@echo off
title SNBT Study Tracker - Windows Launcher
echo.
echo  ████████████████████████████████████
echo  █  SNBT STUDY TRACKER 2027         █
echo  █  made by ran ft envy             █
echo  ████████████████████████████████████
echo.
echo  Membuka simulasi di Chrome...
echo  (Tampilan identik dengan versi Android)
echo.

cd /d "%~dp0"

where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  [!] Flutter tidak ditemukan di PATH.
    echo      Pastikan flutter\bin ada di PATH.
    echo      Cek: https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

echo  [*] Menjalankan flutter run -d chrome...
echo  [*] Tekan Ctrl+C untuk berhenti.
echo.

flutter run -d chrome --web-renderer html 2>&1

pause
