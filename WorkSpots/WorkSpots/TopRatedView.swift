import SwiftUI

/// Spots ranked by their community rating (the average of all check-ins),
/// ties broken by check-in count. Spots nobody has rated yet are listed
/// separately so they are easy to go and rate.
struct TopRatedView: View {
    @EnvironmentObject private var store: WorkSpotsStore

    private var unratedPlaces: [Place] {
        store.places
            .filter { store.communityRating(for: $0.id) == nil }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List {
                if !store.topRatedPlaces.isEmpty {
                    Section("Ranked by community rating") {
                        ForEach(store.topRatedPlaces) { place in
                            NavigationLink(value: place.id) {
                                HStack(spacing: 12) {
                                    Text("\((store.topRatedPlaces.firstIndex(of: place) ?? 0) + 1)")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(place.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text("\(place.type.displayName) · \(place.town)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let community = store.communityRating(for: place.id) {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            HStack(spacing: 3) {
                                                StarRatingDisplay(rating: community.average)
                                                Text(String(format: "%.1f", community.average))
                                                    .font(.subheadline.weight(.bold))
                                            }
                                            Text("\(community.count) check-in\(community.count == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if !unratedPlaces.isEmpty {
                    Section("Not yet rated by the community") {
                        ForEach(unratedPlaces) { place in
                            NavigationLink(value: place.id) {
                                PlaceRowView(place: place)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Top Rated")
            .navigationDestination(for: UUID.self) { placeID in
                PlaceDetailView(placeID: placeID)
            }
            .overlay {
                if store.topRatedPlaces.isEmpty && unratedPlaces.isEmpty {
                    ContentUnavailableView("No spots yet", systemImage: "trophy")
                }
            }
        }
    }
}
