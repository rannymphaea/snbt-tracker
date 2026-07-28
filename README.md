# 📚 SNBT Study Tracker 2027

**Gamified habit tracker untuk persiapan SNBT** — Flutter native offline app (Android + Windows preview).

> *made by ran ft envy*

---

## ✨ Fitur

- 🌳 **Pohon Belajar** — karakter pohon 6 tahap yang tumbuh sesuai progres kamu (CustomPainter)
- ✅ **Checkbox Animasi** — partikel burst + suara saat kamu mencentang topik
- 📊 **Dashboard** — ring progres total, 6 ring per subtes, grafik tren 7 hari, streak counter
- 📖 **6 Subtes SNBT** — semua materi tersedia lengkap (dari `materi-snbt.json`)
- 🗒️ **Catatan per Topik** — tulis catatan belajarmu langsung di app
- ➕ **Tambah Topik Custom** — tambah topik sendiri per bab
- ⚙️ **Pengaturan** — reminder harian, SFX on/off, export/import data JSON, reset progres
- 🔒 **100% Offline** — tidak ada server, semua data di SQLite lokal

---

## 🚀 Cara Install & Pakai

### Prasyarat (sekali di awal)

1. **Flutter SDK** — [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) (pilih Windows), extract ke `C:\src\flutter`, tambah `flutter\bin` ke PATH
2. **Aktifkan Windows desktop**: `flutter config --enable-windows-desktop`
3. **Visual Studio 2022** (Community, gratis) — [visualstudio.microsoft.com/downloads](https://visualstudio.microsoft.com/downloads/) — centang workload **"Desktop development with C++"**
   > ⚠️ Pakai VS2022, bukan VS2026 — ada bug kompatibilitas toolchain Flutter dengan VS2026 per mid-2026
4. **Android Studio + Android SDK** — [developer.android.com/studio](https://developer.android.com/studio) (untuk build APK)
5. Verifikasi: `flutter doctor -v` → pastikan Visual Studio dan Android toolchain ✅ hijau

### Clone & Setup

```bash
git clone https://github.com/rannymphaea/snbt-tracker-flutter.git
cd snbt-tracker-flutter
flutter pub get
```

### Simulasi di Windows (sehari-hari)

```bash
# Double-click file ini:
JALANKAN_DI_WINDOWS.bat

# Atau manual:
flutter run -d chrome --wasm
```

> Windows native (`flutter run -d windows`) butuh VS2022 terinstall. Untuk preview cepat, gunakan Chrome WASM mode di atas.

### Build APK (untuk Android)

```bash
# Double-click:
BUILD_APK.bat

# Atau manual:
flutter build apk --release --target-platform android-arm64
# Output: build\app\outputs\flutter-apk\app-release.apk
```

Copy `app-release.apk` ke HP → install langsung (aktifkan "Install dari sumber tidak dikenal").

---

## 🏗️ Struktur Proyek

```
snbt_tracker/
├── assets/
│   ├── materi-snbt.json       # Data materi SNBT (statis, tidak diedit app)
│   ├── fonts/                 # Nunito.ttf (local, offline)
│   └── sfx/check.wav          # Suara centang
├── lib/
│   ├── data/
│   │   ├── database_helper.dart  # Platform-aware SQLite init
│   │   └── repository.dart       # SubtestRepo, TopicRepo, ProgressRepo, dll
│   ├── models/models.dart         # Data classes
│   ├── providers/
│   │   └── progress_provider.dart # ProgressProvider + SettingsProvider
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── subtes_list_screen.dart
│   │   ├── subtes_screen.dart
│   │   ├── tambah_screen.dart
│   │   └── pengaturan_screen.dart
│   ├── utils/app_theme.dart       # Design tokens, ThemeData
│   ├── widgets/
│   │   ├── animated_checkbox.dart # Custom checkbox + partikel + SFX
│   │   ├── app_card.dart          # AppCard, PrimaryButton, TapScale
│   │   ├── ring_progress.dart     # Animated ring progress
│   │   └── tree_painter.dart      # Pohon belajar CustomPainter
│   └── main.dart                  # Entry point + custom cursor (Windows)
├── JALANKAN_DI_WINDOWS.bat        # Launcher Windows/Chrome
└── BUILD_APK.bat                  # APK builder
```

---

## 🧰 Stack Teknologi

| Layer | Package |
|-------|---------|
| State | `provider` (ChangeNotifier) |
| Database | `sqflite` (Android) + `sqflite_common_ffi` (Windows) |
| Charts | `fl_chart` |
| Audio | `audioplayers` |
| Notifikasi | `flutter_local_notifications` + `timezone` |
| File I/O | `file_picker` |
| Font | Nunito (lokal, `.ttf` di assets) |

---

## 🎨 Design System

- **Palet**: Kuning `#F5B942` · Coral `#FF6B4A` · Biru `#2E6FF2` · Hijau `#3BA55C` · Krem `#FDF8F0`
- **Gaya**: Neobrutalism — flat color, shadow solid tipis, rounded card
- **Dilarang**: glow neon, gradient ungu-biru generik, blur berlebihan
- **Font**: Nunito (bundel lokal, bukan fetch online)

---

## 📋 Batasan (Non-Goal)

- Tidak ada autentikasi atau akun
- Tidak ada sync multi-device / backend
- iOS: kode sudah platform-agnostic, tapi belum dikerjakan build-nya (butuh Xcode di macOS)
- Windows native preview butuh VS2022 — gunakan Chrome WASM mode sebagai alternatif

---

## 📱 Untuk iPhone (nanti)

Kode sudah ditulis platform-agnostic. Saat siap tambah iOS:
1. Butuh Mac dengan Xcode (aturan Apple, bukan Flutter)
2. Atau pakai cloud build seperti [Codemagic](https://codemagic.io) untuk compile `.ipa`
3. Tidak perlu ubah kode Dart — langsung lanjut dari tahap build

---

*made by ran ft envy · SNBT 2027*
