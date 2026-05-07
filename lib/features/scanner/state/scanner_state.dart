import 'package:flutter/foundation.dart';

import '../../../core/models/scan_history_entry.dart';
import '../data/scanner_api_service.dart';

enum AppMenu { home, history, manual, settings, profile }
enum HistoryFilter { today, all }
enum NoticeType { success, error }

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
  final Set<String> highlightedFields = <String>{};

  bool isFetching = false;
  bool isRegistering = false;
  bool isScanLocked = false;
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

  List<ScanHistoryEntry> get scanHistory => List.unmodifiable(_scanHistory);

  bool get hasResultData => fields.values.any((value) => value.isNotEmpty);

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
      errorMessage = _userFacingError(error);
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
      registerMessage = _userFacingError(error);
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

  static String _userFacingError(Object error) {
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
