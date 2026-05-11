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
