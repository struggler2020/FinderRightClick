#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"
BUILD_DIR="${ROOT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/FinderRightClick.app"
EXT_BUNDLE="${APP_BUNDLE}/Contents/PlugIns/FinderRightClickExtension.appex"

echo "==> Cleaning build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${EXT_BUNDLE}/Contents/MacOS"
mkdir -p "${EXT_BUNDLE}/Contents/Resources"

cp "${ROOT_DIR}/Resources/HostInfo.plist" "${APP_BUNDLE}/Contents/Info.plist"
cp "${ROOT_DIR}/Resources/ExtensionInfo.plist" "${EXT_BUNDLE}/Contents/Info.plist"

echo "==> Compiling Host App (FinderRightClick)..."
swiftc \
    "${ROOT_DIR}/Sources/Shared/SharedModels.swift" \
    "${ROOT_DIR}/Sources/HostApp/HostApp.swift" \
    -parse-as-library \
    -O \
    -o "${APP_BUNDLE}/Contents/MacOS/FinderRightClick" \
    -framework Cocoa

echo "==> Compiling Finder Sync Extension (FinderRightClickExtension)..."
swiftc \
    "${ROOT_DIR}/Sources/Shared/SharedModels.swift" \
    "${ROOT_DIR}/Sources/FinderExtension/FinderSync.swift" \
    -parse-as-library \
    -application-extension \
    -O \
    -Xlinker -e -Xlinker _NSExtensionMain \
    -o "${EXT_BUNDLE}/Contents/MacOS/FinderRightClickExtension" \
    -framework Cocoa \
    -framework FinderSync

echo "==> Code-signing bundles..."
codesign --force --sign - --entitlements "${ROOT_DIR}/Resources/Extension.entitlements" "${EXT_BUNDLE}"
codesign --force --sign - "${APP_BUNDLE}"

echo "==> Build succeeded: ${APP_BUNDLE}"
