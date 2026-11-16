# portss

A minimal, ultra-lightweight macOS menu bar note-taking application designed to track local development ports by project group.

- **Menu Bar Only**: Lives solely in your macOS status bar (`LSUIElement`), no Dock icon.
- **Ultra Lightweight**: Pure AppKit with binary size under 230 KB and minimal memory footprint (~4-7 MB RAM).
- **Flexible Sorting**: Sort ports on-the-fly by **Created**, **Updated**, **Key (A-Z)**, or **Value (Port)**.
- **Native Typography & Vibrancy**: Renders with native system `menuFont` and vibrancy support, seamlessly matching macOS menu items.
- **Flush-Right Table Layout**: Keys align strictly to the left, and values/ports align flush to the far right margin with zero trailing empty space.
- **Native Hover Highlights**: Interactive row hover feedback adhering to macOS system colors and dark/light modes.
- **Optional Groups & Folded Submenus**:
  - Standalone ports (no group) appear directly in the root menu for instant 1-click copying.
  - Grouped ports automatically collapse into native folded submenus.
- **Full Management (Add, Edit, Delete)**:
  - **Add Port...**: Add standalone or grouped ports.
  - **Edit Port...**: Select any port from dropdown, prefilled with current group, key, and value to easily modify.
  - **Delete Port...**: Delete specific ports or entire groups.
- **Max 24 Characters**: Key, value, and optional group name are constrained to 24 characters max.
- **Quick Copy**: Click any port item to immediately copy the port number to your clipboard.
- **Standard Keyboard Shortcuts**: Full support for `Cmd+A` (Select All), `Cmd+Z` (Undo), `Cmd+Shift+Z` (Redo), `Cmd+C` (Copy), `Cmd+V` (Paste), and `Cmd+X` (Cut) in all text fields.
- **Local Persistence**: Stored cleanly at `~/Library/Application Support/portss/ports.json`.
- **Free & Independent**: Works with standard Ad-hoc code signing without a paid Apple Developer account.

---

## Installation & Build

### Prerequisites
- macOS 13.0+
- Swift 6+ (bundled with Xcode or Command Line Tools)

### Build `.app` Bundle
To build the release application bundle:
```bash
./scripts/build-app.sh
```
The output application bundle will be created at `dist/portss.app`.

### Running the App
You can move `dist/portss.app` into `/Applications` or run it directly:
```bash
open dist/portss.app
```

---

## Usage

1. Click the **network** icon in your macOS status bar.
2. Select **Add Port...** to enter:
   - **Group (Optional)**: Leave blank for root menu item, or enter a name (e.g., `App A`) to fold into a submenu.
   - **Key**: (e.g., `web`)
   - **Value**: (e.g., `9400`)
3. Click any port in the menu list to copy its port number to the clipboard.
4. Select **Edit Port...** to modify the group, key, or port value of any existing item.
5. Select **Sort by** to change sort order:
   - **Created** (most recently created first)
   - **Updated** (most recently updated first)
   - **Key (A-Z)**
   - **Value (Port)** (numerical/alphabetical ascending)
6. Select **Delete Port...** to remove a specific port or entire group.
7. Select **Open ports.json** to view or edit the underlying JSON file directly.

---

## Testing

Run the test suite via Swift Package Manager:
```bash
swift test
```
