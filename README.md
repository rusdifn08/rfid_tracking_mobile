# Gistex Mobile — RFID Tracking (Scanner)

<p align="center">
  <strong>Aplikasi mobile operasional untuk tracking RFID bundle di proses cutting GCC</strong><br>
  Registrasi barcode, scanning stasiun produksi, dashboard real-time, dan checking riwayat RFID — terintegrasi dengan backend Gistex.
</p>

<p align="center">
  <img src="lib/assets/icon.png" alt="Gistex Mobile" width="96" />
</p>

| | |
|---|---|
| **Nama produk** | Gistex Mobile |
| **Versi** | 1.0.1+2 |
| **Package** | `scanner` |
| **Repository** | [rfid_tracking_mobile](https://github.com/rusdifn08/rfid_tracking_mobile) |

---

## Mengapa Gistex Mobile?

Aplikasi ini dirancang untuk **operator di lantai produksi** yang membutuhkan kecepatan scan, feedback langsung, dan visibilitas data tanpa membuka sistem desktop.

| Kelebihan | Penjelasan |
|-----------|------------|
| **Satu aplikasi, banyak stasiun** | Bundle, Quality Control, Supermarket, dan Supply Sewing dalam satu shell navigasi yang konsisten. |
| **Siap hardware scanner** | Input RFID mendukung **barcode wedge** (ketik + Enter) dan **kamera** (`mobile_scanner`) untuk barcode registrasi. |
| **Dashboard live dari API** | Ringkasan, grafik per jam, pie chart kualitas, dan tabel histori — data langsung dari server, bukan mock statis. |
| **UX modern & responsif** | Tipografi Poppins, animasi halus, layout adaptif untuk layar kecil handheld, dan dialog scanning yang informatif. |
| **Keamanan sesi operator** | Login NIK + password (MD5), penyimpanan sesi aman via `flutter_secure_storage` / `shared_preferences`. |
| **Arsitektur terpisah & testable** | Layer `data` → `state` (Provider) → `presentation`; unit test untuk kontrak API. |
| **Multi-platform** | Build untuk **Android** (APK), **Windows** desktop, dan dukungan iOS dalam struktur proyek Flutter. |
| **Integrasi API terstandar** | Header `rfid-key`, parsing response fleksibel (`success: true` atau `code: 200` + `status: success`). |

---

## Fitur Utama

### Autentikasi & Profil
- Splash screen dan gate login otomatis.
- Login operator berdasarkan **NIK** dan password (validasi ke API + hash MD5).
- Registrasi akun operator baru.
- Halaman profil operator (nama, NIK).
- Sesi tersimpan — tidak perlu login ulang setiap buka app.

### Home — Registrasi & Quick Tracking
- **Scan barcode** via kamera atau input manual untuk lookup data cutting.
- **Registrasi bundling** RFID + barcode ke sistem (`POST /api/gcc/cutting/reg`).
- **Quick grid** menu tracking: Bundle, Quality Control, Supermarket, Supply Sewing.
- Mode **Coming Soon** configurable untuk fitur yang belum rilis (`lib/config/coming.dart`).

### Stasiun Bundle
- Dashboard output bundle.
- Scan RFID untuk pencatatan output cutting (`POST /api/gcc/cutting/output`).

### Stasiun Quality Control
- Dashboard QC real-time: summary Good / Repair / Reject, grafik per jam, pie chart, tabel WO.
- **SCAN QC** — ambil qty output → split Good / Repair / Reject → submit (`POST /api/gcc/cutting/qc`).
- **SCAN Repair** — ambil qty repair → **Send To Good** / **Send To Reject**.
- Auto-refresh dashboard setelah setiap scan sukses.

### Stasiun Supermarket
- Dashboard: jumlah bundle, check-in, check-out, supply urgent.
- Grafik multi-series per jam (check-in, check-out, supply urgent).
- Tabel item dengan status lokasi (`IN_SMARKET`, `OUT_SMARKET`, `SUPPLY URGENT`).
- Scanning dialog: **Check In**, **Check Out**, **Supply Urgent** + konfigurasi location/line saat diperlukan.

### Checking RFID (Bottom Nav)
- Ganti riwayat scan lokal dengan **Checking RFID** terpusat.
- `GET /api/gcc/cutting/check` — timeline status bundle di seluruh proses.
- Filter status, pencarian, statistik Found/Not Found, dialog timeline detail.
- Ekspor ringkasan ke clipboard.

### Input Manual & Pengaturan
- Halaman input barcode manual untuk lookup cepat.
- Settings: info koneksi API, placeholder konfigurasi scanner & keamanan.

---

## Tech Stack

| Lapisan | Teknologi |
|---------|-----------|
| **Framework** | [Flutter](https://flutter.dev) 3.41+ (stable) |
| **Bahasa** | [Dart](https://dart.dev) 3.11+ |
| **State management** | [Provider](https://pub.dev/packages/provider) (`ChangeNotifier`) |
| **Networking** | [http](https://pub.dev/packages/http) |
| **UI & tipografi** | Material 3, [Google Fonts](https://pub.dev/packages/google_fonts) (Poppins) |
| **Animasi** | [flutter_animate](https://pub.dev/packages/flutter_animate) |
| **Charts** | [fl_chart](https://pub.dev/packages/fl_chart) |
| **Kamera / scan** | [mobile_scanner](https://pub.dev/packages/mobile_scanner) |
| **Keamanan** | [crypto](https://pub.dev/packages/crypto) (MD5), [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage), [shared_preferences](https://pub.dev/packages/shared_preferences) |
| **Testing** | `flutter_test`, `integration_test`, `mock` (HTTP client di unit test) |
| **Build tools** | [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons), [flutter_lints](https://pub.dev/packages/flutter_lints) |

### Platform yang didukung

| Platform | Status |
|----------|--------|
| Android | ✅ APK release (utama untuk handheld) |
| Windows | ✅ Desktop debug/release |
| iOS | 🔧 Struktur proyek siap (build sesuai kebutuhan) |
| Web | 🔧 Dapat dijalankan untuk development |

---

## Dependencies (pubspec)

### Production

| Package | Versi | Peran di aplikasi |
|---------|-------|-------------------|
| `flutter` | SDK | Framework UI cross-platform |
| `cupertino_icons` | ^1.0.8 | Ikon gaya iOS (pelengkap Material) |
| `http` | ^1.5.0 | REST client ke API Gistex GCC Cutting |
| `mobile_scanner` | ^7.1.2 | Scan barcode via kamera perangkat |
| `provider` | ^6.1.5 | State management (`AuthState`, `ScannerState`) |
| `google_fonts` | ^6.3.0 | Tipografi Poppins konsisten |
| `flutter_animate` | ^4.5.2 | Animasi micro-interaction UI |
| `crypto` | ^3.0.6 | Hash MD5 password saat login |
| `flutter_secure_storage` | ^9.2.4 | Penyimpanan aman data sesi (mobile/desktop) |
| `shared_preferences` | ^2.5.3 | Persistensi preferensi & fallback storage |
| `fl_chart` | ^1.2.0 | Line chart, pie chart dashboard stasiun |

### Development

| Package | Versi | Peran |
|---------|-------|-------|
| `flutter_test` | SDK | Unit & widget test |
| `integration_test` | SDK | End-to-end test |
| `flutter_lints` | ^6.0.0 | Aturan analisis statis Dart/Flutter |
| `flutter_launcher_icons` | ^0.14.4 | Generate ikon launcher Android/iOS |

---

## Integrasi API

Base URL default: `http://10.5.0.201:9000`  
Header wajib: `rfid-key: <API_KEY>`

| Modul | Method | Endpoint |
|-------|--------|----------|
| Lookup barcode | GET | `/api/gcc/cutting/list?barcode=` |
| Registrasi bundle | POST | `/api/gcc/cutting/reg` |
| Output bundle | POST | `/api/gcc/cutting/output` |
| QC qty | GET | `/api/gcc/cutting/qc/qty` |
| Submit QC | POST | `/api/gcc/cutting/qc` |
| QC qty repair | GET | `/api/gcc/cutting/qc/qty/repair` |
| Repair → Good | POST | `/api/gcc/cutting/qc/repair/good` |
| Repair → Reject | POST | `/api/gcc/cutting/qc/repair/reject` |
| Dashboard QC | GET | `/api/gcc/cutting/qc/data` |
| Supermarket scan | POST | `/api/gcc/cutting/smarket` |
| Dashboard Supermarket | GET | `/api/gcc/cutting/smarket/data` |
| Checking RFID | GET | `/api/gcc/cutting/check?rfid_bundles=` |

Dokumentasi detail:
- [`docs/supermarket-scanning-api.md`](docs/supermarket-scanning-api.md)
- [`docs/quality-control-dashboard-api.md`](docs/quality-control-dashboard-api.md)

---

## Struktur Proyek

```
lib/
├── app/                    # MaterialApp, theme, entry gate
├── config/                 # Feature flags (coming soon, dll.)
├── core/
│   ├── models/             # Model data bersama (RFID checking, dll.)
│   └── theme/              # Motion tokens, design tokens
├── features/
│   ├── auth/               # Login, register, secure storage
│   └── scanner/
│       ├── data/           # ScannerApiService (REST)
│       ├── state/          # ScannerState, dashboard snapshots
│       └── presentation/
│           ├── pages/      # Shell, stasiun (bundle/QC/supermarket/…)
│           └── widgets/    # Dialog scan, charts, checking RFID
docs/                       # Dokumentasi API
test/                       # Unit test (API service, dll.)
```

---

## Memulai Development

### Prasyarat

- Flutter SDK **3.41+** / Dart **3.11+**
- Android SDK (untuk build APK)
- Visual Studio Build Tools (untuk build Windows, opsional)

### Instalasi

```bash
git clone https://github.com/rusdifn08/rfid_tracking_mobile.git
cd rfid_tracking_mobile
flutter pub get
```

### Menjalankan

```bash
# Android / perangkat terhubung
flutter run

# Windows desktop
flutter run -d windows
```

### Build APK Release

```bash
# APK universal (~66 MB)
flutter build apk --release

# APK per ABI (lebih kecil, ~20–27 MB per arsitektur)
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

### Menjalankan Test

```bash
flutter test
flutter analyze
```

---

## Konfigurasi

| Item | Lokasi | Keterangan |
|------|--------|------------|
| Base URL API | `lib/features/scanner/data/scanner_api_service.dart` | `defaultBaseUrl` |
| API Key | `scanner_api_service.dart` | `defaultApiKey` → header `rfid-key` |
| Coming Soon Supply Sewing | `lib/config/coming.dart` | `supplySewing = true/false` |
| Versi app | `pubspec.yaml` | `version: 1.0.1+2` |
| Ikon launcher | `lib/assets/icon.png` | via `flutter_launcher_icons` |

---

## Lisensi & Kontribusi

Proyek internal Gistex. Untuk perubahan fitur atau integrasi API baru, ikuti pola existing di `ScannerApiService` + `ScannerState` dan tambahkan unit test di `test/features/scanner/data/`.

---

<p align="center">
  <sub>Dibangun dengan Flutter · Gistex GCC Cutting RFID Tracking</sub>
</p>
