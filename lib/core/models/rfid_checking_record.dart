class RfidCheckingRecord {
  const RfidCheckingRecord({
    required this.id,
    required this.lastStatus,
    required this.qtyBatch,
    required this.batch,
    required this.logCreatedAt,
    required this.barcode,
    required this.rfidBundles,
    required this.wo,
    required this.style,
    required this.meja,
    required this.warna,
    required this.size,
    required this.noIkat,
    required this.noUrut,
    required this.season,
    required this.country,
    this.bundleCreatedAt,
  });

  final int id;
  final String lastStatus;
  final int qtyBatch;
  final String batch;
  final DateTime? logCreatedAt;
  final String barcode;
  final String rfidBundles;
  final String wo;
  final String style;
  final String meja;
  final String warna;
  final String size;
  final String noIkat;
  final String noUrut;
  final String season;
  final String country;
  final DateTime? bundleCreatedAt;

  factory RfidCheckingRecord.fromJson(Map<String, dynamic> json) {
    return RfidCheckingRecord(
      id: _parseInt(json['id']),
      lastStatus: (json['last_status'] ?? '').toString(),
      qtyBatch: _parseInt(json['qty_batch']),
      batch: (json['batch'] ?? '').toString(),
      logCreatedAt: _parseDateTime(json['log_created_at']),
      barcode: (json['barcode'] ?? '').toString(),
      rfidBundles: (json['rfid_bundles'] ?? '').toString(),
      wo: (json['wo'] ?? '').toString(),
      style: (json['style'] ?? '').toString(),
      meja: (json['meja'] ?? '').toString(),
      warna: (json['warna'] ?? '').toString(),
      size: (json['size'] ?? '').toString(),
      noIkat: (json['no_ikat'] ?? '').toString(),
      noUrut: (json['no_urut'] ?? '').toString(),
      season: (json['season'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      bundleCreatedAt: _parseDateTime(json['bundle_created_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}

class RfidCheckingApiResponse {
  const RfidCheckingApiResponse({
    required this.message,
    required this.count,
    required this.records,
  });

  final String message;
  final int count;
  final List<RfidCheckingRecord> records;

  bool get found => records.isNotEmpty;

  RfidCheckingRecord? get latestRecord {
    if (records.isEmpty) {
      return null;
    }
    final sorted = List<RfidCheckingRecord>.from(records)
      ..sort((a, b) {
        final at = a.logCreatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.logCreatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    return sorted.first;
  }
}
