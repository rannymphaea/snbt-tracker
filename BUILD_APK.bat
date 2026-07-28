@echo off
title Build APK - SNBT Study Tracker
echo.
echo  [BUILD APK] SNBT Study Tracker
echo  Proses ini memerlukan Android Studio + SDK
echo.

cd /d "%~dp0"

echo  [1/3] flutter pub get...
flutter pub get
if %ERRORLEVEL% NEQ 0 goto :err

echo.
echo  [2/3] flutter build apk --release...
flutter build apk --release --target-platform android-arm64
if %ERRORLEVEL% NEQ 0 goto :err

echo.
echo  [3/3] APK siap!
echo.
echo  Lokasi: build\app\outputs\flutter-apk\app-release.apk
echo.
explorer build\app\outputs\flutter-apk\
goto :end

:err
echo.
echo  [ERROR] Build gagal. Cek output di atas.
pause
exit /b 1

:end
pause
