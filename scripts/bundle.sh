#!/bin/bash
# Assemble the SwiftPM executable into a .app bundle and ad-hoc sign it.
# A proper bundle is required for LSUIElement, and ad-hoc signing keeps
# SMAppService (launch at login) stable.
set -euo pipefail

APP_NAME="LidLock"
EXECUTABLE="lidlock"
CONFIG="${CONFIG:-release}"
DEPLOYMENT_TARGET="13.0"

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
# The app icon is an Icon Composer document (icons/lidlock.icon). actool needs
# it inside an asset catalog as "AppIcon", so stage a throwaway catalog, compile
# it into the bundle's Resources (producing Assets.car + a legacy .icns), and
# merge the icon keys actool emits (CFBundleIconName / CFBundleIconFile) into the
# bundle Info.plist. Requires Xcode 26+ tooling (Icon Composer support).
ACTOOL="$(xcrun --find actool)"
ASSET_TMP="$(mktemp -d)"
trap 'rm -rf "${ASSET_TMP}"' EXIT
ASSET_CATALOG="${ASSET_TMP}/Assets.xcassets"
mkdir -p "${ASSET_CATALOG}"
cat >"${ASSET_CATALOG}/Contents.json" <<'JSON'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON
cp -R "${ICON_SRC}" "${ASSET_CATALOG}/AppIcon.icon"

PARTIAL_PLIST="${ASSET_TMP}/icon-info.plist"
"${ACTOOL}" "${ASSET_CATALOG}" \
	--compile "${APP_DIR}/Contents/Resources" \
	--output-partial-info-plist "${PARTIAL_PLIST}" \
	--app-icon AppIcon \
	--platform macosx \
	--minimum-deployment-target "${DEPLOYMENT_TARGET}" \
	--target-device mac \
	--errors --warnings --notices

/usr/libexec/PlistBuddy -c "Merge ${PARTIAL_PLIST}" "${APP_DIR}/Contents/Info.plist"

echo "==> Ad-hoc signing"
codesign --force --sign - "${APP_DIR}"

echo "==> Done: ${APP_DIR}"
