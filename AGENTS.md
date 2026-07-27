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
- `swift-format` on `PATH` for `make format` / `make check`.

## Build, run, and check

Use the `Makefile` targets rather than raw `swift` invocations:

```sh
make build    # Release build via SwiftPM
make run      # Run directly with `swift run` (quick iteration)
make app      # Assemble .build/LidLock.app (signed; ad-hoc unless SIGN_ID is set)
make notarize # Notarize and staple the built .app (release only; needs NOTARY_* env)
make install  # Build the .app and copy it to /Applications
make format   # Format sources in place with swift-format
make check    # Lint (check only) with swift-format --strict
make clean    # Remove build artifacts
```

Always run `make check` (and `make build`) before finishing a change. There is
no test target yet; verify behavior by building and, when relevant, running the
app.

Note: `make run` / `swift run` cannot exercise `LSUIElement` (Dock hiding) or
`SMAppService` (Launch at Login) — those need the signed `.app` bundle from
`make app`.

## Project layout

- `Sources/lidlock/` — Swift sources (the executable target).
- `Resources/Info.plist` — bundle metadata (`LSUIElement`, version, bundle id).
- `scripts/bundle.sh` — assembles + signs the `.app` (see Signing below).
- `scripts/notarize-app.sh` — notarizes and staples the built `.app`.
- `scripts/entitlements.plist` — entitlements applied when signing (empty dict).
- `scripts/bump-version.sh` — bumps the version and opens a release PR (see below).
- `.github/workflows/` — CI (`ci.yml`: lint + build), release (`release.yml`),
  and `pinact.yml` (pins action refs to commit SHAs on PRs).
- `Makefile`, `Package.swift` — build entry points.
- `notes/` — development notes; not shipped.

## Signing

`scripts/bundle.sh` chooses its identity from the environment:

- `CODESIGN_IDENTITY` — a Developer ID identity, set only by `release.yml`. It
  also enables the hardened runtime and a secure timestamp, both required for
  notarization.
- `SIGN_ID` — the local fallback, ad-hoc (`-`) by default. Pass a self-signed
  certificate (`SIGN_ID="My Dev Cert" make app`) to keep the CDHash — and with
  it the `SMAppService` login-item registration — stable across rebuilds.

Keep `scripts/entitlements.plist` empty unless something actually needs an
exception; the app is not sandboxed, and both the `login.framework` `dlopen` and
`/usr/bin/pmset` are Apple platform binaries that the hardened runtime allows.

## CI / Release

- `ci.yml` runs `make check` and `make build` on every PR and push to `main`.
- `pinact.yml` runs on PRs and auto-pins GitHub Actions references to immutable
  commit SHAs (via [pinact](https://github.com/suzuki-shunsuke/pinact-action)),
  committing fixes back to the PR branch. It authenticates with a GitHub App
  (`ACTIONS_APP_ID` variable, `ACTIONS_APP_PRIVATE_KEY` secret).
- To cut a release, run `scripts/bump-version.sh <version|patch|minor|major>` on
  `main`. It opens a version-bump PR. Merging that PR makes `release.yml` build
  the `.app` signed with a Developer ID certificate, notarize and staple it, and
  publish it as a GitHub Release (zip) tagged `v<version>`. The tag is created
  last by `gh release create --target`, so a failed run leaves no tag and can be
  retried as is.
- Release secrets: `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`,
  `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_KEY_P8`,
  `HOMEBREW_GITHUB_API_TOKEN`.

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
