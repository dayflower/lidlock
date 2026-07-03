# Development Notes

Technical details of how LidLock is built and how it works internally.

## Project layout

- `Sources/lidlock/` — Swift sources (SwiftPM executable target).
- `Resources/Info.plist` — bundle metadata (`LSUIElement`, version, bundle id).
- `scripts/bundle.sh` — assembles the executable into a signed `.app`.
- `Makefile` — build/format/lint/install entry points.

## Build

Built with SwiftPM (`Package.swift`, macOS 13+). Common targets:

```sh
make build    # Release build of the executable via SwiftPM
make app      # Assemble .build/LidLock.app (ad-hoc signed)
make run      # Run directly with `swift run`
make install  # Build the .app and copy it to /Applications
make format   # Format sources with swift-format
make lint     # Lint sources with swift-format --strict
make clean    # Remove build artifacts
```

### Why a `.app` bundle?

`make run` / `swift run` is fine for quick iteration, but a proper `.app`
bundle is required for:

- **`LSUIElement`** — hides the Dock icon so the app is menu-bar only.
- **`SMAppService` (Launch at Login)** — needs a stable bundle identity, so the
  bundle is ad-hoc signed by [scripts/bundle.sh](../scripts/bundle.sh).

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
