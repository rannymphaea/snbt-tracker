# 📚 SNBT Study Tracker 2027

> Gamified habit tracker untuk persiapan SNBT — **100% offline**, Flutter native app.  
> *made by ran ft envy*

[![Flutter](https://img.shields.io/badge/Flutter-3.44-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-blue?logo=dart)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-APK-green?logo=android)](https://developer.android.com)
[![Offline](https://img.shields.io/badge/Offline-100%25-brightgreen)](.)

---

## ✨ Fitur

- 🌳 **Pohon Belajar** — maskot pohon tumbuh sesuai progres (6 tahap, CustomPainter)
- 🔥 **Streak Tracker** — hitung hari belajar berturut-turut
- 📊 **Grafik Tren 7 Hari** — visualisasi aktivitas belajar harian
- ✅ **3 Checkbox per Topik** — Pelajari / Latihan / Review + animasi partikel
- 📝 **Catatan per Topik** — simpan catatan dengan debounce 500ms
- ➕ **Topik Custom** — tambah target belajar sendiri
- 💾 **Export / Import JSON** — backup dan restore progres
- 🔔 **Reminder Harian** — notifikasi jam belajar (Android)
- 🎵 **Sound Effect** — SFX saat centang topik

---

## 🚀 Cara Jalankan (Simulasi Windows)

### Metode 1 — Double-click (paling mudah)
```
Klik dua kali: JALANKAN_DI_WINDOWS.bat
```
App akan terbuka otomatis di Chrome. Tampilan **identik** dengan Android.

### Metode 2 — Terminal
```powershell
cd "SNBT 2027\snbt_tracker"
flutter pub get
flutter run -d chrome
```

---

## 📱 Build APK (Android)

```powershell
BUILD_APK.bat
# APK: build\app\outputs\flutter-apk\app-release.apk
```

---

## 📁 Struktur

```
lib/
├── main.dart
├── data/       (SQLite repositories)
├── models/     (data classes)
├── providers/  (ChangeNotifier state)
├── screens/    (5 screens)
└── widgets/    (checkbox, ring, tree, cards)
```

---

## 👤 Credits

*made by ran ft envy* · Flutter 3.44 · SQLite · Provider
