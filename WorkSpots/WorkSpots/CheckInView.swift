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
    /// True after saving a check-in at an On Deck spot: the sheet then asks
    /// the Repeat / Never question before it dismisses.
    @State private var showingOnDeckChoice = false

    var body: some View {
        NavigationStack {
            if showingOnDeckChoice {
                onDeckChoice
            } else {
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
    }

    /// Shown after a check-in clears a spot from On Deck: the user decides
    /// whether it becomes a Repeat or is never suggested again.
    private var onDeckChoice: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("Checked in to \(place.name)")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("That clears it from On Deck. What should happen to this spot now?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                store.completeOnDeck(for: place.id, choice: .repeats)
                dismiss()
            } label: {
                Label("Repeat", systemImage: "repeat")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                store.completeOnDeck(for: place.id, choice: .never)
                dismiss()
            } label: {
                Label("Never", systemImage: "slash.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Text("Repeat moves it to the Repeats tab. Never means it won't be suggested again.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("On Deck — done")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        let wasOnDeck = store.place(for: place.id)?.listStatus == .onDeck
        store.addCheckIn(
            placeID: place.id,
            date: date,
            rating: rating,
            scorecard: scorecard,
            whatIHad: whatIHad.trimmingCharacters(in: .whitespacesAndNewlines),
            review: review.trimmingCharacters(in: .whitespacesAndNewlines),
            wouldReturn: wouldReturn
        )
        if wasOnDeck {
            showingOnDeckChoice = true
        } else {
            dismiss()
        }
    }
}
