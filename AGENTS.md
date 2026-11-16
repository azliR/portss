# AGENTS.md

## Overview
`portss` is an ultra-lightweight macOS menu bar application designed for developers to keep track of development ports per project group.

## Architecture
The project follows a modular architecture using Swift Package Manager:
- `PortssCore` (Library target):
  - `Models/`: Core domain entities (`PortItem`, `PortGroup`, `ValidationError`). Enforces 24-character maximum constraints.
  - `Storage/`: Local persistence (`PortStorage`, `StorageError`) managing `~/Library/Application Support/portss/ports.json`.
  - `Utilities/`: Helper services (`ClipboardManager`).
- `portss` (Executable target):
  - `App/`: Application lifecycle (`AppDelegate`, `StatusBarController`).
  - `UI/`: Native macOS dialogs (`AddPortDialog`, `DeletePortDialog`, `DialogPresenter`).
  - `main.swift`: Entry point.
- `portssTests` (Test target):
  - Unit tests covering model validation, storage operations, and error handling.

## Build & Test Commands
- Run tests: `swift test`
- Build debug: `swift build`
- Build release .app bundle: `./scripts/build-app.sh`
- Output bundle: `dist/portss.app`

## Key Design Principles
- Pure AppKit (`NSStatusItem` + `NSMenu`) to maintain minimal memory footprint (~4-7 MB RAM) and small binary size (~190 KB).
- `LSUIElement = true` ensures the app lives solely in the macOS status bar without a Dock icon.
- No silent fallbacks: all failures raise loud errors via native modal dialogs.
