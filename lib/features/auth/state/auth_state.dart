import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../data/auth_api_service.dart';
import '../data/auth_secure_storage.dart';
import '../models/auth_user.dart';

class AuthState extends ChangeNotifier {
  AuthState({
    AuthApiService? apiService,
    AuthSecureStorage? storage,
  }) : _apiService = apiService ?? AuthApiService(),
       _storage = storage ?? SharedPrefsAuthStorage();

  final AuthApiService _apiService;
  final AuthSecureStorage _storage;

  bool isBooting = true;
  bool isLoading = false;
  bool isRegistering = false;
  bool isLoggedIn = false;
  String? errorMessage;
  String? registerErrorMessage;
  String? registerSuccessMessage;
  AuthUser? currentUser;

  Future<void> initialize() async {
    if (!isBooting) {
      return;
    }
    final saved = await _storage.readUser();
    if (saved != null) {
      currentUser = saved;
      isLoggedIn = true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    isBooting = false;
    notifyListeners();
  }

  Future<bool> login({
    required String nik,
    required String password,
  }) async {
    if (isLoading) {
      return false;
    }

    final cleanNik = nik.trim();
    final cleanPassword = password.trim();
    if (cleanNik.isEmpty || cleanPassword.isEmpty) {
      errorMessage = 'NIK dan password wajib diisi.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    registerErrorMessage = null;
    notifyListeners();

    try {
      final inputHash = md5.convert(utf8.encode(cleanPassword)).toString();
      final payload = await _apiService.fetchUserByNik(cleanNik);
      if (payload.serverPasswordHash != inputHash.toLowerCase()) {
        throw Exception('Password tidak sesuai dengan data API.');
      }
      currentUser = payload.user;
      await _storage.saveUser(payload.user);
      isLoggedIn = true;
      return true;
    } catch (error) {
      errorMessage = _toMessage(error);
      isLoggedIn = false;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerUser({
    required String rfidUser,
    required String password,
    required String nama,
    required String nik,
    required String bagian,
    required String line,
    String telegram = '',
    String noHp = '',
  }) async {
    if (isRegistering) {
      return false;
    }
    final cleanRfid = rfidUser.trim();
    final cleanPassword = password.trim();
    final cleanNama = nama.trim();
    final cleanNik = nik.trim();
    final cleanBagian = bagian.trim();
    final cleanLine = line.trim().isEmpty ? '1' : line.trim();
    final cleanTelegram = telegram.trim();
    final cleanNoHp = noHp.trim();

    if (cleanRfid.isEmpty ||
        cleanPassword.isEmpty ||
        cleanNama.isEmpty ||
        cleanNik.isEmpty ||
        cleanBagian.isEmpty) {
      registerErrorMessage = 'RFID, password, nama, NIK, dan bagian wajib diisi.';
      registerSuccessMessage = null;
      notifyListeners();
      return false;
    }

    isRegistering = true;
    registerErrorMessage = null;
    registerSuccessMessage = null;
    notifyListeners();
    try {
      await _apiService.registerUser(
        RegisterUserRequest(
          rfidUser: cleanRfid,
          telegram: cleanTelegram,
          noHp: cleanNoHp,
          nama: cleanNama,
          nik: cleanNik,
          bagian: cleanBagian,
          line: cleanLine,
          password: cleanPassword,
        ),
      );
      registerSuccessMessage = 'Registrasi user $cleanNik berhasil.';
      return true;
    } catch (error) {
      registerErrorMessage = _toMessage(error);
      return false;
    } finally {
      isRegistering = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    currentUser = null;
    isLoggedIn = false;
    errorMessage = null;
    registerErrorMessage = null;
    registerSuccessMessage = null;
    await _storage.clearUser();
    notifyListeners();
  }

  static String _toMessage(Object error) {
    final text = error.toString();
    if (text.contains('Failed to fetch')) {
      return 'Login API gagal terhubung (Failed to fetch). Gunakan build Android/Windows untuk akses langsung ke IP lokal.';
    }
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }
}
