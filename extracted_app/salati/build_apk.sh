#!/usr/bin/env bash
# ========================================================
# سكربت بناء ملف APK لتطبيق صلاتي (Prayer Now Flutter Fixed)
# ========================================================
set -e

echo "🕌 بدء عملية بناء تطبيق صلاتي (Salati) لنظام أندرويد..."

echo "1️⃣ فحص بيئة فلاتر (Flutter Doctor)..."
flutter doctor

echo "2️⃣ تنزيل حزم الاعتماديات (Pub Get)..."
flutter pub get

echo "3️⃣ تنظيف مخلفات البناء السابقة..."
flutter clean
flutter pub get

echo "4️⃣ بناء ملف APK الإصدار الموحد (Universal Release APK)..."
flutter build apk --release

echo "5️⃣ بناء نسخ معمارية منفصلة لتوفير الحجم (Split per ABI: arm64, armeabi, x86_64)..."
flutter build apk --release --split-per-abi

echo ""
echo "✅ تم بناء ملفات الـ APK بنجاح! المسارات كالتالي:"
echo "📂 الملف الموحد: build/app/outputs/flutter-apk/app-release.apk"
echo "📂 المعماريات: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo ""
echo "للتثبيت المباشر على الهاتف عبر USB:"
echo "👉 flutter install"
