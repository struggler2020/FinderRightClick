#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"
INSTALL_APP="/Applications/FinderRightClick.app"
LAUNCH_AGENT="${HOME}/Library/LaunchAgents/com.opensource.FinderRightClick.plist"

"${SCRIPT_DIR}/build.sh"

echo "==> Stopping existing instances..."
killall FinderRightClick 2>/dev/null || true
killall FinderRightClickExtension 2>/dev/null || true

echo "==> Installing to ${INSTALL_APP}..."
rm -rf "${INSTALL_APP}"
cp -R "${ROOT_DIR}/build/FinderRightClick.app" "${INSTALL_APP}"

echo "==> Configuring LaunchAgent for background host persistence..."
mkdir -p "${HOME}/Library/LaunchAgents"
cat << EOF > "${LAUNCH_AGENT}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.opensource.FinderRightClick</string>
    <key>ProgramArguments</key>
    <array>
        <string>${INSTALL_APP}/Contents/MacOS/FinderRightClick</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl unload "${LAUNCH_AGENT}" 2>/dev/null || true
launchctl load "${LAUNCH_AGENT}"

echo "==> Registering and enabling Finder Sync Extension..."
pluginkit -a "${INSTALL_APP}/Contents/PlugIns/FinderRightClickExtension.appex"
pluginkit -e use -i com.opensource.FinderRightClick.Extension

echo "==> Installation complete!"
