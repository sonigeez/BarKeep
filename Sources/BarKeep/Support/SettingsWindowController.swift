import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(preferences: AppPreferences) {
        let rootView = SettingsView(preferences: preferences)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "BarKeep Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 600))
        window.minSize = NSSize(width: 520, height: 560)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("BarKeep.SettingsWindow")
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
