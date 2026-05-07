# Testing API Scanner

Folder ini berisi panduan testing koneksi frontend Flutter ke backend API lokal.

## 1) Unit Test API Service (mock HTTP)

Menjalankan validasi endpoint, header `rfid-key`, dan body `rfid_bundles` tanpa akses jaringan:

```bash
flutter test test/features/scanner/data/scanner_api_service_test.dart
```

## 2) Integration Test Koneksi Real API (GET + POST)

Pastikan device/emulator berada di jaringan yang sama dengan server `10.5.0.201:9000`.

```bash
flutter test integration_test/api/scanner_api_connection_test.dart --dart-define=API_BASE_URL=http://10.5.0.201:9000 --dart-define=API_KEY=0011779933 --dart-define=API_TEST_BARCODE=BD20260504-565507 --dart-define=API_TEST_RFID=RFID-INTEGRATION-001
```

Jika menggunakan perangkat Android fisik, jalankan:

```bash
flutter test integration_test/api/scanner_api_connection_test.dart -d <device_id> --dart-define=API_BASE_URL=http://10.5.0.201:9000 --dart-define=API_KEY=0011779933
```

## 3) Checklist Debug Jika Timeout

- HP/device dan backend berada di WiFi lokal yang sama.
- API dapat diakses dari browser/device: `http://10.5.0.201:9000/api/gcc/cutting/list?barcode=BD20260504-565507`
- Firewall Windows/server membuka port `9000`.
- Header request benar: `rfid-key: 0011779933`.
- Android manifest sudah mengizinkan cleartext HTTP (`usesCleartextTraffic=true`).
