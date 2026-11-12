import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var store: WorkSpotsStore

    @State private var searchText = ""
    @State private var selectedTown: String?
    @State private var selectedType: PlaceType?
    @State private var selectedTag: String?
    @State private var showingAddPlace = false

    private let tagOptions = ["light food", "boutique", "stretch"]

    private var filteredPlaces: [Place] {
        store.places.filter { place in
            if let town = selectedTown, place.town != town { return false }
            if let type = selectedType, place.type != type { return false }
            if let tag = selectedTag, !place.tags.contains(tag) { return false }
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let haystack = "\(place.name) \(place.town) \(place.address)".lowercased()
                if !haystack.contains(query) { return false }
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    filterBar
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))

                Section {
                    ForEach(filteredPlaces) { place in
                        NavigationLink(value: place.id) {
                            PlaceRowView(place: place)
                        }
                    }
                } header: {
                    Text("Showing \(filteredPlaces.count) of \(store.places.count) places")
                }
            }
            .navigationTitle("Discover")
            .navigationDestination(for: UUID.self) { placeID in
                PlaceDetailView(placeID: placeID)
            }
            .searchable(text: $searchText, prompt: "Search spots or towns")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddPlace = true
                    } label: {
                        Label("Add a Spot", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlace) {
                AddPlaceView()
            }
            .overlay {
                if filteredPlaces.isEmpty {
                    ContentUnavailableView(
                        "No spots match",
                        systemImage: "magnifyingglass",
                        description: Text("Try clearing a filter, or add the spot yourself with the + button.")
                    )
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Picker("Town", selection: $selectedTown) {
                        Text("All Towns").tag(String?.none)
                        ForEach(store.towns, id: \.self) { town in
                            Text(town).tag(town as String?)
                        }
                    }
                } label: {
                    filterLabel(selectedTown ?? "All Towns", systemImage: "building.2")
                }

                Menu {
                    Picker("Type", selection: $selectedType) {
                        Text("All Types").tag(PlaceType?.none)
                        ForEach(PlaceType.allCases) { type in
                            Text(type.displayName).tag(type as PlaceType?)
                        }
                    }
                } label: {
                    filterLabel(selectedType?.displayName ?? "All Types", systemImage: "square.grid.2x2")
                }

                Menu {
                    Picker("Tag", selection: $selectedTag) {
                        Text("All Tags").tag(String?.none)
                        ForEach(tagOptions, id: \.self) { tag in
                            Text(tagLabel(tag)).tag(tag as String?)
                        }
                    }
                } label: {
                    filterLabel(selectedTag.map(tagLabel) ?? "All Tags", systemImage: "tag")
                }

                if selectedTown != nil || selectedType != nil || selectedTag != nil {
                    Button("Clear") {
                        selectedTown = nil
                        selectedType = nil
                        selectedTag = nil
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private func filterLabel(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.12), in: Capsule())
    }

    private func tagLabel(_ tag: String) -> String {
        switch tag {
        case "light food": return "Light Food"
        case "boutique": return "Boutique"
        case "stretch": return "Stretch"
        default: return tag.capitalized
        }
    }
}

/// One row in the Discover list (also reused where a compact place row helps).
struct PlaceRowView: View {
    @EnvironmentObject private var store: WorkSpotsStore
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: place.type.systemImage)
                    .foregroundStyle(Color.accentColor)
                Text(place.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                if let price = place.priceLevel {
                    Text(price)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(place.type.displayName) · \(place.town)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if let listed = place.listedRating {
                    HStack(spacing: 3) {
                        StarRatingDisplay(rating: listed)
                        Text(String(format: "%.1f", listed))
                            .font(.caption.weight(.semibold))
                        Text("listed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Unrated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let community = store.communityRating(for: place.id) {
                    HStack(spacing: 3) {
                        StarRatingDisplay(rating: community.average)
                        Text(String(format: "%.1f", community.average))
                            .font(.caption.weight(.semibold))
                        Text("community (\(community.count))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !place.tagLabels.isEmpty {
                HStack(spacing: 4) {
                    ForEach(place.tagLabels, id: \.self) { label in
                        TagChip(text: label)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
