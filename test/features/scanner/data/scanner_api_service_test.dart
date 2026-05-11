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

    test('postCuttingBundleOutput mengirim body rfid_bundles dan nik', () async {
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
            'message': 'Berhasil mencatat Output Bundle',
            'data': <String, dynamic>{
              'wo': 'WO1',
              'rfid_bundles': 'RFID-Z',
              'qty_output': '10',
            },
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        apiKey: 'test-key',
        client: client,
      );

      final data = await service.postCuttingBundleOutput(
        rfidBundles: 'RFID-Z',
        nik: '12345',
      );

      expect(capturedUri.path, '/api/gcc/cutting/output');
      expect(capturedHeaders['rfid-key'], 'test-key');
      expect(capturedHeaders['Content-Type'], 'application/json');
      expect(capturedBody['rfid_bundles'], 'RFID-Z');
      expect(capturedBody['nik'], '12345');
      expect(data['wo'], 'WO1');
    });

    test('postCuttingBundleOutput melempar error saat status gagal', () async {
      final client = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 400,
            'status': 'error',
            'message': 'RFID tidak dikenal',
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        client: client,
      );

      expect(
        () => service.postCuttingBundleOutput(
          rfidBundles: 'X',
          nik: '1',
        ),
        throwsA(
          predicate<Object>(
            (e) => e.toString().contains('RFID tidak dikenal'),
          ),
        ),
      );
    });

    test('fetchQualityControlQty mengirim GET body rfid_bundles', () async {
      late http.BaseRequest capturedRequest;
      final client = MockClient((http.Request request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 200,
            'status': 'success',
            'message': 'Qty output berhasil ditemukan.',
            'data': <String, dynamic>{
              'id_bundles': 12,
              'rfid_bundles': '0013468151',
              'qty_output': 10,
            },
          }),
          200,
        );
      });

      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        apiKey: 'test-key',
        client: client,
      );

      final data = await service.fetchQualityControlQty(
        rfidBundles: '0013468151',
      );

      final request = capturedRequest as http.Request;
      expect(request.method, 'GET');
      expect(request.url.path, '/api/gcc/cutting/qc/qty');
      expect(request.headers['rfid-key'], 'test-key');
      expect(request.headers['Content-Type'], 'application/json');
      expect(
        jsonDecode(request.body)['rfid_bundles'],
        '0013468151',
      );
      expect(data['qty_output'], 10);
    });

    test('postQualityControlResult mengirim payload QC yang benar', () async {
      late Uri capturedUri;
      late Map<String, dynamic> capturedBody;
      final client = MockClient((http.Request request) async {
        capturedUri = request.url;
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
        client: client,
      );

      await service.postQualityControlResult(
        rfidBundles: 'RF-01',
        reject: 1,
        repair: 2,
        good: 7,
        nik: '92300014',
      );

      expect(capturedUri.path, '/api/gcc/cutting/qc');
      expect(capturedBody['rfid_bundles'], 'RF-01');
      expect(capturedBody['reject'], 1);
      expect(capturedBody['repair'], 2);
      expect(capturedBody['good'], 7);
      expect(capturedBody['nik'], '92300014');
    });

    test('postSupermarketScan mengirim payload smarket yang benar', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      late Map<String, dynamic> capturedBody;
      final client = MockClient((http.Request request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': true,
            'message': 'SMarket IN berhasil diproses.',
            'data': <String, dynamic>{
              'rfid_bundles': 'RFID001',
              'line': 'L01',
              'branch': 'GM1',
              'qty': 20,
            },
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        apiKey: 'test-key',
        client: client,
      );

      final data = await service.postSupermarketScan(
        nik: '123456',
        status: 'in',
        line: 'L01',
        branch: 'GM1',
        rfidBundles: 'RFID001',
      );

      expect(capturedUri.path, '/api/gcc/cutting/smarket');
      expect(capturedHeaders['rfid-key'], 'test-key');
      expect(capturedHeaders['Content-Type'], 'application/json');
      expect(capturedBody['nik'], '123456');
      expect(capturedBody['status'], 'in');
      expect(capturedBody['line'], 'L01');
      expect(capturedBody['branch'], 'GM1');
      expect(capturedBody['rfid_bundles'], 'RFID001');
      expect(data['qty'], 20);
    });

    test('postSupermarketScan status in tidak wajib kirim line/branch', () async {
      late Map<String, dynamic> capturedBody;
      final client = MockClient((http.Request request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': true,
            'message': 'SMarket IN berhasil diproses.',
            'data': <String, dynamic>{'qty': 1},
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        client: client,
      );

      await service.postSupermarketScan(
        nik: '123456',
        status: 'in',
        line: null,
        branch: null,
        rfidBundles: 'RFID001',
      );

      expect(capturedBody['status'], 'in');
      expect(capturedBody.containsKey('line'), isFalse);
      expect(capturedBody.containsKey('branch'), isFalse);
    });

    test('fetchSupermarketDashboardData parse bundle/in/out/urgent', () async {
      final client = MockClient((http.Request request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/gcc/cutting/smarket/data');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'bundle': 4,
              'in': 178,
              'out': 19,
              'urgent': 15,
            },
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        client: client,
      );

      final data = await service.fetchSupermarketDashboardData();
      expect(data['bundle'], 4);
      expect(data['in'], 178);
      expect(data['out'], 19);
      expect(data['urgent'], 15);
    });

    test('fetchQualityControlDashboardData parse bundle/good/repair/reject', () async {
      final client = MockClient((http.Request request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/gcc/cutting/qc/data');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'bundle': 4,
              'good': 178,
              'repair': 19,
              'reject': 15,
            },
          }),
          200,
        );
      });
      final service = ScannerApiService(
        baseUrl: 'http://example.test',
        client: client,
      );

      final data = await service.fetchQualityControlDashboardData();
      expect(data['bundle'], 4);
      expect(data['good'], 178);
      expect(data['repair'], 19);
      expect(data['reject'], 15);
    });
  });
}
