@echo off
chcp 65001 > nul
echo ========================================================
echo 🕌 بدء عملية بناء ملف APK لتطبيق صلاتي (Salati Flutter)
echo ========================================================

echo 1. فحص بيئة العمل...
call flutter doctor

echo 2. تنزيل الحزم والمكتبات...
call flutter pub get

echo 3. بناء ملف Release APK...
call flutter build apk --release

echo.
echo ========================================================
echo ✅ تم بناء تطبيق صلاتي APK بنجاح!
echo 📂 مسار الملف المنشأ:
echo build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
