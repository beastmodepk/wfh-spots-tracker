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
}

/// Everything persisted locally, in one Codable document.
struct StoredData: Codable {
    var places: [Place]
    var checkIns: [CheckIn]
    var profile: UserProfile
}
