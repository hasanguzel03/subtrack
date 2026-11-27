import SwiftUI
import SwiftData

@main
struct SubTrackApp: App {
    @AppStorage("appTheme") private var appTheme = "system"

    private let modelContainer: ModelContainer = SubTrackApp.makeModelContainer()

    init() {
        NotificationManager.shared.configureDelegate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(resolvedColorScheme)
        }
        .modelContainer(modelContainer)
    }

    private var resolvedColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    // MARK: - Safe SwiftData Initialization

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Reset incompatible local store from earlier dev schemas and recreate cleanly
            let storeURL = configuration.url
            let relatedURLs = [
                storeURL,
                URL(fileURLWithPath: storeURL.path + "-shm"),
                URL(fileURLWithPath: storeURL.path + "-wal")
            ]
            for url in relatedURLs {
                try? FileManager.default.removeItem(at: url)
            }

            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [fallback])
            }
        }
    }
}
