import Foundation

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
    @Published var profile: UserProfile { didSet { persist() } }

    private let repository: WorkSpotsRepository
    private var isLoading = true

    init(repository: WorkSpotsRepository = LocalJSONRepository()) {
        self.repository = repository
        if let stored = repository.load(), !stored.places.isEmpty {
            places = stored.places
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
