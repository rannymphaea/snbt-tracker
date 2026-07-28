@echo off
title Build APK - SNBT Study Tracker 2027
chcp 65001 >nul
echo.
echo  ┌──────────────────────────────────────────┐
echo  │   BUILD APK — SNBT Study Tracker 2027    │
echo  │   made by ran ft envy                    │
echo  └──────────────────────────────────────────┘
echo.

cd /d "%~dp0"

where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  [!] Flutter tidak ditemukan di PATH.
    pause
    exit /b 1
)

echo  [*] Membutuhkan: Android Studio + Android SDK
echo  [*] Cek flutter doctor jika ada masalah.
echo.
echo  [*] Memulai build APK release (arm64)...
echo  [*] Proses ini bisa memakan waktu 5-15 menit.
echo.

flutter build apk --release --target-platform android-arm64

if %ERRORLEVEL% EQU 0 (
    echo.
    echo  ══════════════════════════════════════════
    echo  ✅ APK BERHASIL DIBUAT!
    echo.
    echo  Lokasi file:
    echo  build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo  Cara install ke HP Android:
    echo  1. Copy file .apk ke HP (via USB/WhatsApp/dll)
    echo  2. Buka file di HP
    echo  3. Aktifkan "Install dari sumber tidak dikenal" jika diminta
    echo  ══════════════════════════════════════════
    start "" "build\app\outputs\flutter-apk\"
) else (
    echo.
    echo  [!] Build GAGAL. Jalankan: flutter doctor -v
)

pause
