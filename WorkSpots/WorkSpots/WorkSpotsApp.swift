import SwiftUI

@main
struct WorkSpotsApp: App {
    @StateObject private var store = WorkSpotsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
