import SwiftUI

/// Every check-in across every spot, newest first.
struct ActivityView: View {
    @EnvironmentObject private var store: WorkSpotsStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.sortedCheckIns) { checkIn in
                    NavigationLink(value: checkIn.placeID) {
                        CheckInRowView(checkIn: checkIn, showPlace: true)
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationDestination(for: UUID.self) { placeID in
                PlaceDetailView(placeID: placeID)
            }
            .overlay {
                if store.checkIns.isEmpty {
                    ContentUnavailableView(
                        "No check-ins yet",
                        systemImage: "checklist",
                        description: Text("Check in to a spot from Discover and it will show up here.")
                    )
                }
            }
        }
    }
}
