import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: AppPreferences
    @StateObject private var loginItemManager = LoginItemManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                setupCard
                behaviorSection
                systemSection
                footer
            }
            .padding(28)
        }
        .frame(minWidth: 520, minHeight: 560)
        .background(.background)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "rectangle.3.group.bubble.left.fill")
                .font(.system(size: 34, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .frame(width: 52, height: 52)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 3) {
                Text("BarKeep")
                    .font(.title2.weight(.semibold))
                Text("A smaller menu bar, without the subscription hangover.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Set up your hidden section", systemImage: "hand.draw")
                .font(.headline)

            Text("Hold ⌘ and drag BarKeep’s divider to the left of the icons you want hidden. Keep the double-chevron control to their right. macOS remembers the layout.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                menuBarChip("Visible")
                Image(systemName: "line.diagonal")
                    .foregroundStyle(.secondary)
                menuBarChip("Hidden icons")
                Image(systemName: "chevron.left.2")
                    .foregroundStyle(.tint)
            }
            .padding(.top, 2)

            Label("Click the chevrons or press ⌥⌘B to reveal and hide the section.", systemImage: "keyboard")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.separator.opacity(0.7), lineWidth: 1)
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Behavior")
                .font(.headline)

            Toggle("Collapse managed items when BarKeep launches", isOn: $preferences.collapseAtLaunch)
            Toggle("Reveal when the pointer rests in the menu bar", isOn: $preferences.hoverToReveal)
            Toggle("Show section dividers", isOn: $preferences.showDivider)
            Toggle("Enable an always-hidden section", isOn: $preferences.alwaysHiddenEnabled)

            HStack {
                Text("Auto-collapse after")
                Spacer()
                Picker("Auto-collapse after", selection: $preferences.autoHideDelay) {
                    Text("Never").tag(0.0)
                    Text("5 seconds").tag(5.0)
                    Text("10 seconds").tag(10.0)
                    Text("15 seconds").tag(15.0)
                    Text("30 seconds").tag(30.0)
                    Text("1 minute").tag(60.0)
                }
                .labelsHidden()
                .frame(width: 150)
            }

            if preferences.alwaysHiddenEnabled {
                Text("A second divider appears. ⌘-drag it to the left edge of items you rarely need; Option-click the chevrons to reveal that section.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System")
                .font(.headline)

            Toggle(
                "Launch BarKeep at login",
                isOn: Binding(
                    get: { loginItemManager.isEnabled },
                    set: { loginItemManager.setEnabled($0) }
                )
            )

            if let errorMessage = loginItemManager.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                    Button("Open Login Items Settings") {
                        loginItemManager.openSystemSettings()
                    }
                }
            }

            Label("No Accessibility, Screen Recording, analytics, or network access.", systemImage: "lock.shield")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack {
            Text("BarKeep 1.0 · MIT License")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Text("Built in the open")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 4)
    }

    private func menuBarChip(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary, in: Capsule())
    }
}
