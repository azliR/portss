#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

OUTPUT_ICNS="${PROJECT_ROOT}/Assets/AppIcon.icns"
RENDERER="${WORK_DIR}/render-app-icon"
ICONSET="${WORK_DIR}/AppIcon.iconset"

echo "Compiling icon renderer..."
swiftc -O \
    "${PROJECT_ROOT}/Sources/portss/UI/PortGlyph.swift" \
    "${PROJECT_ROOT}/scripts/app-icon/main.swift" \
    -o "${RENDERER}"

echo "Rendering iconset..."
"${RENDERER}" "${ICONSET}"

mkdir -p "$(dirname "${OUTPUT_ICNS}")"
iconutil --convert icns --output "${OUTPUT_ICNS}" "${ICONSET}"
echo "App icon written to ${OUTPUT_ICNS}"
