# Contributing to strickey

Thanks for helping improve strickey. It is a native Swift menu bar app for macOS; contributions should preserve its small footprint, privacy, and compatibility with macOS 14 or later.

## Set up locally

Use Xcode 26 or later, or Apple's Command Line Tools with Swift 6 and a macOS 26 SDK. Clone the repository, run the core tests, and build the app:

```sh
git clone https://github.com/madvillax/strickey.git
cd strickey
./scripts/test.sh
./scripts/build-app.sh
open dist/Strickey.app
```

Read [README.md](README.md) for setup and [architecture.md](architecture.md) before changing event handling, audio, permissions, or app lifecycle.

## Development guidelines

For the landing page, use Node.js 22+ and run npm install followed by npm run dev from the repository root. Website code belongs in apps/web; the Swift app stays in its existing folders. Run npm run lint, npm run typecheck, and npm run build for web changes. Check desktop/mobile layouts, dark-theme contrast, reduced motion, and real sound playback after a user gesture.

- Keep the app native to Swift, AppKit, and SwiftUI. Explain the need and maintenance cost before adding a package or runtime dependency.
- Preserve macOS 14 as the minimum supported version. Guard APIs that require newer macOS releases and keep the older-system appearance working.
- Keep keyboard monitoring listen-only. Use physical key codes for sound selection; do not read typed characters or text, suppress key events, or store a typing history.
- Keep user preferences local. Do not add network reporting or analytics for keyboard events.
- Keep audio loading and decoding out of the per-keystroke path. Include any new recordings in the resource manifest and document their source, license, and required attribution. The bundled Mechvibes recordings keep their separate license and credits in `Sources/StrickeyCore/Resources/CherryMX/`.
- Keep the menu bar panel compact and accessible, and retain support for Reduce Transparency and the macOS 14 visual fallback.
- Update `architecture.md` when a change affects component responsibilities, data flow, permissions, packaging, or release behavior.
- Do not commit `.build/` or `dist/`; they contain local build and release artifacts.

## Before opening a pull request

For Swift or packaging changes, run:

```sh
./scripts/test.sh
./scripts/build-app.sh
```

For changes to physical typing, audio, permissions, launch behavior, or the menu bar UI, also launch the built app and describe the manual checks you performed. CI tests core behavior and packaging on Apple Silicon and Intel runners, but it cannot grant Input Monitoring or confirm what typing sounds like on your Mac.

Keep each pull request focused. Describe the user-visible change, list relevant checks and their results, and mention any macOS version or permission needed to reproduce it. Include screenshots for visual changes when practical.

## Sound assets and licensing

Do not add sounds copied from other projects, websites, or recordings unless their terms allow redistribution in strickey. Preserve the source attribution and license alongside each asset. The existing Cherry MX recordings are covered by the upstream license included with those files; that notice is separate from any license for strickey's own source code.
