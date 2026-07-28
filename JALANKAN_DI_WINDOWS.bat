@echo off
title SNBT Study Tracker - Windows Simulation
echo.
echo  ████████████████████████████████████████
echo  █  SNBT STUDY TRACKER 2027             █
echo  █  made by ran ft envy                 █
echo  ████████████████████████████████████████
echo.
echo  Membuka simulasi di Chrome...
echo  (Tampilan identik dengan versi Android)
echo.

cd /d "%~dp0"

where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  [!] Flutter tidak ditemukan di PATH.
    echo      Install Flutter dari: https://docs.flutter.dev/get-started/install
    echo      Lalu tambahkan flutter\bin ke PATH.
    pause
    exit /b 1
)

echo  [*] Menjalankan flutter run -d chrome...
echo  [*] Tekan Ctrl+C di terminal ini untuk berhenti.
echo.

:: Flag --disable-web-security diperlukan untuk SQLite WASM di browser
flutter run -d chrome ^
  "--web-browser-flag=--enable-features=SharedArrayBuffer" ^
  "--web-browser-flag=--disable-web-security" 2>&1

pause
