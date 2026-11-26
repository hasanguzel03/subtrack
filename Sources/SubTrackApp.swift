import SwiftUI
import SwiftData

@main
struct SubTrackApp: App {
    @AppStorage("appTheme") private var appTheme = "system"

    init() {
        NotificationManager.shared.configureDelegate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(resolvedColorScheme)
        }
        .modelContainer(for: Subscription.self)
    }

    private var resolvedColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
