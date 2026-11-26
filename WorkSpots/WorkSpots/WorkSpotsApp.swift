import SwiftUI
import UIKit

@main
struct WorkSpotsApp: App {
    @StateObject private var store = WorkSpotsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    store.applyPendingOnDeckDecisions()
                }
        }
    }
}
