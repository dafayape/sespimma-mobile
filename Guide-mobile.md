# PANDUAN PENGGUNAAN APLIKASI MOBILE - SESPIMMA

> [!IMPORTANT]
> **PERINGATAN SEBELUM INSTALASI (JIKA STUCK LOADING / LOGO)**
> Jika aplikasi mengalami hang (stuck) pada layar logo SESPIMMA setelah instalasi build APK baru, ikuti langkah berikut untuk mereset cache Keystore:
> 1. Masuk ke **Pengaturan HP** -> **Aplikasi** -> **Kelola Aplikasi** -> Pilih **SESPIMMA**.
> 2. Pilih **Penyimpanan** (Storage) -> Tekan **Hapus Data** (Clear Data) & **Hapus Cache** (Clear Cache).
> 3. Buka kembali aplikasi. Aplikasi akan memuat halaman login dengan lancar.

---

Aplikasi mobile SESPIMMA memiliki 5 peran (Role) utama yang memiliki akses dan fitur berbeda untuk mendukung proses evaluasi, presensi, dan penilaian peserta didik.

---

## 1. Role: Serdik (Peserta Didik / Siswa)
Serdik adalah objek utama penilaian. Peran ini berfokus pada pemantauan nilai pribadi, kehadiran, dan aktivitas harian.

* **Akun Uji Coba**:
  * **NRP (Username)**: `77110075`
  * **Password**: `Password123!`
  * **Nama Lengkap**: ABD AZIS, S.Sos. (POKJAR 1)


### Fitur & Menu Utama:
* **Dashboard Utama (Beranda)**:
  * **Akumulasi Penilaian**: Memantau grafik nilai akhir untuk 3 pilar: Akademik, Mental Kepribadian, dan Jasmani secara realtime.
  * **Status Kehadiran**: Melihat jumlah rekap kehadiran pribadi (Hadir, Telat, Izin, Alpha).
  * **Poin Reward & Punishment**: Menampilkan total poin pujian (+) dan teguran (-) yang telah disetujui (Approved) oleh Korsis.
* **Scan Presensi (Kelas & Zona Aktif)**:
  * Menggunakan kamera HP untuk memindai QR Code presensi yang dibuat oleh Korsis/Operator.
  * Presensi hanya bisa dilakukan jika posisi GPS HP berada di dalam radius toleransi yang ditentukan dari titik lokasi presensi.
* **Pengajuan Izin Khusus**:
  * Mengajukan izin keluar/sakit lewat menu presensi jika berhalangan hadir.
  * Wajib mengisi durasi izin (Waktu Mulai & Selesai), deskripsi alasan, serta mengunggah file bukti (foto surat dokter/dinas dalam format gambar atau PDF).
* **Pengisian Sosiometri**:
  * Mengisi kuisioner penilaian rekan sejawat (satu peleton/pokjar) ketika periode sosiometri aktif dibuka oleh sistem.
* **Riwayat Aktivitas**:
  * Memantau log aktivitas pribadi: tugas dikirim, tugas dinilai, status remedial, riwayat reward yang diterima, dan pelanggaran yang tercatat.

---

## 2. Role: Patun (Perwira Penuntun)
Patun bertanggung jawab langsung atas pembinaan mental kepribadian Serdik di Pokjar (Kelompok Belajar) asuhannya.

* **Akun Uji Coba**:
  * **NRP (Username)**: `69100449`
  * **Password**: `password123`
  * **Nama Lengkap**: Drs. Sabri Manullang, M.Pd. (POKJAR 1)


### Fitur & Menu Utama:
* **Daftar Serdik Asuhan**:
  * Menampilkan daftar Serdik terbatas hanya pada kelompok kelas (Pokjar) yang diasuhnya.
* **Penilaian Nilai Mental (Angka)**:
  * Memasukkan nilai rutin (skala 0-100) untuk 5 aspek mental utama Serdik asuhannya: Moral, Disiplin, Kepemimpinan, Pengendalian Diri, dan Penampilan.
* **Pengajuan Reward & Punishment**:
  * Memberikan penghargaan (pujian) atau hukuman (teguran) kepada Serdik asuhannya.
  * Patun memilih jenis reward/punishment dari daftar acuan, mengunggah bukti foto kejadian, dan mengisi catatan detail.
  * **Catatan**: Input dari Patun tidak langsung memotong/menambah nilai akhir Serdik, melainkan dikirim sebagai draf pengajuan ke Inbox Korsis terlebih dahulu.
* **Monitoring Jasmani**:
  * Melihat nilai Jasmani (Samapta A & B) Serdik asuhannya secara read-only untuk bahan evaluasi pembinaan.

---

## 3. Role: Gadik (Tenaga Pendidik / Dosen)
Gadik bertanggung jawab atas pilar penilaian Akademik melalui pengajaran dan tugas kelas.

* **Akun Uji Coba**:
  * **NRP (Username)**: `71080519`
  * **Password**: `password123`
  * **Nama Lengkap**: Tommy Bambang Irawan, S.I.K., M.H.


### Fitur & Menu Utama:
* **Daftar Penilaian Pokjar**:
  * Memilih kelas (Pokjar) untuk melihat performa akademik Serdik pada mata kuliah yang diampu.
* **Input Nilai Akademik**:
  * Menginput nilai angka (0-100) untuk komponen akademik Serdik: Ujian Tengah Semester (UTS), Ujian Akhir (UAS), Tugas Mandiri, dan Partisipasi Kelas.
* **Manajemen Tugas**:
  * Memantau status pengumpulan tugas (apakah sudah dikumpul, belum mulai, atau perlu remedial) dan langsung memberikan penilaian numerik di aplikasi.

---

## 4. Role: Korsis (Koordinator Siswa)
Korsis adalah validator utama alur penilaian harian dan pengelola presensi di lapangan.

* **Akun Uji Coba**:
  * **NRP (Username)**: `70012128`
  * **Password**: `password123`
  * **Nama Lengkap**: Suprayitno, S.H., S.I.K.


### Fitur & Menu Utama:
* **Inbox Approval (Persetujuan)**:
  * Menyetujui atau menolak draf pengajuan izin khusus dari Serdik. Jika disetujui, absensi Serdik pada kegiatan tersebut otomatis berubah menjadi "Izin" atau "Sakit" di sistem.
  * Menyetujui atau menolak pengajuan Reward & Punishment yang diajukan oleh Patun. Setelah disetujui, poin reward/punishment langsung terakumulasi ke nilai mental akhir Serdik secara otomatis.
* **Pembuatan Zona Presensi (QR Code)**:
  * Membuat sesi presensi baru untuk kegiatan (misal: Apel Pagi, Kuliah Kelas, Olahraga Pagi).
  * Mengatur titik koordinat GPS lokasi, batas radius toleransi presensi (meter), waktu mulai, serta waktu cutoff (toleransi keterlambatan).
  * Menghasilkan QR Code presensi untuk ditampilkan di layar/dicetak.
* **Dashboard Rekap & Ranking**:
  * Memantau statistik kehadiran Serdik hari ini secara global.
  * Memantau daftar peringkat (ranking) Serdik lintas Pokjar secara realtime berdasarkan akumulasi seluruh nilai.

---

## 5. Role: Operator
Operator memiliki hak akses luas lintas pokjar untuk melakukan input data teknis penunjang di lapangan.

* **Akun Uji Coba**:
  * **Username (Email)**: `admin@sespima.com` (atau NRP: `99999999`)
  * **Password**: `Superadmin123!`
  * **Nama Lengkap**: Super Admin Utama


### Fitur & Menu Utama:
* **Input Data Samapta (Jasmani)**:
  * Menginput hasil tes fisik Serdik: Samapta A (Lari 12 menit) dan Samapta B (Pull Up, Sit Up, Push Up, Shuttle Run). Sistem akan menghitung otomatis skor konversinya ke skala 0-100.
* **Input Data Kesehatan**:
  * Menginput hasil Tes Kesehatan Awal (Score A), Tes Kesehatan Akhir (Score B), serta rekam medis kunjungan klinik Serdik di TPS/RS.
* **Manajemen Kehadiran & Sosiometri**:
  * Membantu pembuatan zona presensi dan menginput nilai sosiometri manual jika ada kendala sistem di mobile Serdik.
* **Data Master Lintas Pokjar**:
  * Dapat mencari dan mengakses profil/nilai seluruh Serdik lintas Pokjar tanpa batasan kelas asuhan.
