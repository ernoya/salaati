# بناء ملف APK لتطبيق «صلاتي»

المشروع الأصلي تطبيق **Flutter** موجود في `extracted_app/salati/`.
واجهة الويب في جذر المستودع (`src/`) هي تقرير/محاكاة فقط وليست التطبيق نفسه.

هناك طريقتان لإنتاج `app-release.apk`:

---

## ١) عبر GitHub Actions (بدون أي أدوات على جهازك)

ملف سير العمل الجاهز موجود في `ci/build-apk.workflow.yml`.
لتشغيله:

```bash
cp ci/build-apk.workflow.yml .github/workflows/build-apk.yml
git add .github/workflows/build-apk.yml
git commit -m "ci: build APK"
git push
```

> **مهم:** رفع أي ملف داخل `.github/workflows` يتطلّب صلاحية `workflows`
> في اتصال GitHub. إذا رُفض الرفع برسالة
> `refusing to allow a GitHub App to create or update workflow`،
> فأعد ربط GitHub من إعدادات Arena بصلاحية `workflows` (أو استخدم
> Personal Access Token يحتوي النطاق `workflow`).

ما يفعله السير:

1. يثبّت JDK 17 و Flutter 3.24.5.
2. يطبّق إعدادات أندرويد متوافقة عبر `ci/scripts/patch_android.py`
   (تفعيل `coreLibraryDesugaring` المطلوب لـ `flutter_local_notifications`،
   ورفع `compileSdk`/AGP/Gradle/Kotlin تدريجيًا عند الحاجة).
3. يبني `flutter build apk --release` (universal — يعمل على arm64/arm/x64).
4. ينشر الناتج في فرع `ci-artifacts` باسم `salati-release.apk` مع السجلات
   و`status.txt`، حتى لو فشل البناء (لتشخيص السبب).

لاستخراج الملف بعد نجاح السير:

```bash
git fetch origin ci-artifacts
git show origin/ci-artifacts:salati-release.apk > salati-release.apk
sha256sum salati-release.apk   # قارنه بقيمة status.txt
```

---

## ٢) بناء محلي (يتطلّب Flutter + Android SDK + JDK 17)

```bash
cd extracted_app/salati
rm -f android/local.properties          # يمنع مسار SDK قديم من إفساد البناء
python3 ../../ci/scripts/patch_android.py 2 .   # أو profile 1/3 حسب إصدار أدواتك
flutter pub get
flutter build apk --release
# الناتج: build/app/outputs/flutter-apk/app-release.apk
```

للبناء النظيف بأحجام أصغر:

```bash
flutter build apk --release --split-per-abi
```

---

## ملاحظات عن الملف الناتج

| البند | القيمة |
|---|---|
| معرّف الحزمة | `com.salati.app` |
| الإصدار | `1.0.0` (build 1) |
| التوقيع | مفتاح **debug** — يصلح للتثبيت المباشر والتجربة، وليس للنشر على Google Play |
| الأذونات | الموقع، الإشعارات، المنبّهات الدقيقة، التشغيل عند الإقلاع، الإنترنت |

### للتوقيع الحقيقي (نشر المتجر)

```bash
keytool -genkey -v -keystore salati-release.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias salati
```

ثم أنشئ `android//key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=salati
storeFile=/absolute/path/salati-release.jks
```

واستبدل في `android/app/build.gradle`:

```groovy
signingConfig = signingConfigs.release
```

مع إضافة `signingConfigs { release { ... } }` تقرأ من `key.properties`.
