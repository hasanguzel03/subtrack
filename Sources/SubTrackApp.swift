import SwiftUI
import SwiftData

@main
struct SubTrackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Subscription.self)
    }
}
