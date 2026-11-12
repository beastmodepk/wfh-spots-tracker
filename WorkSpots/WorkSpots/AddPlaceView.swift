import SwiftUI

/// Form for adding a brand-new spot to the catalog, anywhere in the world.
struct AddPlaceView: View {
    @EnvironmentObject private var store: WorkSpotsStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: PlaceType = .cafe
    @State private var town = ""
    @State private var address = ""
    @State private var priceLevel: String?
    @State private var hours = ""
    @State private var notes = ""
    @State private var lightFood = false
    @State private var boutique = false

    private let priceOptions = ["$", "$$", "$$$"]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !town.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Spot") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(PlaceType.allCases) { placeType in
                            Text(placeType.displayName).tag(placeType)
                        }
                    }
                    .pickerStyle(.segmented)
                    TextField("Town / City", text: $town)
                        .textInputAutocapitalization(.words)
                    TextField("Address", text: $address)
                }

                Section("Details") {
                    Picker("Price", selection: $priceLevel) {
                        Text("Unknown").tag(String?.none)
                        ForEach(priceOptions, id: \.self) { option in
                            Text(option).tag(option as String?)
                        }
                    }
                    TextField("Hours (optional)", text: $hours)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 60)
                    }
                }

                Section("Tags") {
                    Toggle("Light food", isOn: $lightFood)
                    Toggle("Boutique", isOn: $boutique)
                }

                Section {
                    Text("New spots join the catalog unrated — the first check-in starts their community rating.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add a Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        var tags: [String] = []
        if lightFood { tags.append("light food") }
        if boutique { tags.append("boutique") }

        let trimmedHours = hours.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addPlace(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            town: town.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            priceLevel: priceLevel,
            hours: trimmedHours.isEmpty ? nil : trimmedHours,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags
        )
        dismiss()
    }
}
