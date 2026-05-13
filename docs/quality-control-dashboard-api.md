# Dokumentasi API Dashboard Quality Control

## Endpoint
- `GET /api/gcc/cutting/qc/data`

## Contoh response sukses
```json
{
  "code": 200,
  "status": "success",
  "message": "Data dashboard QC berhasil ditampilkan.",
  "data": {
    "tanggal_from": "2026-05-09T00:00:00",
    "tanggal_to": "2026-05-09T23:59:59",
    "summary": {
      "jumlah_bundle": 6,
      "total_good": 4,
      "total_repair": 2,
      "total_reject": 1
    },
    "data_per_jam": [
      { "jam": "08:00", "good": 2, "repair": 1, "reject": 0 },
      { "jam": "09:00", "good": 2, "repair": 1, "reject": 1 }
    ],
    "total_data": 2,
    "items": [
      {
        "tanggal": "2026-05-09T08:15:00",
        "id_bundles": 12,
        "rfid_bundles": "0013468151",
        "wo": "WO-001",
        "qty_output": 10,
        "qty_good": 7,
        "qty_repair": 2,
        "qty_reject": 1
      }
    ]
  }
}
```

## Pemetaan ke UI aplikasi
- `summary` -> empat kartu di atas (Jumlah Bundle / Total Good / Total Repair / Total Reject).
- `data_per_jam` -> chart `Data Per Jam` dengan tiga garis (Good, Repair, Reject)
  pada widget `QcHourlyChartCard`.
- `summary.total_*` juga menjadi sumber pie chart `Komposisi Quality Control (%)`.
- `items` -> tabel `Tabel Quality Control` dengan kolom RFID Bundle, WO, QTY,
  Good, Repair, Reject.

## Catatan implementasi
- Aplikasi memuat dashboard di `initState` halaman QC (`fetchQualityControlDashboard`).
- Setelah POST `/api/gcc/cutting/qc` (submit hasil QC) sukses, aplikasi otomatis
  memanggil ulang endpoint dashboard agar UI selalu sinkron tanpa user harus
  reload manual.
