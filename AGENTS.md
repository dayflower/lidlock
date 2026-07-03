# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this is

LidLock is a small macOS menu-bar app (SwiftPM executable) that locks or sleeps
the Mac when the lid is closed in clamshell mode (external display attached).
See [README.md](README.md) for the user-facing overview and
[notes/DEVELOP.md](notes/DEVELOP.md) for the architecture and internals.

## Setup

- macOS 13 (Ventura) or later.
- A Swift toolchain (Xcode or Command Line Tools).
- `swift-format` on `PATH` for `make format` / `make lint`.

## Build, run, and check

Use the `Makefile` targets rather than raw `swift` invocations:

```sh
make build    # Release build via SwiftPM
make run      # Run directly with `swift run` (quick iteration)
make app      # Assemble .build/LidLock.app (ad-hoc signed)
make install  # Build the .app and copy it to /Applications
make format   # Format sources in place with swift-format
make lint     # Lint with swift-format --strict
make clean    # Remove build artifacts
```

Always run `make lint` (and `make build`) before finishing a change. There is
no test target yet; verify behavior by building and, when relevant, running the
app.

Note: `make run` / `swift run` cannot exercise `LSUIElement` (Dock hiding) or
`SMAppService` (Launch at Login) — those need the signed `.app` bundle from
`make app`.

## Project layout

- `Sources/lidlock/` — Swift sources (the executable target).
- `Resources/Info.plist` — bundle metadata (`LSUIElement`, version, bundle id).
- `scripts/bundle.sh` — assembles + ad-hoc signs the `.app`.
- `Makefile`, `Package.swift` — build entry points.
- `notes/` — development notes; not shipped.

Source responsibilities (details in [notes/DEVELOP.md](notes/DEVELOP.md)):
`ClamshellMonitor` (IOKit lid state), `DisplayMonitor` (external display via
Core Graphics), `ActionScheduler` (delay + cancel), `ActionExecutor` (lock via
`SACLockScreenImmediate` / sleep via `pmset`), `Preferences` (UserDefaults),
`LoginItem` (`SMAppService`), `AppDelegate` / `LidLockApp` (menu bar + wiring).

## Conventions

- Code, comments, and documentation are written in **English**.
- Formatting is enforced by `swift-format`; run `make format` and match the
  existing style rather than hand-formatting.
- Keep the app dependency-free — the `Package.swift` target has no external
  dependencies; prefer system frameworks (IOKit, Core Graphics, ServiceManagement).

## Commit messages

- English, Conventional Commits style, no scope parentheses
  (e.g. `feat: ...`, `fix: ...`, not `feat(menu): ...`).
- Title line only describes the change; keep it to a single line.
- Follow the title with a blank line, then the `Co-Authored-By` trailer.
