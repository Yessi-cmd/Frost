import SwiftUI

@main
struct FrostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(FrostViewModel.shared)
        }
    }
}
