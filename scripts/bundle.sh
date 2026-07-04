#!/bin/bash
# Assemble the SwiftPM executable into a .app bundle and ad-hoc sign it.
# A proper bundle is required for LSUIElement, and ad-hoc signing keeps
# SMAppService (launch at login) stable.
set -euo pipefail

APP_NAME="LidLock"
EXECUTABLE="lidlock"
CONFIG="${CONFIG:-release}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/.build/${CONFIG}"
APP_DIR="${ROOT_DIR}/.build/${APP_NAME}.app"
ICON_SRC="${ROOT_DIR}/icons/lidlock.icon"

echo "==> Building (${CONFIG})"
swift build -c "${CONFIG}" --package-path "${ROOT_DIR}"

echo "==> Assembling ${APP_NAME}.app"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BUILD_DIR}/${EXECUTABLE}" "${APP_DIR}/Contents/MacOS/${EXECUTABLE}"
cp "${ROOT_DIR}/Resources/Info.plist" "${APP_DIR}/Contents/Info.plist"

echo "==> Compiling app icon (actool)"
# The app icon is an Icon Composer document (icons/lidlock.icon). Pass it to
# actool directly (as "AppIcon.icon"), compile it into an Assets.car, and merge
# the icon keys actool emits into the bundle Info.plist. Requires a full Xcode
# (actool >= 26, Icon Composer support) — Command Line Tools alone will fail.
ACTOOL="$(xcrun --find actool)"
ICON_TMP="$(mktemp -d)"
trap 'rm -rf "${ICON_TMP}"' EXIT
cp -R "${ICON_SRC}" "${ICON_TMP}/AppIcon.icon"
mkdir -p "${ICON_TMP}/out"
PARTIAL_PLIST="${ICON_TMP}/assetcatalog_generated_info.plist"

# Clear any stuck actool daemon that can make the compile silently produce nothing.
killall ibtoold >/dev/null 2>&1 || true

# Icon Composer (liquid glass) icons need a macOS 26 deployment target here; this
# is intentionally separate from the app's own (macOS 13) build target.
# With an older target actool emits no icon and still exits 0.
"${ACTOOL}" "${ICON_TMP}/AppIcon.icon" \
	--compile "${ICON_TMP}/out" \
	--output-format human-readable-text \
	--notices --warnings --errors \
	--output-partial-info-plist "${PARTIAL_PLIST}" \
	--app-icon AppIcon \
	--include-all-app-icons \
	--enable-on-demand-resources NO \
	--development-region en \
	--target-device mac \
	--minimum-deployment-target 26.0 \
	--platform macosx

if [ ! -f "${ICON_TMP}/out/Assets.car" ]; then
	echo "Error: actool did not generate Assets.car (app icon would be missing)" >&2
	"${ACTOOL}" --version || true
	exit 1
fi

cp "${ICON_TMP}/out/Assets.car" "${APP_DIR}/Contents/Resources/Assets.car"
/usr/libexec/PlistBuddy -c "Merge ${PARTIAL_PLIST}" "${APP_DIR}/Contents/Info.plist"
# Ensure the icon-name key is present even if actool's partial plist omitted it.
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "${APP_DIR}/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "${APP_DIR}/Contents/Info.plist"

echo "==> Ad-hoc signing"
codesign --force --sign - "${APP_DIR}"

echo "==> Done: ${APP_DIR}"
