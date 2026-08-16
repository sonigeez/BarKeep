import AppKit

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private enum Layout {
        static let dividerWidth: CGFloat = 12
        static let invisibleDividerWidth: CGFloat = 4
        static let maximumCollapseWidth: CGFloat = 10_000
        static let hoverDelay: TimeInterval = 0.6
    }

    private let preferences: AppPreferences
    private let openSettings: () -> Void
    private let controlItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let hiddenDivider = NSStatusBar.system.statusItem(withLength: Layout.dividerWidth)
    private var alwaysHiddenDivider: NSStatusItem?
    private let menu = NSMenu()

    private var isHiddenSectionCollapsed = false
    private var isAlwaysHiddenSectionCollapsed = true
    private var autoHideTimer: Timer?
    private var pointerTimer: Timer?
    private var pointerEnteredMenuBarAt: Date?
    private var preferenceObserver: NSObjectProtocol?

    init(preferences: AppPreferences, openSettings: @escaping () -> Void) {
        self.preferences = preferences
        self.openSettings = openSettings
        super.init()

        configureStatusItems()
        configureMenu()
        configureObservers()
        applyPreferences()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.preferences.collapseAtLaunch {
                self.collapseHiddenSection()
            }
        }
    }

    deinit {
        autoHideTimer?.invalidate()
        pointerTimer?.invalidate()
        if let preferenceObserver {
            NotificationCenter.default.removeObserver(preferenceObserver)
        }
        NSStatusBar.system.removeStatusItem(controlItem)
        NSStatusBar.system.removeStatusItem(hiddenDivider)
        if let alwaysHiddenDivider {
            NSStatusBar.system.removeStatusItem(alwaysHiddenDivider)
        }
    }

    func toggleHiddenSection() {
        if isHiddenSectionCollapsed {
            revealHiddenSection()
        } else {
            collapseHiddenSection()
        }
    }

    private func configureStatusItems() {
        controlItem.autosaveName = "BarKeep.Control"
        hiddenDivider.autosaveName = "BarKeep.HiddenDivider"
        controlItem.isVisible = true
        hiddenDivider.isVisible = true

        if let button = controlItem.button {
            button.image = symbol("chevron.left.2")
            button.imagePosition = .imageOnly
            button.toolTip = "BarKeep — click to reveal hidden items"
            button.target = self
            button.action = #selector(controlPressed(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel("BarKeep hidden items")
        }

        hiddenDivider.button?.toolTip = "BarKeep divider — ⌘-drag to position"
        updateDividerAppearance()
    }

    private func configureMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
    }

    private func configureObservers() {
        preferenceObserver = NotificationCenter.default.addObserver(
            forName: AppPreferences.didChange,
            object: preferences,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.applyPreferences()
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        pointerTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkPointerPosition()
            }
        }
    }

    private func applyPreferences() {
        updateDividerAppearance()
        configureAlwaysHiddenDivider()

        if isHiddenSectionCollapsed {
            hiddenDivider.length = collapseWidth
        }

        if preferences.autoHideDelay == 0 {
            autoHideTimer?.invalidate()
            autoHideTimer = nil
        } else if !isHiddenSectionCollapsed, !isPointerInMenuBar {
            scheduleAutoHide()
        }
    }

    private func configureAlwaysHiddenDivider() {
        if preferences.alwaysHiddenEnabled {
            if alwaysHiddenDivider == nil {
                let item = NSStatusBar.system.statusItem(withLength: collapseWidth)
                item.autosaveName = "BarKeep.AlwaysHiddenDivider"
                item.isVisible = true
                item.button?.toolTip = "Always-hidden divider — ⌘-drag to position"
                alwaysHiddenDivider = item
            }
            updateDividerAppearance()
            alwaysHiddenDivider?.length = isAlwaysHiddenSectionCollapsed
                ? collapseWidth
                : expandedDividerWidth
        } else if let item = alwaysHiddenDivider {
            NSStatusBar.system.removeStatusItem(item)
            alwaysHiddenDivider = nil
            isAlwaysHiddenSectionCollapsed = true
        }
    }

    private func updateDividerAppearance() {
        let image = preferences.showDivider ? symbol("line.diagonal") : nil
        hiddenDivider.button?.image = image
        alwaysHiddenDivider?.button?.image = image

        if !isHiddenSectionCollapsed {
            hiddenDivider.length = expandedDividerWidth
        }
        if !isAlwaysHiddenSectionCollapsed {
            alwaysHiddenDivider?.length = expandedDividerWidth
        }
    }

    private var expandedDividerWidth: CGFloat {
        preferences.showDivider ? Layout.dividerWidth : Layout.invisibleDividerWidth
    }

    private var collapseWidth: CGFloat {
        let widestScreen = NSScreen.screens.map(\.frame.width).max() ?? 1728
        return min(max(widestScreen * 2, 500), Layout.maximumCollapseWidth)
    }

    private var isPointerInMenuBar: Bool {
        let pointer = NSEvent.mouseLocation
        return NSScreen.screens.contains { screen in
            let menuBarFloor = screen.visibleFrame.maxY
            return pointer.x >= screen.frame.minX
                && pointer.x <= screen.frame.maxX
                && pointer.y >= menuBarFloor
                && pointer.y <= screen.frame.maxY
                && screen.frame.maxY - menuBarFloor > 1
        }
    }

    private func revealHiddenSection() {
        guard isHiddenSectionCollapsed else { return }
        isHiddenSectionCollapsed = false
        hiddenDivider.length = expandedDividerWidth
        NSLog("BarKeep: revealed managed section")
        updateControlAppearance()
        if !isPointerInMenuBar {
            scheduleAutoHide()
        }
    }

    private func collapseHiddenSection() {
        guard !isHiddenSectionCollapsed else { return }
        guard dividerOrderIsUsable else {
            NSLog("BarKeep: divider is on the wrong side of the control; skipping collapse")
            return
        }
        isHiddenSectionCollapsed = true
        hiddenDivider.length = collapseWidth
        NSLog("BarKeep: collapsed managed section to %.0f points", hiddenDivider.length)
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        updateControlAppearance()
    }

    private func toggleAlwaysHiddenSection() {
        guard let alwaysHiddenDivider else { return }
        isAlwaysHiddenSectionCollapsed.toggle()
        alwaysHiddenDivider.length = isAlwaysHiddenSectionCollapsed
            ? collapseWidth
            : expandedDividerWidth
        NSLog(
            "BarKeep: %@ always-hidden section",
            isAlwaysHiddenSectionCollapsed ? "collapsed" : "revealed"
        )
    }

    private func updateControlAppearance() {
        controlItem.button?.image = symbol(isHiddenSectionCollapsed ? "chevron.right.2" : "chevron.left.2")
        controlItem.button?.toolTip = isHiddenSectionCollapsed
            ? "BarKeep — click to reveal hidden items"
            : "BarKeep — click to hide managed items"
    }

    private var dividerOrderIsUsable: Bool {
        guard
            let controlX = controlItem.button?.window?.frame.minX,
            let dividerX = hiddenDivider.button?.window?.frame.minX
        else {
            return true
        }
        return controlX > dividerX
    }

    private func scheduleAutoHide() {
        autoHideTimer?.invalidate()
        guard preferences.autoHideDelay > 0 else { return }
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: preferences.autoHideDelay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.isPointerInMenuBar {
                    self.scheduleAutoHide()
                } else {
                    self.collapseHiddenSection()
                }
            }
        }
    }

    private func checkPointerPosition() {
        if isPointerInMenuBar {
            autoHideTimer?.invalidate()
            autoHideTimer = nil

            guard preferences.hoverToReveal, isHiddenSectionCollapsed else {
                pointerEnteredMenuBarAt = nil
                return
            }

            if pointerEnteredMenuBarAt == nil {
                pointerEnteredMenuBarAt = Date()
            } else if Date().timeIntervalSince(pointerEnteredMenuBarAt!) >= Layout.hoverDelay {
                pointerEnteredMenuBarAt = nil
                revealHiddenSection()
            }
        } else {
            pointerEnteredMenuBarAt = nil
            if !isHiddenSectionCollapsed, autoHideTimer == nil {
                scheduleAutoHide()
            }
        }
    }

    @objc private func controlPressed(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            toggleHiddenSection()
            return
        }

        if event.type == .rightMouseUp {
            menu.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: sender.bounds.maxY + 4),
                in: sender
            )
        } else if event.modifierFlags.contains(.option), preferences.alwaysHiddenEnabled {
            toggleAlwaysHiddenSection()
        } else {
            toggleHiddenSection()
        }
    }

    @objc private func toggleHiddenMenuItem() {
        toggleHiddenSection()
    }

    @objc private func toggleAlwaysHiddenMenuItem() {
        toggleAlwaysHiddenSection()
    }

    @objc private func showSettingsMenuItem() {
        openSettings()
    }

    @objc private func quitMenuItem() {
        NSApp.terminate(nil)
    }

    @objc private func screenConfigurationChanged() {
        if isHiddenSectionCollapsed {
            hiddenDivider.length = collapseWidth
        }
        if isAlwaysHiddenSectionCollapsed {
            alwaysHiddenDivider?.length = collapseWidth
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(item(
            title: isHiddenSectionCollapsed ? "Show Hidden Items" : "Hide Managed Items",
            action: #selector(toggleHiddenMenuItem),
            key: "b",
            modifiers: [.command, .option]
        ))

        if preferences.alwaysHiddenEnabled {
            menu.addItem(item(
                title: isAlwaysHiddenSectionCollapsed ? "Show Always-Hidden" : "Hide Always-Hidden",
                action: #selector(toggleAlwaysHiddenMenuItem)
            ))
        }

        menu.addItem(.separator())
        menu.addItem(item(title: "Settings…", action: #selector(showSettingsMenuItem), key: ","))
        menu.addItem(.separator())
        menu.addItem(item(title: "Quit BarKeep", action: #selector(quitMenuItem), key: "q"))
    }

    private func item(
        title: String,
        action: Selector,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = .command
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    private func symbol(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }
}
