import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }

            OnDeckView()
                .tabItem { Label("On Deck", systemImage: "circle.circle") }

            RepeatsView()
                .tabItem { Label("Repeats", systemImage: "repeat") }

            TopRatedView()
                .tabItem { Label("Top Rated", systemImage: "trophy.fill") }

            ActivityView()
                .tabItem { Label("Activity", systemImage: "list.bullet") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkSpotsStore(repository: PreviewRepository()))
}

/// In-memory repository used only by SwiftUI previews.
final class PreviewRepository: WorkSpotsRepository {
    func load() -> StoredData? {
        StoredData(places: SeedData.places, checkIns: [], profile: UserProfile())
    }

    func save(_ data: StoredData) {}
}
