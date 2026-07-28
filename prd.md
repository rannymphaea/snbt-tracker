Kamu bisa langsung menyalin (*copy-paste*) dokumen di bawah ini untuk keperluan pengerjaan proyekmu.
# Product Requirements Document (PRD)
**Nama Aplikasi:** SNBT Tracker
**Target Ujian:** UTBK SNBT 2027
## 1. Problem Statement
Persiapan UTBK SNBT menuntut konsistensi belajar jangka panjang. Hal ini seringkali sulit dipertahankan, terutama bagi peserta yang memiliki kesibukan lain seperti mahasiswa *semi-gap year*. Calon peserta sering kesulitan melacak riwayat materi yang sudah dipelajari, kehilangan motivasi karena progres belajar tidak terlihat secara fisik, dan kerap melupakan jadwal belajar atau *tryout* karena padatnya aktivitas sehari-hari.
## 2. Goals
 * **Konsistensi:** Membangun dan menjaga konsistensi belajar pengguna agar mendapatkan hasil maksimal pada kesempatan UTBK 2027.
 * **Motivasi & Gamifikasi:** Membuat proses pembelajaran terasa lebih nyata, terlihat, dan memuaskan (*rewarding*) melalui pendekatan gamifikasi untuk meningkatkan motivasi.
 * **Asisten Pribadi:** Menjadi asisten pengingat yang andal agar pengguna tetap disiplin menjalankan jadwal belajar dan *tryout* di tengah kesibukan (khususnya jadwal kuliah bagi *semi-gap year*).
## 3. Target User
Pelajar ambisius yang menargetkan masuk Perguruan Tinggi Negeri (PTN) pada tahun 2027, meliputi:
 * Siswa SMA/SMK/MA Kelas 12.
 * Alumni *Gap Year* (fokus penuh belajar mandiri).
 * Mahasiswa *Semi-Gap Year* (mempersiapkan UTBK sembari menjalani perkuliahan).
## 4. User Stories
 * **Sebagai mahasiswa *semi-gap year***, saya ingin mendapatkan pengingat belajar dan *tryout* berkala agar saya tetap konsisten di tengah kesibukan kuliah.
 * **Sebagai pengguna**, saya ingin melihat visualisasi progres saya berupa pohon yang tumbuh bertahap setiap kali saya menyelesaikan target belajar, sehingga saya merasa pencapaian saya nyata dan terus termotivasi.
 * **Sebagai pengguna**, saya ingin mendapatkan apresiasi/pujian otomatis dari aplikasi setelah menginput progres belajar atau nilai *tryout* agar saya merasa dihargai.
 * **Sebagai pengguna**, saya ingin mencatat skor *tryout* dan melacak materi yang sudah dipelajari (termasuk menambah materi *custom*), agar saya tahu persis statistik dan perkembangan rasionalisasi skor saya.
 * **Sebagai pengguna**, saya ingin data riwayat belajar saya tersimpan dan tersinkronisasi secara otomatis ke sistem *cloud*, sehingga data tidak hilang dan langsung kembali saat saya *login* ulang meski aplikasi sempat terhapus atau saya berganti HP.
## 5. Functional Requirements
 * **Gamifikasi Visual (Maskot Pohon Native):** Sistem menampilkan maskot pohon yang berevolusi (tumbuh akar, ranting, dan daun) secara bertahap seiring dengan poin/konsistensi *input* pengguna. Animasi dan grafis dibangun murni menggunakan sistem bawaan (misal: *CustomPainter* atau *Implicit Animations* Flutter), tanpa mengandalkan file eksternal dari pihak ketiga.
 * **Sistem Apresiasi (Praise System):** Aplikasi menampilkan *pop-up* atau teks apresiasi/motivasi secara otomatis setelah pengguna berhasil mencatat aktivitas belajar atau hasil *tryout*.
 * **Pelacakan Materi & Statistik:**
   * Menampilkan *checklist* daftar materi bawaan dan riwayat materi yang sudah diselesaikan.
   * Memungkinkan fitur Input (CRUD) bagi pengguna untuk menambahkan materi *custom* yang tidak ada di pangkalan data (*database*).
   * Menampilkan visualisasi (grafik garis/batang) untuk statistik perkembangan skor *tryout*.
 * **Sistem Pengingat (Reminders):** Menggunakan fitur *push notification* lokal untuk pengingat jadwal belajar (harian) dan jadwal *tryout* (mingguan).
 * **Manajemen Akun:** Sistem registrasi dan *login* yang sederhana menggunakan Nama, Email, dan Password.
 * **Manajemen Data (Automated Cloud Sync):** Data aplikasi langsung disinkronisasi dengan *database cloud*. Saat pengguna *login*, data secara otomatis ditarik dari *cloud* ke perangkat lokal.
## 6. Non-Functional Requirements
 * **Platform & Framework:** Aplikasi *Mobile* (Android) dikembangkan menggunakan *framework* **Flutter**.
 * **Backend & Database:** Menggunakan ekosistem **Firebase**:
   * *Firebase Authentication* untuk sistem *login/register*.
   * *Cloud Firestore* untuk menyimpan seluruh data progres belajar, skor, dan status pohon pengguna secara *online* dan *real-time*.
 * **Local Notification:** Menggunakan *package* **flutter_local_notifications** agar alarm pengingat tetap berjalan di latar belakang (*background*) walau aplikasi sedang ditutup.
 * **Animasi Internal:** Animasi maskot dibuat menggunakan kode *native* Flutter secara mandiri (misal: AnimatedBuilder, Tween, atau CustomPaint) untuk menjaga ukuran aplikasi tetap kecil dan mengurangi ketergantungan pada *package* eksternal.
 * **Offline Support (via Firestore Cache):** Firestore harus dikonfigurasi untuk memungkinkan akses data dan penambahan data saat *offline* (tidak ada internet), yang nantinya akan otomatis sinkron ke *cloud* saat internet kembali terhubung.
## 7. Scope
 * **In-Scope:** Pembuatan aplikasi pelacak pribadi (*self-tracking*) khusus untuk peserta UTBK 2027. Fitur mencakup sistem akun (*login/register*), sinkronisasi awan otomatis, gamifikasi pohon dengan animasi bawaan Flutter, pelacakan skor/materi, sistem apresiasi, dan pengingat lokal.
 * **Out-of-Scope:** Ekspor/Impor data secara manual, integrasi dengan penyelenggara *tryout* pihak ketiga, forum diskusi antar pengguna, dan animasi kompleks berbasis file eksternal (seperti Lottie/Rive).