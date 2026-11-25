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
                    LabeledContent("On Deck", value: "\(store.onDeckCount)")
                }

                Section("On Deck notifications") {
                    Toggle("Nearby suggestions", isOn: $store.profile.nearbySuggestionsEnabled)
                    Toggle("Daily pick at home", isOn: $store.profile.dailyHomePickEnabled)
                    Picker("Home area", selection: $store.profile.homeTown) {
                        ForEach(store.towns, id: \.self) { town in
                            Text(town).tag(town)
                        }
                    }
                    Stepper(value: $store.profile.dailyHomePickHour, in: 5...12) {
                        Text("Daily pick at \(store.profile.dailyHomePickHour):00")
                    }
                    Stepper(value: $store.profile.suggestionRadiusMiles, in: 0.5...10, step: 0.5) {
                        Text("Suggest within \(store.profile.suggestionRadiusMiles, specifier: "%.1f") mi")
                    }
                    Stepper(value: $store.profile.suggestionStartHour, in: 0...23) {
                        Text("Suggestions from \(store.profile.suggestionStartHour):00")
                    }
                    Stepper(value: $store.profile.suggestionEndHour, in: 1...24) {
                        Text("Suggestions until \(store.profile.suggestionEndHour):00")
                    }
                    Text("One suggestion per area per day, at most two a day, and your home area gets the daily pick instead of an arrival ping.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .onChange(of: store.profile.nearbySuggestionsEnabled) { _, isOn in
                    if isOn {
                        NearbyNotificationManager.shared.requestAuthorizationIfNeeded()
                        store.refreshNotifications()
                    }
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
