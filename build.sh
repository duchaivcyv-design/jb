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

# Rust core (core/): hot paths that do not touch UIKit. It is optional: if Rust is missing, fails to build, or fails to link,
# the same functions are compiled from their Objective-C versions and the app behaves the same.
RUST_LIB=""
if [ -d core ] && command -v cargo >/dev/null 2>&1; then
  echo "==> Building the Rust core (iOS arm64)"
  rustup target add aarch64-apple-ios >/dev/null 2>&1 || true
  if IPHONEOS_DEPLOYMENT_TARGET=12.0 cargo build --release --lib --target aarch64-apple-ios --manifest-path core/Cargo.toml; then
    RUST_LIB="core/target/aarch64-apple-ios/release/libclaudemini_core.a"
    [ -f "$RUST_LIB" ] || RUST_LIB=""
  else
    echo "WARNING: the Rust core did not build; using the Objective-C versions"
  fi
else
  echo "==> Rust core skipped (cargo not found); using the Objective-C versions"
fi

compile_app() {   # $1 = 1 to link the Rust core, 0 to use the Objective-C fallbacks
  local extra=()
  if [ "$1" = "1" ]; then extra=(-DCM_USE_RUST=1 -Icore/include "$RUST_LIB"); else extra=(-DCM_USE_RUST=0); fi
  xcrun --sdk iphoneos clang \
    -arch arm64 \
    -miphoneos-version-min=12.0 \
    -isysroot "$SDK" \
    -fobjc-arc -fmodules -O2 -Wall -Wno-deprecated-declarations \
    "${extra[@]}" \
    src/*.m src/*.c \
    -framework UIKit -framework Foundation -framework Security -framework AuthenticationServices -framework WebKit -framework ImageIO -framework AVFoundation -framework CoreMedia -framework CoreText -lz \
    -o "$APPDIR/$APP"
}

echo "==> Compiling (arm64, iOS 12.0+)"
if [ -n "$RUST_LIB" ]; then
  if compile_app 1; then
    echo "Rust core linked"
  else
    echo "WARNING: linking the Rust core failed; building with the Objective-C versions"
    compile_app 0
  fi
else
  compile_app 0
fi

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
