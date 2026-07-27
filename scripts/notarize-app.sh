#!/bin/bash
# Submits .build/LidLock.app to Apple's notary service and staples the resulting
# ticket into the bundle, so Gatekeeper accepts it on machines that have never
# seen the app and without network access.
#
# The app must already be signed with a Developer ID identity and the hardened
# runtime — run scripts/bundle.sh with CODESIGN_IDENTITY set first.
#
# Credentials come from an App Store Connect API key:
#   NOTARY_KEY_ID     Key ID of the key
#   NOTARY_ISSUER_ID  Issuer ID of the team
#   NOTARY_KEY_PATH   Path to the AuthKey_*.p8 private key
set -euo pipefail

APP_NAME="LidLock"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/.build/${APP_NAME}.app"

: "${NOTARY_KEY_ID:?NOTARY_KEY_ID is required}"
: "${NOTARY_ISSUER_ID:?NOTARY_ISSUER_ID is required}"
: "${NOTARY_KEY_PATH:?NOTARY_KEY_PATH is required}"

if [ ! -d "${APP_DIR}" ]; then
	echo "Error: ${APP_DIR} not found; run scripts/bundle.sh first" >&2
	exit 1
fi

# notarytool only accepts zip/pkg/dmg, so submit a throwaway archive. The ticket
# it issues is stapled to the .app itself afterwards, which means any archive
# built for distribution has to be created after this script runs.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${TMP_DIR}/${APP_NAME}.zip"

echo "==> Submitting to the notary service"
# --wait exits non-zero unless the submission comes back Accepted. It prints the
# submission id, so `xcrun notarytool log <id> --key ...` explains a rejection.
xcrun notarytool submit "${TMP_DIR}/${APP_NAME}.zip" \
	--key "${NOTARY_KEY_PATH}" \
	--key-id "${NOTARY_KEY_ID}" \
	--issuer "${NOTARY_ISSUER_ID}" \
	--wait

echo "==> Stapling the ticket"
xcrun stapler staple "${APP_DIR}"
# Confirm Gatekeeper would let the app run from the stapled ticket alone.
xcrun stapler validate "${APP_DIR}"
spctl --assess --type execute --verbose=4 "${APP_DIR}"

echo "==> Notarized: ${APP_DIR}"
