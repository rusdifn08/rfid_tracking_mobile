import 'package:flutter_test/flutter_test.dart';
import 'package:scanner/features/auth/data/auth_api_service.dart';
import 'package:scanner/features/auth/data/auth_secure_storage.dart';
import 'package:scanner/features/auth/models/auth_user.dart';
import 'package:scanner/features/auth/state/auth_state.dart';

class _FakeAuthApiService extends AuthApiService {
  _FakeAuthApiService({this.payload});

  final AuthLoginPayload? payload;

  @override
  Future<AuthLoginPayload> fetchUserByNik(String nik) async {
    if (payload == null) {
      throw Exception('No payload');
    }
    return payload!;
  }
}

void main() {
  group('AuthState login API MD5', () {
    test('sukses login nik/password 92400689 dan simpan secure storage', () async {
      final storage = MemoryAuthSecureStorage();
      final api = _FakeAuthApiService(
        payload: AuthLoginPayload(
          user: const AuthUser(
            nik: '92400689',
            name: 'RUSDI FADLI NURYUDA',
            jabatan: 'ROBOTIC',
            line: '26',
            branch: 'GM1',
            rfidUser: '0009510568',
            telegram: '',
            noHp: '',
            role: 'user',
            token: 'token-92400689',
          ),
          serverPasswordHash: 'd468bbde1dcf14c899a86ab8c59b34d7',
        ),
      );
      final state = AuthState(apiService: api, storage: storage);

      final ok = await state.login(nik: '92400689', password: '92400689');

      expect(ok, isTrue);
      expect(state.isLoggedIn, isTrue);
      expect(state.currentUser?.nik, '92400689');
      final saved = await storage.readUser();
      expect(saved?.nik, '92400689');
      expect(saved?.jabatan, 'ROBOTIC');
    });

    test('gagal login jika hash tidak cocok', () async {
      final storage = MemoryAuthSecureStorage();
      final api = _FakeAuthApiService(
        payload: AuthLoginPayload(
          user: const AuthUser(
            nik: '92400689',
            name: 'RUSDI FADLI NURYUDA',
            jabatan: 'ROBOTIC',
            line: '26',
            branch: 'GM1',
            rfidUser: '0009510568',
            telegram: '',
            noHp: '',
            role: 'user',
            token: 'token-92400689',
          ),
          serverPasswordHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      );
      final state = AuthState(apiService: api, storage: storage);

      final ok = await state.login(nik: '92400689', password: '92400689');

      expect(ok, isFalse);
      expect(state.isLoggedIn, isFalse);
      expect(state.errorMessage, contains('Password tidak sesuai'));
      expect(await storage.readUser(), isNull);
    });
  });
}
