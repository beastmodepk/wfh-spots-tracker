import Foundation
import CoreLocation
import UserNotifications

// MARK: - Repository boundary
//
// All persistence goes through this protocol. Today the only implementation
// is LocalJSONRepository (a JSON file on the device). The multi-user phase
// adds a remote implementation of the same protocol — accounts, sync and
// shared community ratings — without changing the store or the views.

protocol WorkSpotsRepository {
    func load() -> StoredData?
    func save(_ data: StoredData)
}

/// Local-first persistence: one Codable JSON document in Application Support.
final class LocalJSONRepository: WorkSpotsRepository {
    private let fileURL: URL

    init(fileName: String = "workspots-data.json") {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("WorkSpots", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent(fileName)
    }

    func load() -> StoredData? {
        guard let raw = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(StoredData.self, from: raw)
    }

    func save(_ data: StoredData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let raw = try? encoder.encode(data) else { return }
        try? raw.write(to: fileURL, options: [.atomic])
    }
}

// MARK: - Store

final class WorkSpotsStore: ObservableObject {
    @Published var places: [Place] { didSet { persist() } }
    @Published var checkIns: [CheckIn] { didSet { persist() } }
    @Published var profile: UserProfile { didSet { persist(); refreshNotifications() } }

    private let repository: WorkSpotsRepository
    private var isLoading = true

    init(repository: WorkSpotsRepository = LocalJSONRepository()) {
        self.repository = repository
        if let stored = repository.load(), !stored.places.isEmpty {
            // Backfill coordinates for seed places saved before they had any.
            places = stored.places.map { place in
                var place = place
                if place.latitude == nil,
                   let seed = SeedData.places.first(where: { $0.id == place.id }) {
                    place.latitude = seed.latitude
                    place.longitude = seed.longitude
                }
                return place
            }
            checkIns = stored.checkIns
            profile = stored.profile
        } else {
            // First launch: seed the starting catalog.
            places = SeedData.places
            checkIns = []
            profile = UserProfile()
        }
        isLoading = false
        persist()
        refreshNotifications()
    }

    /// Rebuilds the town geofences and the home daily pick from the
    /// current On Deck list and notification settings.
    func refreshNotifications() {
        guard !isLoading else { return }
        NearbyNotificationManager.shared.refresh(onDeckPlaces: onDeckPlaces, profile: profile)
    }

    private func persist() {
        guard !isLoading else { return }
        repository.save(StoredData(places: places, checkIns: checkIns, profile: profile))
    }

    // MARK: Lookups

    func place(for id: UUID) -> Place? {
        places.first { $0.id == id }
    }

    func checkIns(for placeID: UUID) -> [CheckIn] {
        checkIns
            .filter { $0.placeID == placeID }
            .sorted { $0.date > $1.date }
    }

    /// All check-ins, newest first — the Activity feed.
    var sortedCheckIns: [CheckIn] {
        checkIns.sorted { $0.date > $1.date }
    }

    var towns: [String] {
        Array(Set(places.map(\.town))).sorted()
    }

    // MARK: Community ratings (aggregated from check-ins)

    /// Average overall rating across all check-ins for a spot, with the count.
    /// Returns nil until the spot has at least one check-in.
    func communityRating(for placeID: UUID) -> (average: Double, count: Int)? {
        let list = checkIns.filter { $0.placeID == placeID }
        guard !list.isEmpty else { return nil }
        let total = list.reduce(0.0) { $0 + $1.rating }
        return (total / Double(list.count), list.count)
    }

    /// Per-dimension scorecard averages across all check-ins for a spot.
    func averageScorecard(for placeID: UUID) -> ScorecardAverages? {
        let list = checkIns.filter { $0.placeID == placeID }
        guard !list.isEmpty else { return nil }
        let n = Double(list.count)
        return ScorecardAverages(
            coffee: Double(list.reduce(0) { $0 + $1.scorecard.coffee }) / n,
            wifi: Double(list.reduce(0) { $0 + $1.scorecard.wifi }) / n,
            outlets: Double(list.reduce(0) { $0 + $1.scorecard.outlets }) / n,
            noise: Double(list.reduce(0) { $0 + $1.scorecard.noise }) / n,
            seating: Double(list.reduce(0) { $0 + $1.scorecard.seating }) / n,
            parking: Double(list.reduce(0) { $0 + $1.scorecard.parking }) / n
        )
    }

    /// Spots ranked by community rating; ties break on check-in count, then name.
    var topRatedPlaces: [Place] {
        places
            .filter { communityRating(for: $0.id) != nil }
            .sorted { a, b in
                let ra = communityRating(for: a.id)
                let rb = communityRating(for: b.id)
                if (ra?.average ?? 0) != (rb?.average ?? 0) {
                    return (ra?.average ?? 0) > (rb?.average ?? 0)
                }
                if (ra?.count ?? 0) != (rb?.count ?? 0) {
                    return (ra?.count ?? 0) > (rb?.count ?? 0)
                }
                return a.name < b.name
            }
    }

    // MARK: Personal stats (check-ins stored on this device)

    var totalCheckIns: Int { checkIns.count }

    var uniqueSpotsTried: Int { Set(checkIns.map(\.placeID)).count }

    var averageRatingGiven: Double? {
        guard !checkIns.isEmpty else { return nil }
        return checkIns.reduce(0.0) { $0 + $1.rating } / Double(checkIns.count)
    }

    var wouldReturnCount: Int { checkIns.filter(\.wouldReturn).count }

    // MARK: On Deck / Repeats / Never

    /// The rating used to rank a spot: its listed rating, falling back to
    /// the community average once it has check-ins. Nil means unrated.
    func effectiveRating(for place: Place) -> Double? {
        place.listedRating ?? communityRating(for: place.id)?.average
    }

    /// On Deck spots, highest rated first (unrated last), then by name.
    var onDeckPlaces: [Place] {
        places
            .filter { $0.listStatus == .onDeck }
            .sorted { a, b in
                let ra = effectiveRating(for: a) ?? -1
                let rb = effectiveRating(for: b) ?? -1
                if ra != rb { return ra > rb }
                return a.name < b.name
            }
    }

    /// Spots the user wants to go back to, highest rated first.
    var repeatsPlaces: [Place] {
        places
            .filter { $0.listStatus == .repeats }
            .sorted { a, b in
                let ra = effectiveRating(for: a) ?? -1
                let rb = effectiveRating(for: b) ?? -1
                if ra != rb { return ra > rb }
                return a.name < b.name
            }
    }

    var onDeckCount: Int { places.filter { $0.listStatus == .onDeck }.count }

    /// Ordering for the "All" (Discover) list: On Deck spots first, sorted
    /// by highest rating; every other spot keeps its existing order and
    /// flows straight after, with no section break between the two.
    func discoverOrdered(_ input: [Place]) -> [Place] {
        let indexed = Array(input.enumerated())
        return indexed.sorted { a, b in
            let aDeck = a.element.listStatus == .onDeck
            let bDeck = b.element.listStatus == .onDeck
            if aDeck != bDeck { return aDeck && !bDeck }
            if aDeck && bDeck {
                let ra = effectiveRating(for: a.element) ?? -1
                let rb = effectiveRating(for: b.element) ?? -1
                if ra != rb { return ra > rb }
            }
            return a.offset < b.offset
        }.map(\.element)
    }

    func setListStatus(_ status: PlaceListStatus, for placeID: UUID) {
        guard let index = places.firstIndex(where: { $0.id == placeID }) else { return }
        places[index].listStatus = status
        if status == .onDeck {
            // Permissions are asked when the feature is first used,
            // not at first launch.
            NearbyNotificationManager.shared.requestAuthorizationIfNeeded()
        }
        refreshNotifications()
    }

    /// The small ring button's action: On Deck if it isn't, off if it is.
    func toggleOnDeck(for placeID: UUID) {
        guard let place = place(for: placeID) else { return }
        setListStatus(place.listStatus == .onDeck ? .none : .onDeck, for: placeID)
    }

    /// After a check-in at an On Deck spot, the user's Repeat / Never choice.
    func completeOnDeck(for placeID: UUID, choice: OnDeckCompletionChoice) {
        switch choice {
        case .repeats: setListStatus(.repeats, for: placeID)
        case .never: setListStatus(.never, for: placeID)
        }
    }

    // MARK: Mutations

    @discardableResult
    func addPlace(name: String,
                  type: PlaceType,
                  town: String,
                  address: String,
                  priceLevel: String?,
                  hours: String?,
                  notes: String,
                  tags: [String]) -> Place {
        let place = Place(
            id: UUID(),
            name: name,
            type: type,
            town: town,
            address: address,
            listedRating: nil,
            priceLevel: priceLevel,
            hours: hours,
            notes: notes,
            tags: tags,
            addedBy: profile.displayName
        )
        places.append(place)
        places.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return place
    }

    @discardableResult
    func addCheckIn(placeID: UUID,
                    date: Date,
                    rating: Double,
                    scorecard: Scorecard,
                    whatIHad: String,
                    review: String,
                    wouldReturn: Bool) -> CheckIn {
        let checkIn = CheckIn(
            id: UUID(),
            placeID: placeID,
            author: profile.displayName,
            date: date,
            rating: rating,
            scorecard: scorecard,
            whatIHad: whatIHad,
            review: review,
            wouldReturn: wouldReturn
        )
        checkIns.append(checkIn)
        return checkIn
    }
}


// MARK: - Smart nearby notifications
//
// One geofence per TOWN that has On Deck spots — never one per spot — so
// arriving somewhere with five saved spots produces at most one
// suggestion. Guardrails, all enforced in `passesGuards(town:)`:
//   * at most 1 notification per area per calendar day
//   * at most 2 notifications per day in total
//   * at least 4 hours between any two notifications
//   * only inside the user's suggestion hours (default 8am–6pm)
// The home town never gets an arrival ping; it gets one daily pick
// (a repeating calendar notification) instead.
final class NearbyNotificationManager: NSObject, CLLocationManagerDelegate {
    static let shared = NearbyNotificationManager()

    private let locationManager = CLLocationManager()
    private var onDeckPlaces: [Place] = []
    private var profile = UserProfile()

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        locationManager.requestAlwaysAuthorization()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func refresh(onDeckPlaces: [Place], profile: UserProfile) {
        self.onDeckPlaces = onDeckPlaces
        self.profile = profile

        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["home-daily-pick"])
        guard profile.nearbySuggestionsEnabled else { return }

        let located = onDeckPlaces.filter { $0.latitude != nil && $0.longitude != nil }
        let byTown = Dictionary(grouping: located, by: { $0.town })
        for (town, places) in byTown {
            let latitudes = places.compactMap(\.latitude)
            let longitudes = places.compactMap(\.longitude)
            guard !latitudes.isEmpty, !longitudes.isEmpty else { continue }
            let center = CLLocationCoordinate2D(
                latitude: latitudes.reduce(0, +) / Double(latitudes.count),
                longitude: longitudes.reduce(0, +) / Double(longitudes.count)
            )
            let milesInMeters = profile.suggestionRadiusMiles * 1609.34
            let radius = max(500, min(milesInMeters, locationManager.maximumRegionMonitoringDistance))
            let region = CLCircularRegion(center: center, radius: radius, identifier: "town.\(town)")
            region.notifyOnEntry = true
            region.notifyOnExit = false
            locationManager.startMonitoring(for: region)
        }
        scheduleHomeDailyPick()
    }

    /// The home area's single daily suggestion, as a repeating calendar
    /// notification naming the top-rated On Deck spot in the home town.
    private func scheduleHomeDailyPick() {
        guard profile.dailyHomePickEnabled else { return }
        // onDeckPlaces arrives sorted by rating, so the first home-town
        // entry is the pick.
        guard let pick = onDeckPlaces.first(where: { $0.town == profile.homeTown }) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Today's \(profile.homeTown) pick"
        content.body = "\(pick.name) is On Deck — it's the top-rated spot on your list there."
        content.sound = .default
        var components = DateComponents()
        components.hour = profile.dailyHomePickHour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "home-daily-pick", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard profile.nearbySuggestionsEnabled else { return }
        guard region.identifier.hasPrefix("town.") else { return }
        let town = String(region.identifier.dropFirst("town.".count))
        // Home gets the daily pick, never an arrival ping.
        guard town != profile.homeTown else { return }
        guard let pick = onDeckPlaces.first(where: { $0.town == town }) else { return }
        guard passesGuards(town: town) else { return }

        let content = UNMutableNotificationContent()
        content.title = "You're in \(town) — one On Deck pick"
        content.body = "\(pick.name) is the top-rated spot on your On Deck list here."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "on-deck-\(town)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
        recordNotification(town: town)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        // A town cluster that fails to register simply gets no arrival
        // suggestion; the daily home pick is unaffected.
    }

    // MARK: Guardrails (UserDefaults-backed, per calendar day)

    private func passesGuards(town: String) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        guard hour >= profile.suggestionStartHour, hour < profile.suggestionEndHour else { return false }

        let defaults = UserDefaults.standard
        if let lastTown = defaults.object(forKey: "onDeck.lastNotified.\(town)") as? Date,
           calendar.isDate(lastTown, inSameDayAs: now) {
            return false
        }
        if let lastAny = defaults.object(forKey: "onDeck.lastNotified.any") as? Date,
           now.timeIntervalSince(lastAny) < 4 * 60 * 60 {
            return false
        }
        let countKey = "onDeck.count.\(Self.dayStamp(now))"
        guard defaults.integer(forKey: countKey) < 2 else { return false }
        return true
    }

    private func recordNotification(town: String) {
        let now = Date()
        let defaults = UserDefaults.standard
        defaults.set(now, forKey: "onDeck.lastNotified.\(town)")
        defaults.set(now, forKey: "onDeck.lastNotified.any")
        let countKey = "onDeck.count.\(Self.dayStamp(now))"
        defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey)
    }

    private static func dayStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
