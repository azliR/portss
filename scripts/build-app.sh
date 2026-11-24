#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="portss"
OUTPUT_DIR="${PROJECT_ROOT}/dist"
APP_BUNDLE="${OUTPUT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
SYSTEM_APPLICATIONS_DIR="/Applications"

cd "${PROJECT_ROOT}"

echo "Building release binary..."
swift build -c release

rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${PROJECT_ROOT}/.build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

APP_ICON_SOURCE="${PROJECT_ROOT}/Assets/AppIcon.icns"
if [ ! -f "${APP_ICON_SOURCE}" ]; then
    echo "error: ${APP_ICON_SOURCE} is missing. Run ./scripts/generate-app-icon.sh first." >&2
    exit 1
fi
cp "${APP_ICON_SOURCE}" "${RESOURCES_DIR}/AppIcon.icns"

cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.${APP_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "Signing ad-hoc..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Application bundle created at: ${APP_BUNDLE}"

if [ -w "${SYSTEM_APPLICATIONS_DIR}" ]; then
    echo "Installing to ${SYSTEM_APPLICATIONS_DIR}/${APP_NAME}.app..."
    rm -rf "${SYSTEM_APPLICATIONS_DIR}/${APP_NAME}.app"
    cp -R "${APP_BUNDLE}" "${SYSTEM_APPLICATIONS_DIR}/${APP_NAME}.app"
    codesign --force --deep --sign - "${SYSTEM_APPLICATIONS_DIR}/${APP_NAME}.app"
fi
