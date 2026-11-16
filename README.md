# portss

A minimal, ultra-lightweight macOS menu bar note-taking application designed to track local development ports by project group.

- **Menu Bar Only**: Lives solely in your macOS status bar (`LSUIElement`), no Dock icon.
- **Ultra Lightweight**: Pure AppKit with binary size under 200 KB and minimal memory footprint (~4-7 MB RAM).
- **Grouped Key-Value**: Max 24 characters for key and value (e.g. Group: `App A`, Key: `web`, Value: `9400`).
- **Quick Copy**: Click any port item to immediately copy the port number to your clipboard.
- **Local Persistence**: Stored at `~/Library/Application Support/portss/ports.json`.
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
   - **Group** (e.g., `App A`)
   - **Key** (e.g., `web`)
   - **Value** (e.g., `9400`)
3. Click any port in the menu list to copy its port number to the clipboard.
4. Select **Delete Port...** to remove a specific port or entire group.
5. Select **Open ports.json** to view or edit the underlying JSON file directly.

---

## Testing

Run the test suite via Swift Package Manager:
```bash
swift test
```
