#!/bin/bash
# Packages an already-built ClaudeMini.app as a fake-signed .ipa for JAILBROKEN devices that have AppSync Unified.
#   tools/make_ipa.sh <path/to/ClaudeMini.app> <version> <output folder>
# The .app is copied (the original, signed for the .deb, is left untouched) and its binary is re-signed with the
# entitlements in app/entitlements-ipa.plist. This variant runs inside the normal app sandbox, like any App Store app.
set -euo pipefail

# Paths given on the command line are relative to where the caller is, so make them absolute BEFORE changing folder.
CALLER_DIR="$PWD"
absolute() { case "$1" in /*) printf '%s' "$1" ;; *) printf '%s/%s' "$CALLER_DIR" "$1" ;; esac; }

APP_SRC="$(absolute "${1:?usage: make_ipa.sh <ClaudeMini.app> <version> <output folder>}")"
VERSION="${2:?missing version}"
OUT_DIR="$(absolute "${3:?missing output folder}")"

cd "$(dirname "$0")/.."   # project root: the entitlements file is found relative to it
APP_NAME="ClaudeMini"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

[ -d "$APP_SRC" ] || { echo "no such app bundle: $APP_SRC" >&2; exit 1; }
[ -f "$APP_SRC/$APP_NAME" ] || { echo "the bundle has no executable named $APP_NAME" >&2; exit 1; }

mkdir -p "$WORK/Payload" "$OUT_DIR"
cp -R "$APP_SRC" "$WORK/Payload/$APP_NAME.app"
find "$WORK" -name '.DS_Store' -delete

rm -f "$WORK/Payload/$APP_NAME.app/claudemini-icon"   # the root helper is for the rootful .deb only

echo "==> Re-signing the binary for the .ipa (sandboxed app entitlements)"
ldid -Sapp/entitlements-ipa.plist "$WORK/Payload/$APP_NAME.app/$APP_NAME"

# normal permissions: folders 755, files 644, the executable 755
find "$WORK/Payload" -type d -exec chmod 755 {} +
find "$WORK/Payload" -type f -exec chmod 644 {} +
chmod 755 "$WORK/Payload/$APP_NAME.app/$APP_NAME"

export COPYFILE_DISABLE=1
IPA="$(cd "$OUT_DIR" && pwd)/${APP_NAME}_${VERSION}.ipa"
rm -f "$IPA"
(cd "$WORK" && zip -qry -X "$IPA" Payload)
echo "==> Done: $IPA"
