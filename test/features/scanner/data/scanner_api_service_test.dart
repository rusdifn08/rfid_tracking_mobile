import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:scanner/features/scanner/data/scanner_api_service.dart';

void main() {
  group('ScannerApiService', () {
    test('fetchByBarcode mengirim header API key dan parse data pertama', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      final client = MockClient((http.Request request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 200,
            'status': 'success',
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'wo': '187583', 'style': '1128733'},
            ],
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        apiKey: 'test-key',
        client: client,
      );

      final result = await service.fetchByBarcode('BD20260504-565507');

      expect(capturedUri.path, '/api/gcc/cutting/list');
      expect(capturedUri.queryParameters['barcode'], 'BD20260504-565507');
      expect(capturedHeaders['rfid-key'], 'test-key');
      expect(result['wo'], '187583');
    });

    test('fetchByBarcode memakai key message dari API saat HTTP error', () async {
      final client = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 404,
            'status': 'error',
            'message': 'Gagal: Barcode tidak ditemukan di data Dev.',
          }),
          404,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        client: client,
      );

      expect(
        () => service.fetchByBarcode('BDX'),
        throwsA(
          predicate<Object>(
            (e) => e.toString().contains('Gagal: Barcode tidak ditemukan'),
          ),
        ),
      );
    });

    test('fetchByBarcode melempar error ketika data kosong', () async {
      final client = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 200,
            'status': 'success',
            'data': <dynamic>[],
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        client: client,
      );

      expect(
        () => service.fetchByBarcode('ABC'),
        throwsA(isA<Exception>()),
      );
    });

    test('registerBarcode mengirim body dan header yang benar', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      late Map<String, dynamic> capturedBody;
      final client = MockClient((http.Request request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 200,
            'status': 'success',
            'message': 'ok',
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        apiKey: 'test-key',
        client: client,
      );

      await service.registerBarcode(
        barcode: 'BD20260504-565507',
        rfidBundles: 'RFID-123',
      );

      expect(capturedUri.path, '/api/gcc/cutting/reg');
      expect(capturedHeaders['rfid-key'], 'test-key');
      expect(capturedHeaders['Content-Type'], 'application/json');
      expect(capturedBody['barcode'], 'BD20260504-565507');
      expect(capturedBody['rfid_bundles'], 'RFID-123');
    });

    test('registerBarcode melempar error saat response gagal', () async {
      final client = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 500,
            'status': 'error',
            'message': 'Gagal simpan',
          }),
          500,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        client: client,
      );

      expect(
        () => service.registerBarcode(barcode: 'BDX', rfidBundles: 'RFID-X'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
