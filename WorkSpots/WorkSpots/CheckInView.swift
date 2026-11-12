import SwiftUI

/// The check-in sheet: rate a visit to one spot and save it to the store.
struct CheckInView: View {
    @EnvironmentObject private var store: WorkSpotsStore
    @Environment(\.dismiss) private var dismiss

    let place: Place

    @State private var rating: Double = 0
    @State private var scorecard = Scorecard()
    @State private var whatIHad = ""
    @State private var review = ""
    @State private var wouldReturn = true
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(place.name)
                            .font(.headline)
                        Text("Checking in as \(store.profile.displayName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        DatePicker("Date", selection: $date)
                    }
                }

                Section("Your rating") {
                    HalfStarRatingPicker(rating: $rating)
                    if rating < 0.5 {
                        Text("Tap the stars — half stars count too.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Scorecard") {
                    ScorecardStepperRow(title: "Coffee", systemImage: "cup.and.saucer.fill", value: $scorecard.coffee)
                    ScorecardStepperRow(title: "Wi-Fi", systemImage: "wifi", value: $scorecard.wifi)
                    ScorecardStepperRow(title: "Outlets", systemImage: "powerplug.fill", value: $scorecard.outlets)
                    ScorecardStepperRow(title: "Noise", systemImage: "ear", value: $scorecard.noise)
                    ScorecardStepperRow(title: "Seating", systemImage: "chair.fill", value: $scorecard.seating)
                    ScorecardStepperRow(title: "Parking", systemImage: "parkingsign", value: $scorecard.parking)
                }

                Section("Details") {
                    TextField("What I had (food / drink)", text: $whatIHad)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Review")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $review)
                            .frame(minHeight: 70)
                    }
                    Toggle("Would return", isOn: $wouldReturn)
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(rating < 0.5)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        store.addCheckIn(
            placeID: place.id,
            date: date,
            rating: rating,
            scorecard: scorecard,
            whatIHad: whatIHad.trimmingCharacters(in: .whitespacesAndNewlines),
            review: review.trimmingCharacters(in: .whitespacesAndNewlines),
            wouldReturn: wouldReturn
        )
        dismiss()
    }
}
