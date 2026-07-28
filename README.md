# SNBT Study Tracker

Gamified study tracker untuk persiapan SNBT 2027 — native Android, offline, no ads.

*app by ran ft envy*

---

## Install

### Android
> Butuh Android 5.0+

1. [**Download APK →**](https://github.com/rannymphaea/snbt-tracker/releases/latest) ← klik, download, buka, install
2. Jika muncul popup *"sumber tidak dikenal"* → Settings → izinkan → install lagi

Done. App langsung bisa dipakai tanpa internet.

---

### Windows (preview)
Butuh [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/desktop) terinstal.

```powershell
cd "path\ke\snbt_tracker"
flutter pub get
flutter run -d chrome --wasm
```

Atau double-click **`JALANKAN_DI_WINDOWS.bat`**

---

## Fitur

| | |
|---|---|
| 🌳 Pohon belajar | Tumbuh sesuai progres (6 tahap) |
| ✅ Checkbox animasi | Partikel + suara saat dicentang |
| 📊 Dashboard | Ring progres, grafik 7 hari, streak |
| 📖 6 Subtes SNBT | Materi lengkap offline |
| 🗒️ Catatan | Tulis catatan per topik |
| ➕ Topik custom | Tambah materi sendiri |
| ⚙️ Setelan | Reminder, SFX, export/import data |

---

## Build APK sendiri

```powershell
# Harus di dalam folder snbt_tracker
flutter pub get
flutter build apk --release --target-platform android-arm64
# Output: build\app\outputs\flutter-apk\app-release.apk
```

Atau double-click **`BUILD_APK.bat`**

---

## Tech

Flutter · SQLite · Provider · Offline-first · No backend · No auth

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| App tidak mau diinstall | Aktifkan "Install sumber tidak dikenal" di Settings |
| `No pubspec.yaml` error | Kamu di folder yang salah — harus masuk ke `snbt_tracker/` |
| `flutter` tidak dikenal | Tambah `flutter\bin` ke PATH |
| Build gagal | Jalankan `flutter doctor` dan ikuti instruksinya |
