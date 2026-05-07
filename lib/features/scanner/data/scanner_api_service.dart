import 'dart:convert';

import 'package:http/http.dart' as http;

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
}
