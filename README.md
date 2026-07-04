# LidLock

A tiny macOS menu bar app that locks or sleeps your Mac when you close the lid
while running in clamshell mode.

When a MacBook is connected to an external display and you close the lid, macOS
keeps running in clamshell mode instead of sleeping — leaving your session
unlocked. LidLock watches for the lid closing in that situation and locks the
screen (or puts the Mac to sleep) for you.

## Features

- Lives in the menu bar (no Dock icon).
- Choose the action on lid close: **Lock** the screen or **Sleep** the system.
- Configurable delay before the action fires (0, 1, 2, 5, or 10 seconds).
  Reopening the lid within the delay cancels the pending action.
- Only fires when an external display is connected (true clamshell mode), so it
  won't interfere with a normal lid-close-and-sleep.
- Enable/disable toggle from the menu.
- Optional **Launch at Login**.

## Requirements

- macOS 13 (Ventura) or later
- [Swift toolchain](https://www.swift.org/install/) (Xcode or Command Line Tools)

## Install

Install the prebuilt app with [Homebrew](https://brew.sh):

```sh
brew install --cask dayflower/tap/lidlock
```

The app is distributed with an ad-hoc signature, so after installing you need to
clear the quarantine attribute before first launch:

```sh
xattr -dr com.apple.quarantine /Applications/LidLock.app
```

## Build from source

Build a signed `.app` bundle and copy it to `/Applications`:

```sh
make install
```

See [notes/DEVELOP.md](notes/DEVELOP.md) for other build targets and internals.

## Usage

Launch LidLock and look for the lock icon in the menu bar. From the menu you can:

- **Enabled** — turn the whole feature on or off.
- **Action** — pick Lock or Sleep.
- **Delay** — pick how long after the lid closes the action runs.
- **Options → Launch at Login** — start LidLock automatically on login.

## License

Released under the [MIT License](LICENSE).
