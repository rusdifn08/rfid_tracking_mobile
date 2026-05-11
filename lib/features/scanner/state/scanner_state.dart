import 'package:flutter/foundation.dart';

import '../../../core/models/scan_history_entry.dart';
import '../data/scanner_api_service.dart';

enum AppMenu { home, history, manual, settings, profile }
enum HistoryFilter { today, all }
enum NoticeType { success, error }

class StationScanEntry {
  const StationScanEntry({
    required this.rfid,
    required this.workOrder,
    required this.qty,
    required this.scannedAt,
  });

  final String rfid;
  final String workOrder;
  final int qty;
  final DateTime scannedAt;
}

class QcStationScanEntry {
  const QcStationScanEntry({
    required this.rfid,
    required this.workOrder,
    required this.qty,
    required this.good,
    required this.repair,
    required this.reject,
    required this.scannedAt,
  });

  final String rfid;
  final String workOrder;
  final int qty;
  final int good;
  final int repair;
  final int reject;
  final DateTime scannedAt;
}

class AppNotice {
  const AppNotice({
    required this.id,
    required this.message,
    required this.type,
  });

  final int id;
  final String message;
  final NoticeType type;
}

class ScannerState extends ChangeNotifier {
  ScannerState({ScannerApiService? apiService})
      : _apiService = apiService ?? ScannerApiService();

  final ScannerApiService _apiService;
  int _noticeCounter = 0;

  final Map<String, String> fields = <String, String>{
    'wo': '',
    'style': '',
    'meja': '',
    'warna': '',
    'size': '',
    'noIkat': '',
    'noUrut': '',
    'season': '',
    'country': '',
    'placing': '',
  };

  final List<ScanHistoryEntry> _scanHistory = <ScanHistoryEntry>[];
  final List<StationScanEntry> _bundleScans = <StationScanEntry>[];
  // Menjaga kompatibilitas saat hot-reload dari tipe lama (StationScanEntry).
  final List<Object> _qualityControlScans = <Object>[];
  final List<StationScanEntry> _supermarketScans = <StationScanEntry>[];
  final List<StationScanEntry> _supplySewingScans = <StationScanEntry>[];
  final Set<String> highlightedFields = <String>{};

  bool isFetching = false;
  bool isRegistering = false;
  bool isScanLocked = false;
  bool _isFetchingSupermarketDashboard = false;
  bool _isFetchingQcDashboard = false;
  String barcodeInput = '';
  String rfidBundlesInput = '';
  String? errorMessage;
  String? registerMessage;
  String? lastBarcode;
  /// Terakhir sukses POST /reg (untuk layar Tracking).
  String? lastRegisteredBarcode;
  String? lastRegisteredRfid;
  AppNotice? latestNotice;
  AppMenu activeMenu = AppMenu.home;
  HistoryFilter historyFilter = HistoryFilter.today;
  Map<String, int> _supermarketDashboard = <String, int>{
    'bundle': 0,
    'in': 0,
    'out': 0,
    'urgent': 0,
  };
  Map<String, int> _qualityControlDashboard = <String, int>{
    'bundle': 0,
    'good': 0,
    'repair': 0,
    'reject': 0,
  };

  List<ScanHistoryEntry> get scanHistory => List.unmodifiable(_scanHistory);
  List<StationScanEntry> get bundleScans => List.unmodifiable(_bundleScans);
  List<QcStationScanEntry> get qualityControlScans => List.unmodifiable(
    _qualityControlScans.map((entry) {
      if (entry is QcStationScanEntry) {
        return entry;
      }
      if (entry is StationScanEntry) {
        // Data lama sebelum refactor QC split: asumsikan semuanya Good.
        return QcStationScanEntry(
          rfid: entry.rfid,
          workOrder: entry.workOrder,
          qty: entry.qty,
          good: entry.qty,
          repair: 0,
          reject: 0,
          scannedAt: entry.scannedAt,
        );
      }
      return QcStationScanEntry(
        rfid: '',
        workOrder: 'UNKNOWN',
        qty: 0,
        good: 0,
        repair: 0,
        reject: 0,
        scannedAt: DateTime.now(),
      );
    }).where((entry) => entry.rfid.isNotEmpty),
  );
  List<StationScanEntry> get supermarketScans =>
      List.unmodifiable(_supermarketScans);
  List<StationScanEntry> get supplySewingScans =>
      List.unmodifiable(_supplySewingScans);
  Map<String, int> get supermarketDashboard => Map<String, int>.unmodifiable(
    _supermarketDashboard,
  );
  Map<String, int> get qualityControlDashboard => Map<String, int>.unmodifiable(
    _qualityControlDashboard,
  );

  bool get hasResultData => fields.values.any((value) => value.isNotEmpty);
  Set<String> get scannedBundleRfids => _bundleScans.map((e) => e.rfid).toSet();
  bool hasBundleScanRfid(String rfid) =>
      _bundleScans.any((entry) => entry.rfid == rfid.trim());

  List<ScanHistoryEntry> get filteredHistory {
    if (historyFilter == HistoryFilter.all) {
      return scanHistory;
    }
    final now = DateTime.now();
    return scanHistory.where((entry) {
      return entry.createdAt.year == now.year &&
          entry.createdAt.month == now.month &&
          entry.createdAt.day == now.day;
    }).toList();
  }

  void setActiveMenu(AppMenu menu) {
    activeMenu = menu;
    notifyListeners();
  }

  void setHistoryFilter(HistoryFilter filter) {
    historyFilter = filter;
    notifyListeners();
  }

  void setBarcodeInput(String value) {
    barcodeInput = value;
    notifyListeners();
  }

  void setRfidBundlesInput(String value) {
    rfidBundlesInput = value;
    notifyListeners();
  }

  void clearRfidInput() {
    rfidBundlesInput = '';
    notifyListeners();
  }

  void removeHistory(ScanHistoryEntry entry) {
    _scanHistory.remove(entry);
    notifyListeners();
  }

  void clearLatestNotice(int id) {
    if (latestNotice?.id != id) {
      return;
    }
    latestNotice = null;
    notifyListeners();
  }

  Future<void> fetchByBarcode(
    String barcode, {
    bool pushFetchSuccessNotice = true,
  }) async {
    if (isFetching || barcode.isEmpty) {
      return;
    }

    isFetching = true;
    errorMessage = null;
    lastBarcode = barcode;
    barcodeInput = barcode;
    notifyListeners();

    try {
      final item = await _apiService.fetchByBarcode(barcode);
      _scanHistory.removeWhere((entry) => entry.barcode == barcode);
      _scanHistory.insert(
        0,
        ScanHistoryEntry(barcode: barcode, createdAt: DateTime.now()),
      );
      _fillFields(item, barcode);
      if (pushFetchSuccessNotice) {
        _pushNotice(
          'Data barcode berhasil diambil: $barcode',
          type: NoticeType.success,
        );
      }
    } catch (error) {
      errorMessage = userFacingError(error);
      _pushNotice(errorMessage!, type: NoticeType.error);
      notifyListeners();
    } finally {
      isFetching = false;
      notifyListeners();
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        isScanLocked = false;
        notifyListeners();
      });
    }
  }

  Future<bool> registerCurrentBarcode({
    bool pushSuccessNotice = true,
    bool pushErrorNotice = true,
    bool pushValidationNotice = true,
    String? rfidOverride,
    String? barcodeOverride,
  }) async {
    final o = barcodeOverride?.trim() ?? '';
    final fromInput = barcodeInput.trim();
    final barcode = o.isNotEmpty
        ? o
        : (fromInput.isNotEmpty ? fromInput : (lastBarcode ?? '').trim());
    final rfid = (rfidOverride ?? rfidBundlesInput).trim();
    if (isRegistering) {
      return false;
    }
    if (barcode.isEmpty) {
      registerMessage = 'Barcode belum tersedia. Scan atau input barcode dulu.';
      if (pushValidationNotice) {
        _pushNotice(registerMessage!, type: NoticeType.error);
      }
      notifyListeners();
      return false;
    }
    if (rfid.isEmpty) {
      registerMessage = 'RFID Bundles wajib diisi.';
      if (pushValidationNotice) {
        _pushNotice(registerMessage!, type: NoticeType.error);
      }
      notifyListeners();
      return false;
    }

    isRegistering = true;
    registerMessage = null;
    errorMessage = null;
    notifyListeners();

    var ok = false;
    try {
      await _apiService.registerBarcode(barcode: barcode, rfidBundles: rfid);
      registerMessage = 'Registrasi berhasil untuk barcode $barcode';
      if (pushSuccessNotice) {
        _pushNotice(registerMessage!, type: NoticeType.success);
      }
      ok = true;
    } catch (error) {
      registerMessage = userFacingError(error);
      if (pushErrorNotice) {
        _pushNotice(registerMessage!, type: NoticeType.error);
      }
    } finally {
      isRegistering = false;
      notifyListeners();
    }
    if (ok) {
      lastRegisteredBarcode = barcode;
      lastRegisteredRfid = rfid;
      notifyListeners();
    }
    return ok;
  }

  void lockScan() {
    isScanLocked = true;
    notifyListeners();
  }

  void clearHighlights() {
    highlightedFields.clear();
    notifyListeners();
  }

  String getField(String key) => fields[key] ?? '';

  /// Memanggil POST `/api/gcc/cutting/output` lalu menambahkan baris ke dashboard Bundle.
  Future<void> submitBundleCuttingOutput({
    required String rfidBundles,
    required String nik,
  }) async {
    final cleanRfid = rfidBundles.trim();
    final cleanNik = nik.trim();
    if (cleanRfid.isEmpty) {
      throw Exception('RFID bundle wajib diisi.');
    }
    if (cleanNik.isEmpty) {
      throw Exception('NIK wajib diisi.');
    }
    if (_bundleScans.any((entry) => entry.rfid == cleanRfid)) {
      throw Exception('RFID sudah ada di tabel Bundle.');
    }

    final data = await _apiService.postCuttingBundleOutput(
      rfidBundles: cleanRfid,
      nik: cleanNik,
    );

    final wo = (data['wo'] ?? '').toString().trim();
    final qtyRaw = data['qty_output'] ?? data['qty_bundles'];
    final qty = qtyRaw is int
        ? qtyRaw
        : int.tryParse(qtyRaw?.toString().trim() ?? '') ?? 10;

    DateTime scannedAt = DateTime.now();
    final outputTime = data['output_time'];
    if (outputTime != null && outputTime.toString().trim().isNotEmpty) {
      final parsed = DateTime.tryParse(outputTime.toString().trim());
      if (parsed != null) {
        scannedAt = parsed;
      }
    }

    _bundleScans.insert(
      0,
      StationScanEntry(
        rfid: cleanRfid,
        workOrder: wo.isEmpty ? '-' : wo,
        qty: qty < 1 ? 10 : qty,
        scannedAt: scannedAt,
      ),
    );

    final barcode = data['barcode']?.toString().trim();
    if (barcode != null && barcode.isNotEmpty) {
      lastBarcode = barcode;
    }
    lastRegisteredRfid = cleanRfid;
    notifyListeners();
  }

  bool addBundleStationScan({
    required String rfid,
    String workOrder = 'LIVE-BUNDLE',
    int qty = 10,
  }) {
    final clean = rfid.trim();
    if (clean.isEmpty || _bundleScans.any((entry) => entry.rfid == clean)) {
      return false;
    }
    _bundleScans.insert(
      0,
      StationScanEntry(
        rfid: clean,
        workOrder: workOrder,
        qty: qty,
        scannedAt: DateTime.now(),
      ),
    );
    lastRegisteredRfid = clean;
    notifyListeners();
    return true;
  }

  bool addQualityControlScan({
    required String rfid,
    String workOrder = 'LIVE-QC',
    int qty = 10,
    required int good,
    required int repair,
    required int reject,
  }) {
    final clean = rfid.trim();
    if (good < 0 || repair < 0 || reject < 0 || good + repair + reject != qty) {
      return false;
    }
    if (
      clean.isEmpty ||
      qualityControlScans.any((entry) => entry.rfid == clean)
    ) {
      return false;
    }
    _qualityControlScans.insert(
      0,
      QcStationScanEntry(
        rfid: clean,
        workOrder: workOrder,
        qty: qty,
        good: good,
        repair: repair,
        reject: reject,
        scannedAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  Future<int> fetchQualityControlQty({required String rfidBundles}) async {
    final cleanRfid = rfidBundles.trim();
    if (cleanRfid.isEmpty) {
      throw Exception('RFID bundle wajib diisi.');
    }
    final data = await _apiService.fetchQualityControlQty(rfidBundles: cleanRfid);
    final rawQty = data['qty_output'];
    final qty = rawQty is int
        ? rawQty
        : int.tryParse(rawQty?.toString().trim() ?? '');
    if (qty == null || qty < 0) {
      throw Exception('Qty output tidak valid dari API.');
    }
    return qty;
  }

  Future<void> submitQualityControlResult({
    required String rfidBundles,
    required int qty,
    required int good,
    required int repair,
    required int reject,
    required String nik,
  }) async {
    final cleanRfid = rfidBundles.trim();
    final cleanNik = nik.trim();
    if (cleanRfid.isEmpty) {
      throw Exception('RFID bundle wajib diisi.');
    }
    if (cleanNik.isEmpty) {
      throw Exception('NIK wajib diisi.');
    }
    if (qty < 0 || good < 0 || repair < 0 || reject < 0) {
      throw Exception('Nilai Qty QC tidak valid.');
    }
    if (good + repair + reject != qty) {
      throw Exception('Total Good + Repair + Reject harus sama dengan Qty Bundle.');
    }
    if (qualityControlScans.any((entry) => entry.rfid == cleanRfid)) {
      throw Exception('RFID sudah ada di tabel Quality Control.');
    }

    await _apiService.postQualityControlResult(
      rfidBundles: cleanRfid,
      reject: reject,
      repair: repair,
      good: good,
      nik: cleanNik,
    );

    _qualityControlScans.insert(
      0,
      QcStationScanEntry(
        rfid: cleanRfid,
        workOrder: 'LIVE-QC',
        qty: qty,
        good: good,
        repair: repair,
        reject: reject,
        scannedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  bool addSupermarketScan({
    required String rfid,
    String workOrder = 'LIVE-SUPERMARKET',
    int qty = 10,
  }) {
    final clean = rfid.trim();
    if (clean.isEmpty) {
      return false;
    }
    if (
      _supermarketScans.any(
        (entry) => entry.rfid == clean && entry.workOrder == workOrder,
      )
    ) {
      return false;
    }
    _supermarketScans.insert(
      0,
      StationScanEntry(
        rfid: clean,
        workOrder: workOrder,
        qty: qty,
        scannedAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  Future<void> submitSupermarketScan({
    required String rfidBundles,
    required String nik,
    required String status,
    String? line,
    String? branch,
  }) async {
    final cleanRfid = rfidBundles.trim();
    final cleanNik = nik.trim();
    final cleanStatus = status.trim().toLowerCase();
    final cleanLine = line?.trim().toUpperCase() ?? '';
    final cleanBranch = branch?.trim().toUpperCase() ?? '';

    if (cleanRfid.isEmpty) {
      throw Exception('RFID bundle wajib diisi.');
    }
    if (cleanNik.isEmpty) {
      throw Exception('NIK wajib diisi.');
    }
    if (!<String>{'in', 'out', 'urgent'}.contains(cleanStatus)) {
      throw Exception('Status supermarket tidak valid.');
    }
    if (cleanStatus != 'in') {
      if (cleanLine.isEmpty) {
        throw Exception('Line wajib diisi.');
      }
      if (cleanBranch.isEmpty) {
        throw Exception('Branch wajib diisi.');
      }
    }
    final statusLabel = switch (cleanStatus) {
      'out' => 'CHECK-OUT',
      'urgent' => 'SUPPLY-URGENT',
      _ => 'CHECK-IN',
    };
    if (
      _supermarketScans.any(
        (entry) => entry.rfid == cleanRfid && entry.workOrder == statusLabel,
      )
    ) {
      throw Exception('RFID untuk status ini sudah pernah di-scan.');
    }

    final data = await _apiService.postSupermarketScan(
      nik: cleanNik,
      status: cleanStatus,
      line: cleanStatus == 'in' ? null : cleanLine,
      branch: cleanStatus == 'in' ? null : cleanBranch,
      rfidBundles: cleanRfid,
    );

    final qtyRaw = data['qty'] ?? data['qty_bundles'];
    final qty = qtyRaw is int
        ? qtyRaw
        : int.tryParse(qtyRaw?.toString().trim() ?? '') ?? 10;
    DateTime scannedAt = DateTime.now();
    final smarketTime = data['smarket_time']?.toString().trim();
    if (smarketTime != null && smarketTime.isNotEmpty) {
      final parsed = DateTime.tryParse(smarketTime);
      if (parsed != null) {
        scannedAt = parsed;
      }
    }
    _supermarketScans.insert(
      0,
      StationScanEntry(
        rfid: cleanRfid,
        workOrder: statusLabel,
        qty: qty,
        scannedAt: scannedAt,
      ),
    );
    notifyListeners();
  }

  bool addSupplySewingScan({
    required String rfid,
    String workOrder = 'LIVE-SUPPLY',
    int qty = 10,
  }) {
    final clean = rfid.trim();
    if (clean.isEmpty || _supplySewingScans.any((entry) => entry.rfid == clean)) {
      return false;
    }
    _supplySewingScans.insert(
      0,
      StationScanEntry(
        rfid: clean,
        workOrder: workOrder,
        qty: qty,
        scannedAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  Future<void> fetchSupermarketDashboard() async {
    if (_isFetchingSupermarketDashboard) {
      return;
    }
    _isFetchingSupermarketDashboard = true;
    try {
      final data = await _apiService.fetchSupermarketDashboardData();
      _supermarketDashboard = <String, int>{
        'bundle': _parseInt(data['bundle']),
        'in': _parseInt(data['in']),
        'out': _parseInt(data['out']),
        'urgent': _parseInt(data['urgent']),
      };
      notifyListeners();
    } catch (_) {
      // Tetap biarkan UI pakai fallback data saat API dashboard gagal.
    } finally {
      _isFetchingSupermarketDashboard = false;
    }
  }

  Future<void> fetchQualityControlDashboard() async {
    if (_isFetchingQcDashboard) {
      return;
    }
    _isFetchingQcDashboard = true;
    try {
      final data = await _apiService.fetchQualityControlDashboardData();
      _qualityControlDashboard = <String, int>{
        'bundle': _parseInt(data['bundle']),
        'good': _parseInt(data['good']),
        'repair': _parseInt(data['repair']),
        'reject': _parseInt(data['reject']),
      };
      notifyListeners();
    } catch (_) {
      // Tetap biarkan UI pakai fallback data saat API dashboard gagal.
    } finally {
      _isFetchingQcDashboard = false;
    }
  }

  void _fillFields(Map<String, dynamic> item, String barcode) {
    lastBarcode = barcode;
    fields['wo'] = _toValue(item['wo']);
    fields['style'] = _toValue(item['style']);
    fields['meja'] = _toValue(item['meja']);
    fields['warna'] = _toValue(item['warna']);
    fields['size'] = _toValue(item['size']);
    fields['noIkat'] = _toValue(item['noIkat']);
    fields['noUrut'] = _toValue(item['noUrut']);
    fields['season'] = _toValue(item['season']);
    fields['country'] = _toValue(item['country']);
    fields['placing'] = _toValue(item['placing']);

    highlightedFields
      ..clear()
      ..addAll(fields.keys);
    notifyListeners();
  }

  String _toValue(dynamic value) => value == null ? '' : value.toString();

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  static String userFacingError(Object error) {
    final s = error.toString();
    if (s.startsWith('Exception: ')) {
      return s.substring('Exception: '.length);
    }
    return s;
  }

  void _pushNotice(String message, {required NoticeType type}) {
    _noticeCounter += 1;
    latestNotice = AppNotice(id: _noticeCounter, message: message, type: type);
    notifyListeners();
  }
}
