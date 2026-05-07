# Lessons Learned

## 2026-05-06
- Selalu verifikasi format response API nyata sebelum mengunci parser (`data.user` vs `user` top-level).
- Untuk login produksi, jangan mengunci autentikasi pada data lokal jika requirement utama adalah validasi API user aktif.
- Saat menambah asset JSON baru, pastikan deklarasi di `pubspec.yaml` dan jalankan `flutter pub get` agar asset bundle ter-refresh.
- Saat menambahkan field state UI baru di Flutter web, siapkan fallback null-safe karena hot reload dapat mempertahankan instance lama.
- Untuk kredensial sensitif (API key), wajib gunakan `--dart-define`/env dan hindari hardcode di repository.
