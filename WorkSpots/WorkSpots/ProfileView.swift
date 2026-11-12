import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: WorkSpotsStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Display name") {
                    TextField("Display name", text: $store.profile.displayName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    Text("Your check-ins and the spots you add are stamped with this name. When accounts arrive, this becomes your username.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Your stats") {
                    LabeledContent("Check-ins", value: "\(store.totalCheckIns)")
                    LabeledContent("Spots tried", value: "\(store.uniqueSpotsTried)")
                    HStack {
                        Text("Average rating given")
                        Spacer()
                        if let average = store.averageRatingGiven {
                            HStack(spacing: 4) {
                                StarRatingDisplay(rating: average)
                                Text(String(format: "%.1f", average))
                            }
                        } else {
                            Text("—")
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Would return", value: "\(store.wouldReturnCount)")
                }

                Section("About") {
                    Text("Work Spots is local-first: your catalog, check-ins and ratings live on this iPhone. A future version adds accounts and sync so community ratings come from everyone, not just this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
        }
    }
}
