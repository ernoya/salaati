#!/usr/bin/env bash
# Adaptive release build for the Salati Flutter app.
#
# The sandbox that drives this repo has no Android/Flutter toolchain, so the
# build happens on GitHub runners. Two things are adapted per attempt:
#   * the Flutter SDK version  (geolocator_android 4.6.2 needs Flutter >= 3.27,
#     which exposes `flutter.compileSdkVersion` to plugin projects — see
#     https://github.com/flutter/flutter/issues/164362)
#   * the Android toolchain     (compileSdk / AGP / Gradle / Kotlin / desugaring)
# Every attempt is logged to /tmp/ci-out so the result can be published even
# when the Actions log is not reachable.
set -uo pipefail

APP_DIR="extracted_app/salati"
APK_SRC="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
OUT="/tmp/ci-out"
SDK_ROOT="${HOME:-/root}/flutter-sdks"
mkdir -p "$OUT" "$SDK_ROOT"
: > "$OUT/status.txt"

# A stale local.properties points at a machine that does not exist on CI and
# breaks settings.gradle's flutter.sdk lookup.
rm -f "$APP_DIR/android/local.properties"

echo "runner flutter (preinstalled): $(command -v flutter) -> $(flutter --version 2>/dev/null | head -n 1)"
echo "java: $(java -version 2>&1 | head -n 1)"

# ---------------------------------------------------------------- Flutter SDKs
RELEASES_JSON="$OUT/flutter_releases_linux.json"
if ! curl -fsSL --retry 3 -o "$RELEASES_JSON" \
      https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json; then
  echo "warning: could not fetch Flutter release manifest, using hardcoded versions"
  echo '{"releases":[]}' > "$RELEASES_JSON"
fi

pick_version() {  # $1 = prefix ("3.29") or "" for latest stable; prints version
  python3 - "$RELEASES_JSON" "$1" <<'PY'
import json, sys
path, prefix = sys.argv[1], sys.argv[2]
try:
    releases = json.load(open(path))["releases"]
except Exception:
    releases = []
def key(v):
    out = []
    for part in v.split("."):
        try:
            out.append(int(part))
        except ValueError:
            out.append(0)
    return out
stable = [r for r in releases if r.get("channel") == "stable" and r.get("version")]
if prefix:
    stable = [r for r in stable if r["version"].startswith(prefix + ".")]
if stable:
    print(sorted(stable, key=lambda r: key(r["version"]))[-1]["version"])
PY
}

ensure_flutter() {  # $1 = version -> prints bin dir
  local v="$1" d
  [ -n "$v" ] || return 1
  d="$SDK_ROOT/$v"
  if [ ! -x "$d/bin/flutter" ]; then
    echo "downloading Flutter $v ..."
    rm -rf "$d" "$SDK_ROOT/unpack"
    mkdir -p "$SDK_ROOT/unpack"
    if ! curl -fsSL --retry 3 -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${v}-stable.tar.xz"; then
      echo "download failed for Flutter $v"
      return 1
    fi
    tar -xJf /tmp/flutter.tar.xz -C "$SDK_ROOT/unpack" || return 1
    mv "$SDK_ROOT/unpack/flutter" "$d" || return 1
    rm -rf "$SDK_ROOT/unpack" /tmp/flutter.tar.xz
  fi
  git config --global --add safe.directory "$d" >/dev/null 2>&1 || true
  echo "$d/bin"
}

flutter_version_for() {  # $1 = profile
  local v
  case "$1" in
    1) v=$(pick_version 3.29); [ -n "$v" ] || v=3.29.3 ;;
    2) v=$(pick_version 3.32); [ -n "$v" ] || v=3.32.8 ;;
    3) v=$(pick_version "");   [ -n "$v" ] || v=3.35.7 ;;
  esac
  echo "$v"
}

# ---------------------------------------------------------------- helpers
finish() {
  local rc=$1
  echo "$2" > "$OUT/status.txt"
  exit "$rc"
}

log_tail() {
  echo "----- tail: $1 -----"
  tail -n 100 "$1" || true
}

build_once() {
  local profile=$1 v bindir
  v=$(flutter_version_for "$profile")
  if [ -z "$v" ]; then
    echo "could not resolve a Flutter version for profile $profile"
    return 11
  fi

  echo "=================================================="
  echo "Attempt: profile $profile — Flutter $v"
  echo "=================================================="

  bindir=$(ensure_flutter "$v") || return 12
  export PATH="$bindir:$PATH"
  export FLUTTER_ROOT="$(dirname "$bindir")"
  echo "using flutter: $(command -v flutter)"
  # Keep pub cache shared between SDKs to avoid re-downloading packages.
  export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"

  python3 ci/scripts/patch_android.py "$profile" "$APP_DIR" > "$OUT/patch-$profile.log" 2>&1
  cat "$OUT/patch-$profile.log"

  {
    echo "flutter version: $(flutter --version 2>&1 | head -n 1)"
    echo "dart version:    $(dart --version 2>&1 | head -n 1)"
  } >> "$OUT/patch-$profile.log"
  flutter config --no-analytics >/dev/null 2>&1 || true

  ( cd "$APP_DIR" && flutter pub get ) > "$OUT/pubget-$profile.log" 2>&1
  if [ $? -ne 0 ]; then
    log_tail "$OUT/pubget-$profile.log"
    return 10
  fi

  ( cd "$APP_DIR" && flutter build apk --release ) > "$OUT/build-$profile.log" 2>&1
  local rc=$?
  log_tail "$OUT/build-$profile.log"
  return "$rc"
}

cleanup_between_attempts() {
  ( cd "$APP_DIR" && flutter clean ) > /dev/null 2>&1 || true
  ( cd "$APP_DIR/android" && ./gradlew --stop ) > /dev/null 2>&1 || true
  rm -rf "$APP_DIR/android/.gradle" "$APP_DIR/android/app/.cxx" || true
  rm -f "$APP_DIR/android/local.properties"
}

collect_debug_info() {
  # Plugin gradle files that decide compileSdk/minSdk requirements.
  local dest="$OUT/plugin-gradle" f
  mkdir -p "$dest"
  for f in "$HOME"/.pub-cache/hosted/pub.dev/{geolocator_android-*,audioplayers_android-*,flutter_local_notifications-*,flutter_compass-*}/android/build.gradle; do
    [ -f "$f" ] || continue
    cp "$f" "$dest/$(echo "$f" | sed 's#.*/pub.dev/##; s#/android/build.gradle##').gradle" 2>/dev/null || true
  done
  ( cd "$APP_DIR" && flutter doctor -v ) > "$OUT/flutter-doctor.log" 2>&1 || true
}

last_rc=1
for profile in 1 2 3; do
  build_once "$profile"
  last_rc=$?
  if [ "$last_rc" -eq 0 ] && [ -f "$APK_SRC" ]; then
    cp "$APK_SRC" "$OUT/salati-release.apk"
    cp "$OUT/build-$profile.log" "$OUT/build.log"
    collect_debug_info
    {
      echo "BUILD SUCCESS"
      echo "profile: $profile"
      echo "flutter: $(cd "$APP_DIR" && flutter --version 2>/dev/null | head -n 1)"
      echo "commit: ${GITHUB_SHA:-unknown}"
      echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo "size: $(du -h "$OUT/salati-release.apk" | cut -f1)"
      echo "sha256: $(sha256sum "$OUT/salati-release.apk" | cut -d' ' -f1)"
    } > "$OUT/status.txt"
    cat "$OUT/status.txt"
    exit 0
  fi
  echo "profile $profile failed (exit $last_rc)"
  if [ "$last_rc" -eq 10 ]; then
    finish 1 "BUILD FAILED at dependency resolution (profile $profile) — see pubget-$profile.log"
  fi
  cleanup_between_attempts
done

collect_debug_info

# Surface the most useful error lines to make the failure obvious.
{
  echo "BUILD FAILED (last exit $last_rc)"
  echo "commit: ${GITHUB_SHA:-unknown}"
  echo
  echo "--- extracted errors ---"
  grep -h -E "FAILURE:|What went wrong|^e: |error:|Error:|Execution failed|requires .* (compile)?Sdk|Namespace not specified|Unsupported|Could not|Exception|not found" \
    "$OUT"/build-*.log 2>/dev/null | sort -u | tail -n 80
} > "$OUT/status.txt"
cat "$OUT/status.txt"
exit 1
