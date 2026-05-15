import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/models/rfid_checking_record.dart';

class ScannerApiService {
  ScannerApiService({
    String? baseUrl,
    String? apiKey,
    http.Client? client,
  }) : _baseUrl = baseUrl ?? defaultBaseUrl,
       _apiKey = apiKey ?? defaultApiKey,
       _client = client ?? http.Client();

  static const String defaultBaseUrl = 'http://10.5.0.201:9000';
  static const String defaultApiKey = '0011779933';
  final String _baseUrl;
  final String _apiKey;
  final http.Client _client;

  Map<String, String> get _baseHeaders => <String, String>{
    'rfid-key': _apiKey,
  };

  static Map<String, dynamic>? _tryDecodeMap(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  static String _messageFromBody(Map<String, dynamic>? body, String fallback) {
    final dynamic m = body?['message'];
    if (m != null && m.toString().trim().isNotEmpty) {
      return m.toString();
    }
    return fallback;
  }

  Future<Map<String, dynamic>> fetchByBarcode(String barcode) async {
    final uri = Uri.parse(
      '$_baseUrl/api/gcc/cutting/list?barcode=${Uri.encodeQueryComponent(barcode)}',
    );

    final response = await _client.get(uri, headers: _baseHeaders);
    final Map<String, dynamic>? decoded = _tryDecodeMap(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _messageFromBody(
          decoded,
          'GET list gagal (HTTP ${response.statusCode}).',
        ),
      );
    }

    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }

    final dynamic code = decoded['code'];
    final String? status = decoded['status']?.toString();
    if (code != 200 || status != 'success') {
      throw Exception(
        _messageFromBody(decoded, 'Data barcode tidak tersedia.'),
      );
    }

    final List<dynamic> data = (decoded['data'] as List<dynamic>? ?? []);
    if (data.isEmpty) {
      throw Exception(
        _messageFromBody(decoded, 'Data barcode tidak ditemukan.'),
      );
    }

    return data.first as Map<String, dynamic>;
  }

  Future<void> registerBarcode({
    required String barcode,
    required String rfidBundles,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/reg');
    final response = await _client.post(
      uri,
      headers: <String, String>{
        ..._baseHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'barcode': barcode,
        'rfid_bundles': rfidBundles,
      }),
    );

    final Map<String, dynamic>? decoded = _tryDecodeMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'POST registrasi gagal (HTTP ${response.statusCode}).',
        ),
      );
    }

    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }

    final dynamic code = decoded['code'];
    final String? status = decoded['status']?.toString();
    if (code != 200 || status != 'success') {
      throw Exception(_messageFromBody(decoded, 'Registrasi gagal.'));
    }
  }

  /// POST `/api/gcc/cutting/output` — mencatat output bundle (RFID + NIK).
  Future<Map<String, dynamic>> postCuttingBundleOutput({
    required String rfidBundles,
    required String nik,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/output');
    final response = await _client.post(
      uri,
      headers: <String, String>{
        ..._baseHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'rfid_bundles': rfidBundles,
        'nik': nik,
      }),
    );

    final Map<String, dynamic>? decoded = _tryDecodeMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'POST output bundle gagal (HTTP ${response.statusCode}).',
        ),
      );
    }

    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }

    final dynamic code = decoded['code'];
    final String? status = decoded['status']?.toString();
    if (code != 200 || status != 'success') {
      throw Exception(_messageFromBody(decoded, 'Mencatat output bundle gagal.'));
    }

    final dynamic data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Data response tidak valid.');
  }

  /// GET `/api/gcc/cutting/qc/qty` untuk mengambil qty output by RFID bundle.
  Future<Map<String, dynamic>> fetchQualityControlQty({
    required String rfidBundles,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/qc/qty');
    final request = http.Request('GET', uri)
      ..headers.addAll(<String, String>{
        ..._baseHeaders,
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode(<String, String>{'rfid_bundles': rfidBundles});

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final Map<String, dynamic>? decoded = _tryDecodeMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'GET qty QC gagal (HTTP ${response.statusCode}).',
        ),
      );
    }

    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }

    final dynamic code = decoded['code'];
    final String? status = decoded['status']?.toString();
    if (code != 200 || status != 'success') {
      throw Exception(_messageFromBody(decoded, 'Qty output tidak ditemukan.'));
    }

    final dynamic data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Data response tidak valid.');
  }

  /// POST `/api/gcc/cutting/qc` untuk submit hasil QC.
  Future<void> postQualityControlResult({
    required String rfidBundles,
    required int reject,
    required int repair,
    required int good,
    required String nik,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/qc');
    final response = await _client.post(
      uri,
      headers: <String, String>{
        ..._baseHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'rfid_bundles': rfidBundles,
        'reject': reject,
        'repair': repair,
        'good': good,
        'nik': nik,
      }),
    );

    final Map<String, dynamic>? decoded = _tryDecodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'POST quality control gagal (HTTP ${response.statusCode}).',
        ),
      );
    }
    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }
    final dynamic code = decoded['code'];
    final String? status = decoded['status']?.toString();
    if (code != 200 || status != 'success') {
      throw Exception(_messageFromBody(decoded, 'Submit quality control gagal.'));
    }
  }

  /// GET `/api/gcc/cutting/qc/qty/repair` — qty repair by RFID bundle.
  Future<Map<String, dynamic>> fetchQualityControlRepairQty({
    required String rfidBundles,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/qc/qty/repair').replace(
      queryParameters: <String, String>{
        'rfid_bundles': rfidBundles.trim(),
      },
    );
    final response = await _client.get(uri, headers: _baseHeaders);
    final Map<String, dynamic>? decoded = _tryDecodeMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'GET qty repair gagal (HTTP ${response.statusCode}).',
        ),
      );
    }
    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }
    if (!_isResponseSuccess(decoded)) {
      throw Exception(_messageFromBody(decoded, 'Qty repair tidak ditemukan.'));
    }

    final dynamic data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Data response tidak valid.');
  }

  /// POST `/api/gcc/cutting/qc/repair/good` — konversi repair ke good.
  Future<Map<String, dynamic>> postQualityControlRepairToGood({
    required String rfidBundles,
    required int qty,
    required String nik,
  }) async {
    return _postQualityControlRepairDisposition(
      path: '/api/gcc/cutting/qc/repair/good',
      rfidBundles: rfidBundles,
      qty: qty,
      nik: nik,
      fallbackError: 'Konversi repair ke good gagal.',
    );
  }

  /// POST `/api/gcc/cutting/qc/repair/reject` — konversi repair ke reject.
  Future<Map<String, dynamic>> postQualityControlRepairToReject({
    required String rfidBundles,
    required int qty,
    required String nik,
  }) async {
    return _postQualityControlRepairDisposition(
      path: '/api/gcc/cutting/qc/repair/reject',
      rfidBundles: rfidBundles,
      qty: qty,
      nik: nik,
      fallbackError: 'Konversi repair ke reject gagal.',
    );
  }

  Future<Map<String, dynamic>> _postQualityControlRepairDisposition({
    required String path,
    required String rfidBundles,
    required int qty,
    required String nik,
    required String fallbackError,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.post(
      uri,
      headers: <String, String>{
        ..._baseHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'rfid_bundles': rfidBundles.trim(),
        'qty': qty,
        'nik': nik.trim(),
      }),
    );

    final Map<String, dynamic>? decoded = _tryDecodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          '$fallbackError (HTTP ${response.statusCode}).',
        ),
      );
    }
    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }
    if (!_isResponseSuccess(decoded)) {
      throw Exception(_messageFromBody(decoded, fallbackError));
    }

    final dynamic data = decoded['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? Map<String, dynamic>.from(data)
        : data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    payload['message'] = _messageFromBody(decoded, fallbackError);
    return payload;
  }

  /// POST `/api/gcc/cutting/smarket` untuk proses supermarket in/out/urgent.
  Future<Map<String, dynamic>> postSupermarketScan({
    required String nik,
    required String status,
    String? line,
    String? branch,
    required String rfidBundles,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/smarket');
    final response = await _client.post(
      uri,
      headers: <String, String>{
        ..._baseHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'nik': nik,
        'status': status,
        'rfid_bundles': rfidBundles,
        if (line != null && line.trim().isNotEmpty) 'line': line,
        if (branch != null && branch.trim().isNotEmpty) 'branch': branch,
      }),
    );

    final Map<String, dynamic>? decoded = _tryDecodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'POST supermarket gagal (HTTP ${response.statusCode}).',
        ),
      );
    }
    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }

    // Backend menggunakan dua bentuk indikator sukses:
    // 1) {"success": true, ...}                (versi awal contoh dokumentasi)
    // 2) {"code": 200, "status": "success", ...} (konsisten dengan endpoint lain)
    // Terima keduanya supaya tidak salah label "gagal" saat backend mengirim
    // format konvensional code/status seperti endpoint /qc dan /smarket/data.
    final success = _isResponseSuccess(decoded);
    if (!success) {
      throw Exception(
        _messageFromBody(decoded, 'Proses supermarket gagal.'),
      );
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Data response tidak valid.');
  }

  static bool _isResponseSuccess(Map<String, dynamic> decoded) {
    if (decoded['success'] == true) {
      return true;
    }
    final dynamic code = decoded['code'];
    final String status = decoded['status']?.toString().toLowerCase() ?? '';
    final bool codeOk = code == 200 || code == '200';
    return codeOk && (status.isEmpty || status == 'success');
  }

  Future<Map<String, dynamic>> fetchSupermarketDashboardData() async {
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/smarket/data');
    final response = await _client.get(uri, headers: _baseHeaders);
    final decoded = _tryDecodeMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'GET dashboard supermarket gagal (HTTP ${response.statusCode}).',
        ),
      );
    }
    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return decoded;
  }

  /// GET `/api/gcc/cutting/check` — riwayat tracking RFID bundle.
  Future<RfidCheckingApiResponse> fetchRfidChecking({
    required String rfidBundles,
  }) async {
    final clean = rfidBundles.trim();
    if (clean.isEmpty) {
      throw Exception('RFID bundle wajib diisi.');
    }
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/check').replace(
      queryParameters: <String, String>{'rfid_bundles': clean},
    );
    final response = await _client.get(uri, headers: _baseHeaders);
    final decoded = _tryDecodeMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'GET checking RFID gagal (HTTP ${response.statusCode}).',
        ),
      );
    }
    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }
    if (!_isResponseSuccess(decoded)) {
      throw Exception(
        _messageFromBody(decoded, 'Checking RFID gagal.'),
      );
    }

    final message = _messageFromBody(
      decoded,
      'Data checking berhasil ditampilkan.',
    );
    final countRaw = decoded['count'];
    final count = countRaw is int
        ? countRaw
        : int.tryParse(countRaw?.toString() ?? '') ?? 0;

    final dataRaw = decoded['data'];
    final list = dataRaw is List ? dataRaw : const <dynamic>[];
    final records = list
        .whereType<Map>()
        .map((e) => RfidCheckingRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    return RfidCheckingApiResponse(
      message: message,
      count: count > 0 ? count : records.length,
      records: records,
    );
  }

  Future<Map<String, dynamic>> fetchQualityControlDashboardData() async {
    final uri = Uri.parse('$_baseUrl/api/gcc/cutting/qc/data');
    final response = await _client.get(uri, headers: _baseHeaders);
    final decoded = _tryDecodeMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _messageFromBody(
          decoded,
          'GET dashboard quality control gagal (HTTP ${response.statusCode}).',
        ),
      );
    }
    if (decoded == null) {
      throw Exception('Response tidak valid.');
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return decoded;
  }
}
