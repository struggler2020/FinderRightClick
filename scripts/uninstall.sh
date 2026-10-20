#!/bin/zsh
set -euo pipefail

INSTALL_APP="/Applications/FinderRightClick.app"
LAUNCH_AGENT="${HOME}/Library/LaunchAgents/com.opensource.FinderRightClick.plist"

echo "==> Unloading LaunchAgent..."
if [ -f "${LAUNCH_AGENT}" ]; then
    launchctl unload "${LAUNCH_AGENT}" 2>/dev/null || true
    rm -f "${LAUNCH_AGENT}"
fi

echo "==> Unregistering Finder Sync Extension..."
if [ -d "${INSTALL_APP}" ]; then
    pluginkit -r "${INSTALL_APP}/Contents/PlugIns/FinderRightClickExtension.appex" 2>/dev/null || true
fi

echo "==> Stopping processes..."
killall FinderRightClick 2>/dev/null || true
killall FinderRightClickExtension 2>/dev/null || true

echo "==> Removing ${INSTALL_APP}..."
rm -rf "${INSTALL_APP}"

echo "==> Uninstallation complete!"
