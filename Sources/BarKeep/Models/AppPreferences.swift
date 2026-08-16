import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    static let didChange = Notification.Name("BarKeepPreferencesDidChange")

    private enum Key {
        static let autoHideDelay = "autoHideDelay"
        static let hoverToReveal = "hoverToReveal"
        static let showDivider = "showDivider"
        static let alwaysHiddenEnabled = "alwaysHiddenEnabled"
        static let collapseAtLaunch = "collapseAtLaunch"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    @Published var autoHideDelay: Double {
        didSet { persist(autoHideDelay, forKey: Key.autoHideDelay) }
    }

    @Published var hoverToReveal: Bool {
        didSet { persist(hoverToReveal, forKey: Key.hoverToReveal) }
    }

    @Published var showDivider: Bool {
        didSet { persist(showDivider, forKey: Key.showDivider) }
    }

    @Published var alwaysHiddenEnabled: Bool {
        didSet { persist(alwaysHiddenEnabled, forKey: Key.alwaysHiddenEnabled) }
    }

    @Published var collapseAtLaunch: Bool {
        didSet { persist(collapseAtLaunch, forKey: Key.collapseAtLaunch) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Key.hasCompletedOnboarding) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.autoHideDelay: 10.0,
            Key.hoverToReveal: false,
            Key.showDivider: true,
            Key.alwaysHiddenEnabled: false,
            Key.collapseAtLaunch: true,
            Key.hasCompletedOnboarding: false
        ])

        autoHideDelay = defaults.double(forKey: Key.autoHideDelay)
        hoverToReveal = defaults.bool(forKey: Key.hoverToReveal)
        showDivider = defaults.bool(forKey: Key.showDivider)
        alwaysHiddenEnabled = defaults.bool(forKey: Key.alwaysHiddenEnabled)
        collapseAtLaunch = defaults.bool(forKey: Key.collapseAtLaunch)
    }

    private func persist(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
}
