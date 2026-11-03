#!/usr/bin/env bash
# Adaptive release build for the Salati Flutter app.
# Tries the project's original Android toolchain first, then escalates
# (compileSdk / AGP / Gradle / Kotlin) if a plugin demands a newer one.
# Every attempt is logged to /tmp/ci-out so the result can be published
# even when Actions logs are not reachable.
set -uo pipefail

APP_DIR="extracted_app/salati"
APK_SRC="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
OUT="/tmp/ci-out"
mkdir -p "$OUT"
: > "$OUT/status.txt"

# A stale local.properties points at a machine that does not exist on CI and
# breaks settings.gradle's flutter.sdk lookup.
rm -f "$APP_DIR/android/local.properties"

finish() {
  local rc=$1
  echo "$2" > "$OUT/status.txt"
  exit "$rc"
}

log_tail() {
  echo "----- tail: $1 -----"
  tail -n 80 "$1" || true
}

build_once() {
  local profile=$1
  echo "=================================================="
  echo "Attempt: profile $profile"
  echo "=================================================="

  python3 .github/scripts/patch_android.py "$profile" "$APP_DIR" > "$OUT/patch-$profile.log" 2>&1
  cat "$OUT/patch-$profile.log"

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

last_rc=1
for profile in 1 2 3; do
  build_once "$profile"
  last_rc=$?
  if [ "$last_rc" -eq 0 ] && [ -f "$APK_SRC" ]; then
    cp "$APK_SRC" "$OUT/salati-release.apk"
    cp "$OUT/build-$profile.log" "$OUT/build.log"
    {
      echo "BUILD SUCCESS"
      echo "profile: $profile"
      echo "commit: ${GITHUB_SHA:-unknown}"
      echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo "flutter: $(flutter --version | head -n 1)"
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

# Surface the most useful error lines to make the failure obvious.
{
  echo "BUILD FAILED (last exit $last_rc)"
  echo "commit: ${GITHUB_SHA:-unknown}"
  echo
  echo "--- extracted errors ---"
  grep -h -E "FAILURE:|What went wrong|error:|Error:|Execution failed|requires .* compile|not found|Exception" \
    "$OUT"/build-*.log 2>/dev/null | tail -n 60
} > "$OUT/status.txt"
cat "$OUT/status.txt"
exit 1
