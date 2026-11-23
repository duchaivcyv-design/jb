#!/bin/bash
# Builds ClaudeMini for iOS 12 (arm64) and packages it as a .deb.
# Runs on a macOS machine with Xcode (GitHub Actions: macos-latest).
set -euo pipefail
cd "$(dirname "$0")"

APP="ClaudeMini"
BUNDLE_ID="com.puc.claudemini"
VERSION="$(tr -d '[:space:]' < VERSION)"
# On GitHub Actions every build gets its run number: the app uses it to tell a newer build of the same version apart
# (the .deb version becomes 0.7.3-46, so the package manager also sees it as an upgrade).
BUILD_NUM="${GITHUB_RUN_NUMBER:-1}"
if [ -n "${GITHUB_RUN_NUMBER:-}" ]; then
  DEB_VERSION="$VERSION-$BUILD_NUM"
  IPA_VERSION="$VERSION-b$BUILD_NUM"
else
  DEB_VERSION="$VERSION"
  IPA_VERSION="$VERSION"
fi
OUT="build"
APPDIR="$OUT/pkg/Applications/$APP.app"
DIST="dist"

rm -rf "$OUT" "$DIST"
mkdir -p "$APPDIR" "$DIST"

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "SDK: $SDK"

echo "==> Compiling (arm64, iOS 12.0+)"
xcrun --sdk iphoneos clang \
  -arch arm64 \
  -miphoneos-version-min=12.0 \
  -isysroot "$SDK" \
  -fobjc-arc -fmodules -O2 -Wall -Wno-deprecated-declarations \
  src/*.m src/*.c \
  -framework UIKit -framework Foundation -framework Security -framework WebKit -framework ImageIO -framework AVFoundation -framework CoreMedia -framework CoreText -framework AuthenticationServices -lz \
  -o "$APPDIR/$APP"

echo "==> Compiling the icon helper (setuid root in the .deb only)"
xcrun --sdk iphoneos clang \
  -arch arm64 \
  -miphoneos-version-min=12.0 \
  -isysroot "$SDK" \
  -O2 -Wall \
  tools/iconhelper.c \
  -o "$OUT/claudemini-icon"

echo "==> Assembling bundle"
cp app/Info.plist "$APPDIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APPDIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APPDIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUM" "$APPDIR/Info.plist"
# The in-app updater always looks in the official updater repo (set in app/Info.plist).
# Override only on purpose: CLAUDEMINI_UPDATE_REPO=owner/repo ./build.sh
if [ -n "${CLAUDEMINI_UPDATE_REPO:-}" ]; then
  /usr/libexec/PlistBuddy -c "Set :ClaudeMiniUpdateRepo $CLAUDEMINI_UPDATE_REPO" "$APPDIR/Info.plist"
fi
# Google sign-in (optional). GOOGLE_OAUTH_CLIENT_ID is an iOS OAuth client ID from Google Cloud, e.g.
# 123456-abc.apps.googleusercontent.com. Without it the sign-in button stays hidden and only API keys are used.
if [ -n "${GOOGLE_OAUTH_CLIENT_ID:-}" ]; then
  GOOGLE_ID="$(printf '%s' "$GOOGLE_OAUTH_CLIENT_ID" | tr -d '[:space:]')"
  GOOGLE_PREFIX="${GOOGLE_ID%.apps.googleusercontent.com}"
  /usr/libexec/PlistBuddy -c "Delete :GoogleOAuthClientID" "$APPDIR/Info.plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :GoogleOAuthClientID string $GOOGLE_ID" "$APPDIR/Info.plist"
  if [ -n "${GOOGLE_CLOUD_PROJECT_ID:-}" ]; then
    /usr/libexec/PlistBuddy -c "Delete :GoogleCloudProjectID" "$APPDIR/Info.plist" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :GoogleCloudProjectID string $GOOGLE_CLOUD_PROJECT_ID" "$APPDIR/Info.plist"
  fi
  /usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$APPDIR/Info.plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy \
    -c "Add :CFBundleURLTypes array" \
    -c "Add :CFBundleURLTypes:0 dict" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string com.googleusercontent.apps.$GOOGLE_PREFIX" \
    "$APPDIR/Info.plist"
  echo "Google sign-in enabled for client $GOOGLE_ID"
else
  echo "Google sign-in disabled: GOOGLE_OAUTH_CLIENT_ID is not set"
fi
cp -R app/Resources/. "$APPDIR/"
printf 'APPL????' > "$APPDIR/PkgInfo"
find "$OUT" -name '.DS_Store' -delete

cp "$OUT/claudemini-icon" "$APPDIR/claudemini-icon"

echo "==> Pseudo-signing with ldid"
ldid -Sapp/entitlements.plist "$APPDIR/$APP"
ldid -Sapp/entitlements-helper.plist "$APPDIR/claudemini-icon"

echo "==> Packaging .deb"
mkdir -p "$OUT/pkg/DEBIAN"
cp deb/DEBIAN/postinst deb/DEBIAN/postrm "$OUT/pkg/DEBIAN/"
sed "s/@VERSION@/$DEB_VERSION/" deb/DEBIAN/control > "$OUT/pkg/DEBIAN/control"
chmod 755 "$OUT/pkg/DEBIAN/postinst" "$OUT/pkg/DEBIAN/postrm"
find "$OUT/pkg/Applications" -type d -exec chmod 755 {} +
find "$OUT/pkg/Applications" -type f -exec chmod 644 {} +
chmod 755 "$APPDIR/$APP"
chmod 4755 "$APPDIR/claudemini-icon"   # setuid root: lets the app swap its Home Screen icon (owner is root inside the .deb)

export COPYFILE_DISABLE=1
DEB="$DIST/${BUNDLE_ID}_${DEB_VERSION}_iphoneos-arm.deb"
dpkg-deb --root-owner-group -Zgzip -b "$OUT/pkg" "$DEB"

echo "==> Done: $DEB"
dpkg-deb -I "$DEB" | head -n 15

echo "==> Packaging the .ipa (for jailbroken devices with AppSync Unified)"
bash tools/make_ipa.sh "$APPDIR" "$IPA_VERSION" "$DIST"
ls -la "$DIST"
