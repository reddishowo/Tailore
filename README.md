# Tailore

Tailore adalah aplikasi Flutter untuk manajemen jadwal order jahitan/butik berbasis kalender tahunan.
Fokus utamanya adalah membantu owner tailor/butik mengatur deadline pesanan, kapasitas harian, status pembayaran, dan pengingat otomatis sebelum tenggat.

## Apa Itu Project Ini?

Project ini merupakan **aplikasi produktivitas untuk operasional tailor/butik** dengan konsep:

- Kalender 12 bulan untuk memantau beban order per tanggal.
- Input order per hari (nama klien, jenis baju, harga, DP, add-on, tanggal masuk).
- Monitoring piutang/lunas secara ringkas.
- Notifikasi reminder deadline otomatis (H-3, H-2, H-1).
- Rekap statistik bulanan dan tahunan.

Target use case: penjahit, butik rumahan, atau tim kecil produksi custom outfit yang ingin workflow sederhana tapi rapi.

## Tech Stack

### Core
- **Flutter** (SDK `^3.10.1`)
- **Dart**
- **Material 3 UI**

### State Management & Routing
- **GetX** (`get`)

### Local Data & Utility
- **shared_preferences** → penyimpanan data jadwal secara lokal (offline)
- **flutter_local_notifications** → scheduling notifikasi lokal
- **timezone** → pengaturan zona waktu notifikasi (default `Asia/Jakarta`)
- **intl** → format tanggal/lokalisasi (`id_ID`)

### Dev Tooling
- **flutter_lints**
- **flutter_launcher_icons**

## Fitur Utama

### 1) Kalender Produksi Tahunan
- Menampilkan 12 bulan sekaligus dalam satu layar.
- Navigasi tahun sebelumnya/berikutnya.
- Setiap tanggal menunjukkan tingkat kepadatan order via warna.

### 2) Manajemen Order Harian (CRUD)
- Tambah, edit, hapus order per tanggal.
- Data order mencakup:
	- Nama klien
	- Jenis baju
	- Harga total
	- Nominal DP/terbayar
	- Add-on/catatan tambahan
	- Tanggal masuk order
	- Deadline

### 3) Kontrol Kapasitas Harian
- Setiap hari memiliki kapasitas maksimum order.
- Validasi otomatis saat kapasitas penuh.
- Indikator slot tersisa ditampilkan di bottom sheet detail harian.

### 4) Tracking Pembayaran
- Status **lunas** vs **belum lunas** otomatis.
- Perhitungan total pendapatan, uang diterima, dan sisa piutang.
- Badge status pembayaran pada kartu order.

### 5) Laporan Bulanan & Tahunan
- Ringkasan jumlah order.
- Ringkasan nilai proyek, uang masuk, piutang.
- Progress pembayaran ditampilkan secara visual.

### 6) Reminder Deadline Otomatis
- Notifikasi dijadwalkan otomatis saat order dibuat/diubah.
- Reminder pada H-3, H-2, H-1 pukul 08:00 (zona lokal).
- Notifikasi lama dibatalkan saat order dihapus/di-reschedule.

### 7) Penyimpanan Lokal (Offline-First)
- Seluruh jadwal disimpan dalam `SharedPreferences` (JSON serialized).
- Data tetap ada saat aplikasi ditutup/dibuka kembali.

## Arsitektur Singkat

Project menggunakan pola modular sederhana berbasis GetX:

- `data/models` → model domain (`OrderModel`, `DailySchedule`, `ScheduleStats`)
- `modules/home/controllers` → business logic, persistence, CRUD, stats
- `modules/home/views` → UI screen + bottom sheets + dialog form
- `services` → layanan notifikasi lokal
- `routes` → routing page

## Struktur Folder Inti

```text
lib/
	main.dart
	app/
		data/
			models/
				order_model.dart
		modules/
			home/
				bindings/
				controllers/
				views/
		routes/
			app_pages.dart
			app_routes.dart
		services/
			notification_service.dart
```

## Cara Menjalankan Project

### Prasyarat
- Flutter SDK terpasang
- Device Android/iOS atau emulator aktif

### Langkah
```bash
flutter pub get
flutter run
```

## Build APK (Opsional)

```bash
flutter build apk --release
```

## Konfigurasi Notifikasi

- Service notifikasi diinisialisasi saat app start (`main.dart`).
- Zona waktu default: `Asia/Jakarta`.
- Android 13+ meminta permission notifikasi & exact alarm.

Jika ingin ubah zona waktu, edit konfigurasi di `NotificationService`.

## Catatan Implementasi Saat Ini

- Routing saat notifikasi di-tap sudah disiapkan payload-nya, namun navigasi detail order masih TODO.
- Terdapat data dummy awal bila local storage masih kosong.
- Aplikasi dikunci ke mode portrait untuk konsistensi tampilan kalender.

## Roadmap Pengembangan (Saran)

- Pencarian & filter order.
- Ekspor laporan (PDF/Excel).
- Sinkronisasi cloud (Firebase/Supabase).
- Multi-user / role-based access.
- Halaman detail order terpisah.
