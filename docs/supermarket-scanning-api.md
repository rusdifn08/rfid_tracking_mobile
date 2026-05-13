# Dokumentasi Penggunaan API Supermarket Scanning

## Endpoint
- `POST /api/gcc/cutting/smarket`

## Status yang didukung
- `in`
- `out`
- `urgent`

## Aturan payload berdasarkan status
- **Check In (`status: "in"`)**
  - wajib kirim: `nik`, `status`, `rfid_bundles`
  - **tidak perlu** kirim `line` dan `branch`
- **Check Out (`status: "out"`)**
  - wajib kirim: `nik`, `status`, `rfid_bundles`, `line`, `branch`
- **Supply Urgent (`status: "urgent"`)**
  - wajib kirim: `nik`, `status`, `rfid_bundles`, `line`, `branch`

## Contoh request body

### 1) Check In (tanpa line/branch)
```json
{
  "nik": "123456",
  "status": "in",
  "rfid_bundles": "RFID001"
}
```

### 2) Check Out
```json
{
  "nik": "123456",
  "status": "out",
  "line": "L01",
  "branch": "GM1",
  "rfid_bundles": "RFID001"
}
```

### 3) Supply Urgent
```json
{
  "nik": "123456",
  "status": "urgent",
  "line": "L02",
  "branch": "GM2",
  "rfid_bundles": "RFID001"
}
```

## Contoh response sukses
```json
{
  "success": true,
  "message": "SMarket IN berhasil diproses.",
  "data": {
    "id_bundles": 1001,
    "rfid_bundles": "RFID001",
    "barcode": "BC001",
    "wo": "WO123456",
    "style": "STYLE001",
    "size": "M",
    "meja": "M01",
    "warna": "BLACK",
    "no_ikat": "12",
    "no_urut": "5",
    "season": "SS26",
    "country": "US",
    "qty_bundles": 20,
    "placing": "A1",
    "nik": "123456",
    "line": "L01",
    "branch": "GM1",
    "qty": 20,
    "last_status": "IN_SMARKET",
    "smarket_time": "2026-05-08T10:30:00"
  }
}
```

## Catatan implementasi di aplikasi
- Popup Supermarket mengisi `status` berdasarkan tab:
  - Check In -> `in`
  - Check Out -> `out`
  - Supply Urgent -> `urgent`
- Field `line` dan `branch` hanya tersedia saat tab Check Out/Supply Urgent.
- Data dashboard atas tetap diambil dari endpoint dashboard:
  - `GET /api/gcc/cutting/smarket/data`
- Setelah POST `/api/gcc/cutting/smarket` sukses, aplikasi otomatis memanggil
  ulang endpoint dashboard di atas agar kartu summary, grafik per jam, dan tabel
  selalu mencerminkan data terbaru.

## Endpoint Dashboard Supermarket

### `GET /api/gcc/cutting/smarket/data`

Contoh response sukses:
```json
{
  "code": 200,
  "status": "success",
  "message": "Data dashboard SMarket berhasil ditampilkan.",
  "data": {
    "tanggal_from": "2026-05-08T00:00:00",
    "tanggal_to": "2026-05-08T23:59:59",
    "summary": {
      "jumlah_bundle": 5,
      "check_in": 3,
      "check_out": 2,
      "supply_urgent": 1
    },
    "data_per_jam": [
      {
        "jam": "15:00",
        "check_in": 2,
        "check_out": 1,
        "supply_urgent": 1
      }
    ],
    "total_data": 4,
    "items": [
      {
        "tanggal": "2026-05-08T15:31:00",
        "id_bundles": 1001,
        "rfid_bundles": "0002028014",
        "wo": "187491",
        "qty_output": 8,
        "qty_good": 8,
        "qty_smarket_in": 8,
        "last_time_smarket_in": "2026-05-08T15:31:00",
        "qty_smarket_out": 0,
        "last_time_smarket_out": null,
        "qty": 8,
        "line": null,
        "branch": null,
        "last_status": "IN_SMARKET",
        "smarket_time": "2026-05-08T15:31:00"
      }
    ]
  }
}
```

Pemetaan ke UI:
- `summary` -> empat kartu di atas (Jumlah Bundle / Check In / Check Out / Supply Urgent).
- `data_per_jam` -> chart `Data Per Jam` dengan tiga garis (Check In, Check Out, Supply Urgent).
- `items` -> tabel `Tabel Supermarket Cutting` dengan kolom RFID Bundle, WO,
  QTY, Line, Lokasi (`branch` jika ada, fallback `supermarket`), dan Waktu
  (diformat `dd MMM yyyy, HH:mm` dari `smarket_time`).
