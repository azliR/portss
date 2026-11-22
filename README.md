# portss

A minimal, ultra-lightweight macOS menu bar note-taking application designed to track local development ports by project group.

- **Menu Bar Only**: Lives solely in your macOS status bar (`LSUIElement`), no Dock icon.
- **Ultra Lightweight**: Pure AppKit with binary size under 230 KB and minimal memory footprint (~4-7 MB RAM).
- **Autostart on Restart/Login**: Seamless automatic launch on user login via native macOS `LaunchAgents`, with an in-app toggle (`Launch at Login [✓]`).
- **Flexible Sorting**: Sort ports on-the-fly by **Created**, **Updated**, **Key (A-Z)**, or **Value (Port)**.
- **Native Typography & Vibrancy**: Renders with native system `menuFont` and vibrancy support, seamlessly matching macOS menu items.
- **Flush-Right Table Layout**: Keys align strictly to the left, and values/ports align flush to the far right margin with zero trailing empty space.
- **Native Hover Highlights**: Interactive row hover feedback adhering to macOS system colors and dark/light modes.
- **Optional Groups & Folded Submenus**:
  - Standalone ports (no group) appear directly in the root menu for instant 1-click copying.
  - Grouped ports automatically collapse into native folded submenus.
- **Full Management (Add, Edit, Delete)**:
  - **Manage Ports...**: One window to add, rename, edit, move (drag & drop), and remove ports and groups inline.
- **Max 24 Characters**: Key, value, and optional group name are constrained to 24 characters max.
- **Quick Copy**: Click any port item to immediately copy the port number to your clipboard.
- **Standard Keyboard Shortcuts**: Full support for `Cmd+A` (Select All), `Cmd+Z` (Undo), `Cmd+Shift+Z` (Redo), `Cmd+C` (Copy), `Cmd+V` (Paste), and `Cmd+X` (Cut) in the Manage Ports window, plus `Cmd+W` to close it.
- **Local Persistence**: Stored cleanly at `~/Library/Application Support/portss/ports.json`.
- **Free & Independent**: Works with standard Ad-hoc code signing without a paid Apple Developer account.

---

## Installation & Build

### Prerequisites
- macOS 13.0+
- Swift 6+ (bundled with Xcode or Command Line Tools)

### Build & Install `.app` Bundle
To build the release application bundle and install it to `/Applications`:
```bash
./scripts/build-app.sh
```
The application bundle is created at `dist/portss.app` and automatically installed to `/Applications/portss.app`.

### Running the App
You can open `/Applications/portss.app` directly:
```bash
open /Applications/portss.app
```

---

## Usage

1. Click the **network** icon in your macOS status bar.
2. Click any port in the menu list to copy its port number to the clipboard.
3. Select **Manage Ports...** (`Cmd+,`) to manage everything in one window:
   - **Add Port** / **Add Group** insert a new row and start editing it inline (the port goes into the selected group).
   - Double-click a cell or press Return to rename a group or edit a key/port; Escape cancels.
   - Drag a port onto a group (or the empty area for standalone) to move it.
   - **Remove** or the Delete key removes the selected row; groups with ports ask for confirmation.
   - Validation errors (empty fields, duplicate keys or group names) appear in red at the bottom of the window.
4. Select **Sort by** to change the menu sort order:
   - **Created** (most recently created first)
   - **Updated** (most recently updated first)
   - **Key (A-Z)**
   - **Value (Port)** (numerical/alphabetical ascending)
5. Toggle **Launch at Login** to enable or disable automatic startup upon machine restart/login.
6. Select **Open ports.json** to view or edit the underlying JSON file directly.

---

## Testing

Run the test suite via Swift Package Manager:
```bash
swift test
```
