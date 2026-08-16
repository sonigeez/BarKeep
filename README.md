# BarKeep

BarKeep is a tiny, open-source menu bar organizer for macOS. It hides a section of menu bar items behind one click, then gets out of your way.

It is deliberately boring about privacy: no account, no analytics, no network requests, and no Accessibility or Screen Recording permission.

## Features

- Hide and reveal a user-defined section of menu bar items
- Auto-collapse after 5 seconds to 1 minute
- Reveal by hovering over the menu bar
- Optional always-hidden section
- Global **Option-Command-B** shortcut
- Launch at login with Apple's `SMAppService`
- Multi-display-aware hiding
- Native Swift and AppKit, with no third-party dependencies

## Requirements

- macOS 14 Sonoma or newer
- Xcode 16 or a compatible Swift 5.10+ toolchain

## Build and run

```sh
./script/build_and_run.sh --verify
```

The script builds a real app bundle at `dist/BarKeep.app` and launches it. To create a release zip and SHA-256 checksum:

```sh
./script/build_and_run.sh --package
```

Release builds are ad-hoc signed by default. Set `BARKEEP_CODESIGN_IDENTITY` to a Developer ID Application identity before packaging a distributable build; notarization still requires the maintainer's Apple credentials.

## Set up your menu bar

1. Launch BarKeep.
2. Hold **Command** and drag BarKeep's diagonal divider to the left of the icons you want managed.
3. Keep BarKeep's double-chevron control to the right of those icons.
4. Click the chevrons, or press **Option-Command-B**, to reveal and hide them.
5. Right-click the chevrons to open Settings or quit.

macOS owns menu bar item ordering and persists the two BarKeep controls. BarKeep changes the divider width to move the managed section offscreen; it does not inspect or capture other apps' icons.

## Scope

BarKeep 1.0 is a complete lightweight menu bar hider, not a pixel-for-pixel Bartender clone. Search, per-app rules, icon mirroring, and menu bar theming require screen capture and accessibility machinery; they are intentionally outside this privacy-first release.

## Contributing

Bug reports and focused pull requests are welcome. Keep the app dependency-free and do not add telemetry.

## License

[MIT](LICENSE)
