@echo off
title SNBT Study Tracker 2027 — Simulasi Windows
chcp 65001 >nul
echo.
echo  ┌──────────────────────────────────────────┐
echo  │   SNBT STUDY TRACKER 2027                │
echo  │   Simulasi di Windows via Chrome WASM    │
echo  │                                          │
echo  │   made by ran ft envy                    │
echo  └──────────────────────────────────────────┘
echo.

cd /d "%~dp0"

where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  [!] Flutter tidak ditemukan di PATH.
    echo.
    echo  Install Flutter dari: https://docs.flutter.dev/get-started/install
    echo  Lalu tambahkan folder flutter\bin ke PATH Windows.
    echo.
    pause
    exit /b 1
)

echo  [*] Menggunakan Flutter versi:
flutter --version 2>&1 | findstr "Flutter"
echo.
echo  [*] Memulai simulasi di Chrome (WASM mode)...
echo  [*] Browser akan terbuka otomatis dalam beberapa detik.
echo  [*] Tekan Ctrl+C di jendela ini untuk berhenti.
echo.
echo  CATATAN: Flutter run -d windows butuh Visual Studio 2022 (VS2022).
echo  Mode Chrome WASM ini tidak membutuhkan VS2022.
echo.

flutter run -d chrome --wasm 2>&1

echo.
echo  Simulasi selesai.
pause
