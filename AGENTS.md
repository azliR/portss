# AGENTS.md

## Overview
`portss` is an ultra-lightweight macOS menu bar application designed for developers to keep track of development ports per project group.

## Architecture
The project follows a modular architecture using Swift Package Manager:
- `PortssCore` (Library target):
  - `Models/`: Core domain entities (`PortItem`, `PortGroup`, `PortStore`, `PortSortOption`, `ValidationError`). Enforces 24-character maximum constraints. Tracks timestamps (`createdAt`, `updatedAt`). Supports optional groups for standalone items.
  - `Storage/`: Local persistence (`PortStorage`, `StorageError`) managing `~/Library/Application Support/portss/ports.json`. `PortStorage+Management` adds id-based create/rename group, add/update/move/remove item APIs that reject duplicate keys/group names and keep empty groups.
  - `Utilities/`: Helper services (`ClipboardManager`, `PortSorter`, `LaunchAtLoginManager`).
- `portss` (Executable target):
  - `App/`: Application lifecycle (`AppDelegate`, `StatusBarController`). Configures standard Edit menu for text shortcuts.
  - `UI/`: Error/confirmation alerts and custom menu item views (`DialogPresenter`, `PortMenuItemView`, `GroupMenuItemView`).
    - `UI/Manage/`: `ManagePortsWindowController` (split into `+Outline`, `+Editing`, `+DragDrop` extensions), `ManagePortsNode`, `ManagePortsOutlineView`. A single window with an `NSOutlineView` for inline editing of groups and ports, drafts for new rows, drag & drop between groups, and validation errors shown in the window status line.
  - `main.swift`: Entry point.
- `portssTests` (Test target):
  - Unit tests covering model validation, storage operations, sorting logic, autostart launch agent management, and error handling.

## Build & Test Commands
- Run tests: `swift test`
- Build debug: `swift build`
- Build release .app bundle & install: `./scripts/build-app.sh`
- Output bundle: `dist/portss.app` and `/Applications/portss.app`

## Key Design Principles
- Pure AppKit (`NSStatusItem` + `NSMenu`) to maintain minimal memory footprint (~4-7 MB RAM) and small binary size (~220 KB).
- `LSUIElement = true` ensures the app lives solely in the macOS status bar without a Dock icon.
- Optional groups: Standalone ports appear directly in the root menu; grouped ports are folded as submenus. Group rows use `GroupMenuItemView` (same 14pt leading inset) so they stay aligned with standalone items regardless of the root menu state column.
- Visual formatting: Native `PortMenuItemView` using AutoLayout flush-right trailing anchor (`trailingAnchor - 14`) and `allowsVibrancy = true` with `NSFont.menuFont(ofSize: 0)` ensuring native system menu typography and zero trailing whitespace.
- Sorting: Dynamic sorting by `Created`, `Updated`, `Key (A-Z)`, or `Value (Port)` persisted via `UserDefaults`.
- Autostart on boot: Native `LaunchAtLoginManager` manages `~/Library/LaunchAgents/com.local.portss.plist` pointing to `/Applications/portss.app`, toggleable via the status bar menu.
- Keyboard support: Native text shortcuts (`Cmd+A`, `Cmd+Z`, `Cmd+C`, `Cmd+V`, `Cmd+X`) supported in Manage Ports text cells via the standard Edit menu; `Cmd+W` closes the window.
- Full CRUD operations: Add, Edit, Delete for all ports and groups, exclusively via the `Manage Ports...` window (`Cmd+,` in the menu); the status bar menu is for quick copy and settings.
- No silent fallbacks: validation errors are shown in red in the Manage Ports status line with a beep; storage/IO failures raise native modal alerts.
