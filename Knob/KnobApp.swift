import SwiftUI
import SwiftData

@main
struct KnobApp: App {
    let modelContainer = SharedModelContainer.make()
    @StateObject private var sessionManager = SessionManager.shared
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    var body: some Scene {
        MenuBarExtra {
            Group {
                if onboardingComplete {
                    MenuBarContentView()
                } else {
                    OnboardingMenuPrompt()
                }
            }
            .environmentObject(sessionManager)
            .modelContainer(modelContainer)
            .task {
                sessionManager.configure(modelContext: modelContainer.mainContext)
            }
        } label: {
            MenuBarLabel()
                .environmentObject(sessionManager)
        }
        .menuBarExtraStyle(.window)

        Window("Knob", id: "main") {
            if onboardingComplete {
                MainWindowView()
                    .environmentObject(sessionManager)
                    .modelContainer(modelContainer)
            } else {
                OnboardingView(onboardingComplete: $onboardingComplete)
                    .modelContainer(modelContainer)
            }
        }
        .defaultSize(width: 720, height: 560)
    }
}
