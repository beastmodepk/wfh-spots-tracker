import SwiftUI

struct PlaceDetailView: View {
    @EnvironmentObject private var store: WorkSpotsStore
    let placeID: UUID

    @State private var showingCheckIn = false

    var body: some View {
        Group {
            if let place = store.place(for: placeID) {
                detail(for: place)
            } else {
                ContentUnavailableView("Spot not found", systemImage: "mappin.slash")
            }
        }
    }

    private func detail(for place: Place) -> some View {
        let checkIns = store.checkIns(for: place.id)
        return List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: place.type.systemImage)
                            .foregroundStyle(Color.accentColor)
                        Text("\(place.type.displayName) · \(place.town)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let price = place.priceLevel {
                            Text("· \(price)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !place.tagLabels.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(place.tagLabels, id: \.self) { label in
                                TagChip(text: label)
                            }
                        }
                    }

                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Check In", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            Section("Ratings") {
                HStack {
                    Text("Listed rating")
                    Spacer()
                    if let listed = place.listedRating {
                        StarRatingDisplay(rating: listed)
                        Text(String(format: "%.1f", listed))
                            .font(.subheadline.weight(.semibold))
                    } else {
                        Text("Unrated")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Community rating")
                    Spacer()
                    if let community = store.communityRating(for: place.id) {
                        StarRatingDisplay(rating: community.average)
                        Text(String(format: "%.1f", community.average))
                            .font(.subheadline.weight(.semibold))
                        Text("(\(community.count))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No check-ins yet")
                            .foregroundStyle(.secondary)
                    }
                }

                if let addedBy = place.addedBy {
                    HStack {
                        Text("Added by")
                        Spacer()
                        Text(addedBy)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let averages = store.averageScorecard(for: place.id) {
                Section("Community scorecard") {
                    ForEach(averages.rows, id: \.title) { row in
                        HStack {
                            Label(row.title, systemImage: row.systemImage)
                            Spacer()
                            Text(String(format: "%.1f/5", row.value))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }

            Section("Details") {
                LabeledContent("Address", value: place.address)
                if let hours = place.hours {
                    LabeledContent("Hours", value: hours)
                } else {
                    HStack {
                        Text("Hours")
                        Spacer()
                        Text("Check before you go")
                            .foregroundStyle(.secondary)
                    }
                }
                if !place.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                        Text(place.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                if let mapsURL = place.mapsURL {
                    Link(destination: mapsURL) {
                        Label("Open in Google Maps", systemImage: "map")
                    }
                }
            }

            Section("Check-ins (\(checkIns.count))") {
                if checkIns.isEmpty {
                    Text("No check-ins yet — be the first to rate this spot.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(checkIns) { checkIn in
                        CheckInRowView(checkIn: checkIn, showPlace: false)
                    }
                }
            }
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCheckIn) {
            CheckInView(place: place)
        }
    }
}

/// One check-in, reused by the detail screen and the Activity feed.
struct CheckInRowView: View {
    @EnvironmentObject private var store: WorkSpotsStore
    let checkIn: CheckIn
    var showPlace: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                if showPlace, let place = store.place(for: checkIn.placeID) {
                    Text(place.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
                StarRatingDisplay(rating: checkIn.rating)
                Text(String(format: "%.1f", checkIn.rating))
                    .font(.subheadline.weight(.semibold))
            }

            HStack(spacing: 6) {
                Text(checkIn.author)
                    .font(.subheadline.weight(.medium))
                Text("·")
                    .foregroundStyle(.secondary)
                Text(checkIn.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if checkIn.wouldReturn {
                    Label("Would return", systemImage: "arrow.uturn.backward.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            if !checkIn.whatIHad.isEmpty {
                Text("Had: \(checkIn.whatIHad)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !checkIn.review.isEmpty {
                Text(checkIn.review)
                    .font(.subheadline)
                    .lineLimit(3)
            }

            Text("Scorecard \(String(format: "%.1f", checkIn.scorecard.average))/5 · Coffee \(checkIn.scorecard.coffee) · Wi-Fi \(checkIn.scorecard.wifi) · Outlets \(checkIn.scorecard.outlets) · Noise \(checkIn.scorecard.noise) · Seating \(checkIn.scorecard.seating) · Parking \(checkIn.scorecard.parking)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}
