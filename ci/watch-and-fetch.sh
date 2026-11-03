#!/usr/bin/env bash
# Watcher: waits for the CI run to publish a *successful* APK on the
# ci-artifacts branch, then downloads it to ./apk/salati-release.apk.
set -uo pipefail
cd /home/user/salaati

BRANCH="arena/6ac9f0e2-salaati"
LOG=/tmp/watcher.log
APK_DIR=/home/user/salaati/apk
mkdir -p "$APK_DIR"

say() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$LOG"; }

for i in $(seq 1 80); do
  if git fetch -q origin ci-artifacts:refs/remotes/origin/ci-artifacts 2>/dev/null; then
    status=$(git show origin/ci-artifacts:status.txt 2>/dev/null | head -n 1)
    build_commit=$(git show origin/ci-artifacts:status.txt 2>/dev/null | sed -n 's/^commit: //p' | head -n 1)
    head_commit=$(git rev-parse "origin/$BRANCH" 2>/dev/null)
    say "attempt $i: ci-artifacts @ ${build_commit:0:8} status='${status:-none}' (branch head ${head_commit:0:8})"

    if [ "$status" = "BUILD SUCCESS" ] && [ "$build_commit" = "$head_commit" ]; then
      git show origin/ci-artifacts:salati-release.apk > "$APK_DIR/salati-release.apk"
      git show origin/ci-artifacts:status.txt > "$APK_DIR/status.txt" 2>/dev/null || true
      git show origin/ci-artifacts:HOW-TO-INSTALL.md > "$APK_DIR/HOW-TO-INSTALL.md" 2>/dev/null || true
      say "APK DOWNLOADED: $(du -h "$APK_DIR/salati-release.apk" | cut -f1) sha256=$(sha256sum "$APK_DIR/salati-release.apk" | cut -d' ' -f1)"
      cat "$APK_DIR/status.txt" | tee -a "$LOG"
      exit 0
    fi

    if [ -n "$build_commit" ] && [ "$build_commit" = "$head_commit" ] && [ "$status" != "BUILD SUCCESS" ]; then
      say "latest build for this commit FAILED — inspect ci/artifacts branch"
      git show origin/ci-artifacts:status.txt > "$APK_DIR/status.txt" 2>/dev/null || true
      exit 2
    fi
  else
    say "attempt $i: no ci-artifacts branch yet"
  fi
  sleep 60
done
say "TIMEOUT waiting for a successful APK"
exit 3
