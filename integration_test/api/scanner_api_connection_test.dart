import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scanner/features/scanner/data/scanner_api_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ScannerApiService.defaultBaseUrl,
  );
  const apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: ScannerApiService.defaultApiKey,
  );
  const sampleBarcode = String.fromEnvironment(
    'API_TEST_BARCODE',
    defaultValue: 'BD20260504-565507',
  );
  const sampleRfid = String.fromEnvironment(
    'API_TEST_RFID',
    defaultValue: 'RFID-INTEGRATION-001',
  );

  final service = ScannerApiService(baseUrl: baseUrl, apiKey: apiKey);

  testWidgets('GET /list berhasil mengambil data barcode', (_) async {
    final data = await service.fetchByBarcode(sampleBarcode);
    expect(data['barcode'], isNotNull);
    expect(data['wo'], isNotNull);
  });

  testWidgets('POST /reg mengirim registrasi barcode + rfid', (_) async {
    await service.registerBarcode(
      barcode: sampleBarcode,
      rfidBundles: sampleRfid,
    );
  });
}
