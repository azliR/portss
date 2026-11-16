# AGENTS.md

## Overview
`portss` is an ultra-lightweight macOS menu bar application designed for developers to keep track of development ports per project group.

## Architecture
The project follows a modular architecture using Swift Package Manager:
- `PortssCore` (Library target):
  - `Models/`: Core domain entities (`PortItem`, `PortGroup`, `PortStore`, `ValidationError`). Enforces 24-character maximum constraints. Supports optional groups for standalone items.
  - `Storage/`: Local persistence (`PortStorage`, `StorageError`) managing `~/Library/Application Support/portss/ports.json`.
  - `Utilities/`: Helper services (`ClipboardManager`).
- `portss` (Executable target):
  - `App/`: Application lifecycle (`AppDelegate`, `StatusBarController`). Configures standard Edit menu for text shortcuts.
  - `UI/`: Native macOS dialogs & custom item views (`AddPortDialog`, `DeletePortDialog`, `DialogPresenter`, `ShortcutTextField`, `PortMenuItemView`).
  - `main.swift`: Entry point.
- `portssTests` (Test target):
  - Unit tests covering model validation, storage operations, and error handling.

## Build & Test Commands
- Run tests: `swift test`
- Build debug: `swift build`
- Build release .app bundle: `./scripts/build-app.sh`
- Output bundle: `dist/portss.app`

## Key Design Principles
- Pure AppKit (`NSStatusItem` + `NSMenu`) to maintain minimal memory footprint (~4-7 MB RAM) and small binary size (~220 KB).
- `LSUIElement = true` ensures the app lives solely in the macOS status bar without a Dock icon.
- Optional groups: Standalone ports appear directly in the root menu; grouped ports are folded as submenus.
- Visual formatting: Native `PortMenuItemView` using AutoLayout flush-right trailing anchor (`trailingAnchor - 14`) ensuring no trailing whitespace on values, complete with native macOS hover highlighting and click-to-copy.
- Keyboard support: Native text shortcuts (`Cmd+A`, `Cmd+Z`, `Cmd+C`, `Cmd+V`, `Cmd+X`) supported in all dialog text fields.
- No silent fallbacks: all failures raise loud errors via native modal dialogs.
