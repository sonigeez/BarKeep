import AppKit

@main
enum BarKeepApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = AppPreferences()
    private var menuBarController: MenuBarController?
    private var hotKey: GlobalHotKey?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settingsWindowController = SettingsWindowController(preferences: preferences)
        self.settingsWindowController = settingsWindowController

        menuBarController = MenuBarController(
            preferences: preferences,
            openSettings: { [weak self] in self?.showSettings() }
        )

        hotKey = GlobalHotKey { [weak self] in
            self?.menuBarController?.toggleHiddenSection()
        }

        if !preferences.hasCompletedOnboarding {
            preferences.hasCompletedOnboarding = true
            showSettings()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showSettings() {
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
