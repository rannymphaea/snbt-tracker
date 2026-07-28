# 📚 SNBT Study Tracker 2027

**Gamified habit tracker untuk persiapan SNBT** — Flutter native offline app.

> *made by ran ft envy* · APK release: `app-release.apk` (19.4 MB) ✅

---

## 📋 Daftar Isi

- [Cara Jalankan di Windows (Simulasi)](#-cara-jalankan-di-windows-simulasi)
- [Cara Install di Android](#-cara-install-di-android)
- [Build APK Sendiri](#-build-apk-sendiri)
- [Fitur App](#-fitur-app)
- [Stack Teknologi](#-stack-teknologi)
- [Struktur Proyek](#-struktur-proyek)

---

## 🖥️ Cara Jalankan di Windows (Simulasi)

> Tampilan di Windows 100% identik dengan Android karena Flutter pakai render engine yang sama.

### Prasyarat

1. **Install Flutter SDK**
   - Download dari [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) → pilih **Windows**
   - Extract ke folder **tanpa spasi**, misalnya `C:\src\flutter`
   - Tambahkan `C:\src\flutter\bin` ke **PATH** Windows:
     - Buka *Start* → cari "Environment Variables"
     - Edit `Path` di User variables → klik New → isi `C:\src\flutter\bin`
     - OK → restart terminal

2. **Verifikasi Flutter**
   ```powershell
   flutter --version
   # Harus muncul: Flutter 3.x.x stable
   ```

3. **Install Chrome** (jika belum ada) — [google.com/chrome](https://www.google.com/chrome/)

### Langkah Jalankan

```powershell
# 1. Buka terminal di folder snbt_tracker
cd "C:\Users\lenovo\OneDrive\Documents\SNBT 2027\snbt_tracker"

# 2. Install dependencies (sekali saja)
flutter pub get

# 3. Jalankan di Chrome
flutter run -d chrome --wasm
```

**Atau cukup double-click file:**
```
📁 snbt_tracker\
   └── 🖱️ JALANKAN_DI_WINDOWS.bat  ← double click ini
```

> **Catatan**: `flutter run -d windows` (native Windows window) membutuhkan **Visual Studio 2022** dengan workload "Desktop development with C++". Jika VS2022 belum terinstall, gunakan mode Chrome di atas — hasilnya sama persis.

### Kontrol saat app berjalan (di terminal)

| Tombol | Fungsi |
|--------|--------|
| `r` | Hot reload (perbarui tanpa restart) |
| `R` | Hot restart (restart penuh) |
| `q` | Quit / berhenti |

---

## 📱 Cara Install di Android

### Opsi A — Download APK (Paling Mudah)

> Jika sudah ada file `app-release.apk` dari proses build:

1. **Copy APK ke HP** — via USB, WhatsApp ke diri sendiri, Google Drive, dll
2. **Buka file APK di HP**
3. Jika muncul peringatan *"Install dari sumber tidak dikenal"*:
   - Android 8+: Settings → Apps → Special app access → Install unknown apps → pilih app pembuka file → Allow
   - Android 7: Settings → Security → Unknown sources → aktifkan
4. Tap **Install** → **Open**

> ✅ App berjalan **100% offline** — tidak butuh internet setelah install

### Opsi B — Pakai USB + ADB

```powershell
# Pastikan Developer Options + USB Debugging aktif di HP
# Hubungkan HP via USB

# Cek HP terdeteksi
flutter devices

# Install langsung ke HP
flutter install
# Atau:
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Opsi C — Flutter Run ke HP (Debug, butuh Android Studio)

```powershell
# HP terhubung via USB dengan USB Debugging aktif
flutter run -d <device-id>
# Ganti <device-id> dengan ID dari: flutter devices
```

---

## 🔨 Build APK Sendiri

### Prasyarat Tambahan

- **Android Studio** — [developer.android.com/studio](https://developer.android.com/studio)
- **Android SDK** (terinstall via Android Studio)

### Langkah Build

```powershell
# Pastikan berada di folder yang benar!
cd "C:\Users\lenovo\OneDrive\Documents\SNBT 2027\snbt_tracker"

# ⚠️ PENTING: jangan dari folder SNBT 2027 langsung, harus dari snbt_tracker

# Build APK release (arm64 — cocok untuk HP modern)
flutter build apk --release --target-platform android-arm64
```

**Atau double-click:**
```
📁 snbt_tracker\
   └── 🖱️ BUILD_APK.bat  ← double click ini
```

**Output APK ada di:**
```
snbt_tracker\build\app\outputs\flutter-apk\app-release.apk
```

### Cek Status Build

```powershell
# Lihat apakah APK sudah ada
Test-Path "build\app\outputs\flutter-apk\app-release.apk"
# True = berhasil

# Lihat ukuran APK
Get-Item "build\app\outputs\flutter-apk\app-release.apk" | Select Length
```

---

## 🛠️ Setup Lengkap untuk Development

```powershell
# 1. Clone repo
git clone https://github.com/rannymphaea/snbt-tracker-flutter.git
cd snbt-tracker-flutter

# 2. Install deps
flutter pub get

# 3. Cek semua tools OK
flutter doctor -v

# 4. Jalankan di Chrome (simulasi)
flutter run -d chrome --wasm

# 5. Build APK saat siap
flutter build apk --release --target-platform android-arm64
```

---

## ✨ Fitur App

| Fitur | Detail |
|-------|--------|
| 🌳 Pohon Belajar | 6 tahap tumbuh sesuai % progres (CustomPainter) |
| ✅ Checkbox Animasi | Partikel burst + suara centang |
| 📊 Dashboard | Ring progres, grafik 7 hari, streak counter |
| 📖 6 Subtes SNBT | Semua materi dari `materi-snbt.json` |
| 🗒️ Catatan Topik | Tulis catatan per topik belajar |
| ➕ Topik Custom | Tambah topik sendiri per bab |
| ⚙️ Pengaturan | Reminder, SFX, export/import, reset data |
| 🔒 100% Offline | SQLite lokal, tidak ada server |

---

## 🧰 Stack Teknologi

| Layer | Package |
|-------|---------|
| Framework | Flutter (stable) + Dart |
| State | `provider` (ChangeNotifier) |
| Database | `sqflite` + `sqflite_common_ffi` |
| Charts | `fl_chart` |
| Audio | `audioplayers` |
| Notifikasi | `flutter_local_notifications` |
| File I/O | `file_picker` |
| Font | Nunito (lokal `.ttf`, tidak fetch online) |

---

## 🏗️ Struktur Proyek

```
snbt_tracker/
├── 📄 JALANKAN_DI_WINDOWS.bat    ← jalankan simulasi Windows
├── 📄 BUILD_APK.bat               ← build APK Android
├── assets/
│   ├── materi-snbt.json           ← data materi (statis)
│   ├── fonts/Nunito-*.ttf         ← font lokal
│   └── sfx/check.wav              ← suara centang
├── lib/
│   ├── data/
│   │   ├── database_helper.dart   ← SQLite platform-aware init
│   │   └── repository.dart        ← SubtestRepo, ProgressRepo, dll
│   ├── models/models.dart
│   ├── providers/
│   │   └── progress_provider.dart ← state management
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── subtes_list_screen.dart
│   │   ├── subtes_screen.dart
│   │   ├── tambah_screen.dart
│   │   └── pengaturan_screen.dart
│   ├── utils/app_theme.dart       ← design tokens
│   ├── widgets/
│   │   ├── animated_checkbox.dart ← custom checkbox + partikel
│   │   ├── app_card.dart          ← AppCard, PrimaryButton, TapScale
│   │   ├── ring_progress.dart     ← animated ring
│   │   └── tree_painter.dart      ← pohon belajar CustomPainter
│   └── main.dart                  ← entry point + custom cursor Windows
└── android/app/build.gradle.kts  ← Android build config
```

---

## 🎨 Design System

- **Palet**: Kuning `#F5B942` · Coral `#FF6B4A` · Biru `#2E6FF2` · Hijau `#3BA55C` · Krem `#FDF8F0`
- **Gaya**: Neobrutalism — flat color, solid shadow, rounded card
- **Aturan**: NO glow neon, NO gradient ungu-biru, NO blur berlebihan
- **Font**: Nunito (bundel lokal — bukan fetch dari Google Fonts)

---

## ❓ Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `flutter: command not found` | Tambah `flutter\bin` ke PATH Windows |
| `No pubspec.yaml found` | Jalankan dari folder `snbt_tracker`, bukan `SNBT 2027` |
| `NDK not found` | Hapus folder NDK yang corrupt, jalankan build ulang |
| `flutter run -d windows` gagal | Install VS2022 + workload "Desktop development with C++" |
| APK tidak bisa diinstall di HP | Aktifkan "Install dari sumber tidak dikenal" di Settings HP |
| App error setelah install | Uninstall versi lama dulu, lalu install APK baru |

---

## 📝 Batasan

- Tidak ada autentikasi / akun
- Tidak ada sync multi-device
- **iOS**: kode siap (platform-agnostic), tapi build butuh Xcode di macOS

---

*made by ran ft envy · SNBT 2027*
