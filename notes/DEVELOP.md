# Development Notes

Technical details of how LidLock is built and how it works internally.

## Project layout

- `Sources/lidlock/` — Swift sources (SwiftPM executable target).
- `Resources/Info.plist` — bundle metadata (`LSUIElement`, version, bundle id).
- `scripts/bundle.sh` — assembles the executable into a signed `.app`.
- `scripts/notarize-app.sh` — notarizes and staples the built `.app`.
- `scripts/entitlements.plist` — entitlements applied when signing.
- `Makefile` — build/format/lint/install entry points.

## Build

Built with SwiftPM (`Package.swift`, macOS 13+). Common targets:

```sh
make build    # Release build of the executable via SwiftPM
make app      # Assemble .build/LidLock.app (signed)
make notarize # Notarize and staple the built .app (needs NOTARY_* env)
make run      # Run directly with `swift run`
make install  # Build the .app and copy it to /Applications
make format   # Format sources with swift-format
make check    # Lint sources with swift-format --strict
make clean    # Remove build artifacts
```

### Why a `.app` bundle?

`make run` / `swift run` is fine for quick iteration, but a proper `.app`
bundle is required for:

- **`LSUIElement`** — hides the Dock icon so the app is menu-bar only.
- **`SMAppService` (Launch at Login)** — needs a stable bundle identity, so the
  bundle is signed by [scripts/bundle.sh](../scripts/bundle.sh).

## Signing

[scripts/bundle.sh](../scripts/bundle.sh) picks its identity from the
environment:

- **`CODESIGN_IDENTITY`** — a Developer ID Application identity. Set only by
  releases; it also enables the hardened runtime (`--options runtime`) and a
  secure timestamp, both required for notarization.
- **`SIGN_ID`** — the local fallback, ad-hoc (`-`) by default.

Ad-hoc signatures change the CDHash on every rebuild, so macOS may drop the
login-item registration between builds. To keep it stable, create a self-signed
code-signing certificate in Keychain Access and use it:

```sh
SIGN_ID="My Dev Cert" make app
```

[scripts/entitlements.plist](../scripts/entitlements.plist) is intentionally an
empty dict: the app is not sandboxed, and neither the `dlopen` of the private
`login.framework` nor the `/usr/bin/pmset` helper needs a hardened-runtime
exception, since both are Apple platform binaries.

## Versioning, CI & release

The app version lives in `Resources/Info.plist`
(`CFBundleShortVersionString` / `CFBundleVersion`).

GitHub Actions (`.github/workflows/`):

- **`ci.yml`** — on every PR and push to `main`, runs `make check` and
  `make build`.
- **`pinact.yml`** — pins every third-party action reference to a full commit
  SHA on PRs. Needs a GitHub App (`vars.ACTIONS_APP_ID`,
  `secrets.ACTIONS_APP_PRIVATE_KEY`).
- **`release.yml`** — on push to `main`, reads the version from
  `Resources/Info.plist`; if the tag `v<version>` does not yet exist, it imports
  a Developer ID certificate, builds with `CODESIGN_IDENTITY` set (so
  `bundle.sh` signs with the hardened runtime and a secure timestamp),
  notarizes and staples via [scripts/notarize-app.sh](../scripts/notarize-app.sh),
  zips the stapled bundle with `ditto`, publishes a GitHub Release tagged
  `v<version>`, and updates the Homebrew cask in `dayflower/homebrew-tap`. The
  tag is created last (by `gh release create --target`), so a partial failure
  leaves no tag and the run is retryable. It runs on `macos-26` because `actool`
  needs Xcode 26 for the Icon Composer app icon.

Release secrets: `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`,
`APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_KEY_P8`,
`HOMEBREW_GITHUB_API_TOKEN`.

To cut a release, run `scripts/bump-version.sh <X.Y.Z | patch | minor | major>`
from a clean `main`: it bumps the Info.plist version on a `bump-version-v<new>`
branch and opens a PR. Merging that PR triggers `release.yml`.

## How it works

- **Lid state** is observed via IOKit: LidLock registers an interest
  notification on `IOPMrootDomain` and reads the `AppleClamshellState` property
  to detect open/close transitions
  ([ClamshellMonitor.swift](../Sources/lidlock/ClamshellMonitor.swift)).
- **External display detection** uses Core Graphics'
  `CGGetOnlineDisplayList` / `CGDisplayIsBuiltin`, since `NSScreen` alone is
  unreliable once the built-in panel is disabled
  ([DisplayMonitor.swift](../Sources/lidlock/DisplayMonitor.swift)).
- **Scheduling** — on lid close the configured action is scheduled with a
  `DispatchWorkItem` after the chosen delay; reopening the lid cancels it, and
  the enabled/external-display conditions are re-checked at fire time
  ([ActionScheduler.swift](../Sources/lidlock/ActionScheduler.swift)).
- **Locking** calls the private `SACLockScreenImmediate` symbol resolved from
  `login.framework` via `dlopen`/`dlsym` (safe no-op if unavailable);
  **sleeping** runs `pmset sleepnow`
  ([ActionExecutor.swift](../Sources/lidlock/ActionExecutor.swift)).
- **Preferences** are persisted in `UserDefaults`
  ([Preferences.swift](../Sources/lidlock/Preferences.swift)).
- **Launch at Login** wraps `SMAppService.mainApp`
  ([LoginItem.swift](../Sources/lidlock/LoginItem.swift)).
