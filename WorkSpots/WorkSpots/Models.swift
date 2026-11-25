import Foundation

/// The kind of work spot. Raw values are the stable Codable storage keys.
enum PlaceType: String, Codable, CaseIterable, Identifiable {
    case cafe
    case library
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cafe: return "Café"
        case .library: return "Library"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .cafe: return "cup.and.saucer.fill"
        case .library: return "books.vertical.fill"
        case .other: return "mappin.and.ellipse"
        }
    }
}

/// Which personal list a spot sits on, if any.
/// - `onDeck`: saved to try next; drives the Discover sort and nearby suggestions.
/// - `repeats`: tried it, would go again; lives on the Repeats tab.
/// - `never`: tried it (or ruled it out); never suggested again.
enum PlaceListStatus: String, Codable, CaseIterable {
    case none
    case onDeck
    case repeats
    case never
}

/// What the user chose for an On Deck spot after checking in there.
enum OnDeckCompletionChoice {
    case repeats
    case never
}

/// A single work-from-anywhere spot: a café, a library, or something else.
struct Place: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var type: PlaceType
    var town: String
    var address: String
    /// Rating from a listing site (e.g. Google), if known. Nil means unrated.
    var listedRating: Double?
    /// "$", "$$", "$$$", or nil when unknown.
    var priceLevel: String?
    /// Free-text opening hours, or nil when not published / not verified.
    var hours: String?
    var notes: String
    /// Lowercase filter tags, e.g. "light food", "boutique", "stretch".
    var tags: [String]
    /// Display name of the user who added this spot, when it was user-added.
    var addedBy: String?
    /// Which personal list this spot is on (On Deck / Repeats / Never).
    var listStatus: PlaceListStatus = .none
    /// Approximate coordinates from the street address, for nearby
    /// suggestions and distance tie-breaks. Nil when not geocoded.
    var latitude: Double? = nil
    var longitude: Double? = nil

    var isStretch: Bool { tags.contains("stretch") }

    /// Google Maps search URL built from the place name + address.
    var mapsURL: URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        let query = "\(name) \(address)"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: allowed) else {
            return nil
        }
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)")
    }
}

/// The 1–5 work-friendliness scorecard attached to every check-in.
/// Higher is always better (for Noise, higher means a better noise level for work).
struct Scorecard: Codable, Hashable {
    var coffee: Int = 3
    var wifi: Int = 3
    var outlets: Int = 3
    var noise: Int = 3
    var seating: Int = 3
    var parking: Int = 3

    var average: Double {
        Double(coffee + wifi + outlets + noise + seating + parking) / 6.0
    }
}

/// Per-dimension averages across many check-ins, used for the detail breakdown.
struct ScorecardAverages {
    var coffee: Double
    var wifi: Double
    var outlets: Double
    var noise: Double
    var seating: Double
    var parking: Double

    var rows: [(title: String, systemImage: String, value: Double)] {
        [
            ("Coffee", "cup.and.saucer.fill", coffee),
            ("Wi-Fi", "wifi", wifi),
            ("Outlets", "powerplug.fill", outlets),
            ("Noise", "ear", noise),
            ("Seating", "chair.fill", seating),
            ("Parking", "parkingsign", parking),
        ]
    }
}

/// One visit to a spot, rated. A user can check in to the same spot many times.
struct CheckIn: Identifiable, Codable, Hashable {
    var id: UUID
    var placeID: UUID
    /// Display name of the person who checked in.
    var author: String
    var date: Date
    /// Overall rating, 0.5–5 in half-star steps.
    var rating: Double
    var scorecard: Scorecard
    /// What they ate / drank.
    var whatIHad: String
    /// Free-text review.
    var review: String
    var wouldReturn: Bool
}

/// The local user profile. In the backend phase this becomes the account identity.
struct UserProfile: Codable, Hashable {
    var displayName: String = "Parthey"
    /// Smart nearby suggestions for On Deck spots (one per area per day).
    var nearbySuggestionsEnabled: Bool = true
    /// A single daily pick for the home area instead of an arrival ping.
    var dailyHomePickEnabled: Bool = true
    /// The town treated as home: no arrival pings there, daily pick instead.
    var homeTown: String = "Burlington"
    /// How close counts as "in the area", in miles.
    var suggestionRadiusMiles: Double = 2.0
    /// Suggestions are only sent between these local hours.
    var suggestionStartHour: Int = 8
    var suggestionEndHour: Int = 18
}

extension UserProfile {
    private enum ProfileCodingKeys: String, CodingKey {
        case displayName, nearbySuggestionsEnabled, dailyHomePickEnabled
        case homeTown, suggestionRadiusMiles, suggestionStartHour, suggestionEndHour
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: ProfileCodingKeys.self)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? "Parthey"
        nearbySuggestionsEnabled = try c.decodeIfPresent(Bool.self, forKey: .nearbySuggestionsEnabled) ?? true
        dailyHomePickEnabled = try c.decodeIfPresent(Bool.self, forKey: .dailyHomePickEnabled) ?? true
        homeTown = try c.decodeIfPresent(String.self, forKey: .homeTown) ?? "Burlington"
        suggestionRadiusMiles = try c.decodeIfPresent(Double.self, forKey: .suggestionRadiusMiles) ?? 2.0
        suggestionStartHour = try c.decodeIfPresent(Int.self, forKey: .suggestionStartHour) ?? 8
        suggestionEndHour = try c.decodeIfPresent(Int.self, forKey: .suggestionEndHour) ?? 18
    }
}

/// Everything persisted locally, in one Codable document.
struct StoredData: Codable {
    var places: [Place]
    var checkIns: [CheckIn]
    var profile: UserProfile
}

extension Place {
    private enum PlaceCodingKeys: String, CodingKey {
        case id, name, type, town, address, listedRating, priceLevel, hours
        case notes, tags, addedBy, listStatus, latitude, longitude
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: PlaceCodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(PlaceType.self, forKey: .type)
        town = try c.decode(String.self, forKey: .town)
        address = try c.decode(String.self, forKey: .address)
        listedRating = try c.decodeIfPresent(Double.self, forKey: .listedRating)
        priceLevel = try c.decodeIfPresent(String.self, forKey: .priceLevel)
        hours = try c.decodeIfPresent(String.self, forKey: .hours)
        notes = try c.decode(String.self, forKey: .notes)
        tags = try c.decode([String].self, forKey: .tags)
        addedBy = try c.decodeIfPresent(String.self, forKey: .addedBy)
        listStatus = try c.decodeIfPresent(PlaceListStatus.self, forKey: .listStatus) ?? .none
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
    }
}
