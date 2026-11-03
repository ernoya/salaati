#!/usr/bin/env bash
# Watcher: waits until .github/workflows/build-apk.yml can be pushed (GitHub
# App gains the `workflows` permission) OR appears on the remote branch, then
# waits for the CI run to publish the APK to the ci-artifacts branch and
# downloads it into ./apk/.
set -uo pipefail
cd /home/user/salaati

BRANCH="arena/6ac9f0e2-salaati"
WF=".github/workflows/build-apk.yml"
LOG=/tmp/watcher.log
APK_DIR=/home/user/salaati/apk
mkdir -p "$APK_DIR"

say() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$LOG"; }

wf_on_remote() {
  git fetch -q origin "$BRANCH" 2>/dev/null || return 1
  git cat-file -e "origin/$BRANCH:$WF" 2>/dev/null
}

pushed=0
for i in $(seq 1 90); do
  if wf_on_remote; then
    say "workflow file present on remote"
    pushed=1
    break
  fi
  if [ -f "$WF" ]; then
    git add "$WF" 2>/dev/null
    git diff --cached --quiet || git commit -q -m "ci: enable Salati APK build workflow"
  fi
  out=$(git push origin HEAD:"$BRANCH" 2>&1)
  if [ $? -eq 0 ]; then
    say "PUSH OK — workflow enabled on $BRANCH"
    pushed=1
    break
  fi
  case "$out" in
    *"without \`workflows\` permission"*)
      say "attempt $i: still no workflows permission" ;;
    *"non-fast-forward"*|*"fetch first"*)
      git fetch -q origin && git rebase -q "origin/$BRANCH" >/dev/null 2>&1
      say "attempt $i: rebased onto remote" ;;
    *)
      say "attempt $i: $(echo "$out" | tail -1)" ;;
  esac
  sleep 30
done

if [ "$pushed" -ne 1 ]; then
  say "GAVE UP: could not publish workflow file"
  exit 1
fi

say "waiting for ci-artifacts branch (build ~10-20 min)"
for i in $(seq 1 80); do
  if git ls-remote --exit-code --heads origin ci-artifacts >/dev/null 2>&1; then
    say "ci-artifacts branch found, fetching"
    git fetch -q origin ci-artifacts
    if git show origin/ci-artifacts:status.txt > "$APK_DIR/status.txt" 2>/dev/null; then
      cat "$APK_DIR/status.txt" | tee -a "$LOG"
    fi
    if git cat-file -e origin/ci-artifacts:salati-release.apk 2>/dev/null; then
      git show origin/ci-artifacts:salati-release.apk > "$APK_DIR/salati-release.apk"
      git show origin/ci-artifacts:HOW-TO-INSTALL.md > "$APK_DIR/HOW-TO-INSTALL.md" 2>/dev/null || true
      say "APK DOWNLOADED: $(du -h "$APK_DIR/salati-release.apk" | cut -f1) sha256=$(sha256sum "$APK_DIR/salati-release.apk" | cut -d' ' -f1)"
      exit 0
    fi
    say "ci-artifacts exists but no APK yet (build failed?) — see $APK_DIR/status.txt"
    exit 2
  fi
  sleep 30
done
say "TIMEOUT waiting for ci-artifacts"
exit 3
