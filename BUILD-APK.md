# بناء ملف APK لتطبيق «صلاتي»

المشروع الأصلي تطبيق **Flutter** في `extracted_app/salati/`،
وواجهة الويب في جذر المستودع (`src/`) هي تقرير/محاكاة فقط.

آخر بناء ناجح: **`salati-release.apk`** (universal — arm64-v8a + armeabi-v7a + x86_64)

| البند | القيمة |
|---|---|
| الحجم | ‎61.8 MB (61,845,197 بايت) |
| SHA-256 | `93df3185228f3bc076019b534e847399ed3df44ad7d48587d5e0bb6ac15d55f4` |
| Flutter | 3.29.3 (stable) |
| Android | compileSdk 35 · minSdk 23 · targetSdk 35 · AGP 8.7.3 · Gradle 8.12 · Kotlin 2.1.0 |
| الحزمة | `com.salati.app` — الإصدار `1.0.0 (1)` |
| التوقيع | مفتاح **debug** (يصلح للتثبيت المباشر، لا للنشر على Google Play) |

---

## كيف يُبنى الملف (GitHub Actions)

بيئة التطوير التي تُدار منها هذه المستودع لا تحتوي JDK/Android SDK/Flutter،
لذلك البناء يتم على مُشغّلات GitHub:

1. `.github/workflows/build-apk.yml` — يشغّل `ci/scripts/build_apk.sh` عند كل دفع
   إلى `arena/**` أو `main`، أو يدويًا عبر `workflow_dispatch`.
2. `ci/scripts/build_apk.sh` — يحمّل SDK Flutter المطلوب بنفسه (من
   `releases_linux.json`) ويجرّب ٣ تركيبات:
   | المحاولة | Flutter | compileSdk | AGP / Gradle / Kotlin |
   |---|---|---|---|
   | 1 | أحدث 3.29.x | 35 | 8.7.3 / 8.12 / 2.1.0 |
   | 2 | أحدث 3.32.x | 36 | 8.7.3 / 8.12 / 2.1.0 |
   | 3 | أحدث stable | 36 | 8.9.1 / 8.14 / 2.1.0 |
3. `ci/scripts/patch_android.py` — يكتب `android/app/build.gradle` وwrapper و
   `settings.gradle` لكل محاولة، مع:
   - `coreLibraryDesugaringEnabled = true` + `desugar_jdk_libs` (مطلوب لـ
     `flutter_local_notifications` 19.x).
   - `multiDexEnabled`، `minSdk` 23/24، `compileSdk` 35/36.
4. `ci/scripts/publish.sh` — ينشر الناتج في فرع `ci-artifacts`:
   `salati-release.apk` + `status.txt` + سجلات كل محاولة + `analyze-*.log`،
   **حتى عند الفشل** (لأن سجلات Actions غير متاحة لحساب البوت).

### استخراج الملف

```bash
git fetch origin +refs/heads/ci-artifacts:refs/remotes/origin/ci-artifacts
git show origin/ci-artifacts:salati-release.apk > salati-release.apk
sha256sum salati-release.apk        # قارنه بـ status.txt
```

أو تلقائيًا: `bash ci/watch-and-fetch.sh` (ينتظر البناء الناجح ويضع الملف في `apk/`).

---

## إصلاحات لازمة للبناء (مطبَّقة في هذا الفرع)

| المشكلة | الإصلاح |
|---|---|
| `geolocator_android 4.6.2` يستخدم `compileSdk flutter.compileSdkVersion` وهذا لا يعمل قبل Flutter 3.27 ([flutter#164362](https://github.com/flutter/flutter/issues/164362)) | البناء يستخدم Flutter ≥ 3.29 (يُحمَّل داخل السكربت) |
| `Unresolved reference: isCoreLibraryDesugaringEnabled` في Groovy DSL | `coreLibraryDesugaringEnabled = true` |
| `lib/screens/settings_screen.dart:328` — `AppColors.textMain` غير موجود | استُبدل بـ `AppColors.textPrimary` |
| `test/widget_test.dart` يستورد `package:prayer_now/...` (اسم الحزمة `salati`) | صُحّح الاستيراد وأُعيدت كتابة الاختبارات لتطابق واجهة `PrayerCalculator` |

---

## بناء محلي (Flutter + Android SDK + JDK 17)

```bash
cd extracted_app/salati
rm -f android/local.properties                  # يمنع مسار SDK قديم من إفساد البناء
python3 ../../ci/scripts/patch_android.py 1 .   # أو 2 / 3 حسب أدواتك
flutter pub get
flutter build apk --release
# الناتج: build/app/outputs/flutter-apk/app-release.apk
```

لبناء أصغر حجمًا لكل معمارية:

```bash
flutter build apk --release --split-per-abi
```

## التوقيع الحقيقي (للنشر على المتجر)

```bash
keytool -genkey -v -keystore salati-release.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias salati
```

ثم `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=salati
storeFile=/absolute/path/salati-release.jks
```

وفي `android/app/build.gradle`: أضف `signingConfigs.release` واجعل
`buildTypes.release.signingConfig = signingConfigs.release`.
