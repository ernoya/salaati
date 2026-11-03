#!/usr/bin/env bash
# Pushes build outputs (APK + logs) to the ci-artifacts branch so they can be
# retrieved with plain git, and so failures stay diagnosable.
set -uo pipefail

OUT="/tmp/ci-out"
mkdir -p "$OUT"

if [ ! -f "$OUT/status.txt" ]; then
  echo "BUILD DID NOT RUN" > "$OUT/status.txt"
fi

cat > "$OUT/HOW-TO-INSTALL.md" <<'MD'
# صلاتي — تثبيت ملف APK

1. انقل ملف `salati-release.apk` إلى هاتف أندرويد.
2. افتح الملف، وإذا ظهر تحذير فاختر **السماح بالتثبيت من هذا المصدر**.
3. ثبّت التطبيق ثم افتحه وامنح أذونات الموقع والإشعارات.

- التطبيق موقّع بمفتاح التطوير (debug)، لذلك يصلح للتجربة والتثبيت المباشر فقط،
  وليس للنشر على Google Play. للنشر يجب إنشاء keystore خاص بـ release.
- الحزمة: com.salati.app — الإصدار: 1.0.0 (1)
MD

cd "$OUT"
git init -q -b ci-artifacts 2>/dev/null || true
git config user.name "salati-ci"
git config user.email "ci@users.noreply.github.com"
git checkout -q -B ci-artifacts
git add -A
git commit -q -m "APK build ${GITHUB_SHA:-local} ($(date -u +%Y-%m-%dT%H:%M:%SZ))" || echo "nothing to commit"

REMOTE="https://x-access-token:${CI_PUSH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"
git push -f origin ci-artifacts && echo "published to ci-artifacts"
