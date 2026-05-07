import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_user.dart';

class AuthLoginPayload {
  const AuthLoginPayload({
    required this.user,
    required this.serverPasswordHash,
  });

  final AuthUser user;
  final String serverPasswordHash;
}

class RegisterUserRequest {
  const RegisterUserRequest({
    required this.rfidUser,
    required this.telegram,
    required this.noHp,
    required this.nama,
    required this.nik,
    required this.bagian,
    required this.line,
    required this.password,
  });

  final String rfidUser;
  final String telegram;
  final String noHp;
  final String nama;
  final String nik;
  final String bagian;
  final String line;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rfid_user': rfidUser,
      'telegram': telegram,
      'no_hp': noHp,
      'nama': nama,
      'nik': nik,
      'bagian': bagian,
      'line': line,
      'password': password,
    };
  }
}

class AuthApiService {
  AuthApiService({
    String? baseUrl,
    String? apiKey,
    http.Client? client,
  }) : _baseUrl = baseUrl ?? defaultBaseUrl,
       _apiKey = apiKey ?? defaultApiKey,
       _client = client ?? http.Client();

  static const String defaultBaseUrl = String.fromEnvironment(
    'AUTH_BASE_URL',
    defaultValue: 'http://10.5.0.106:7000',
  );
  static const String defaultApiKey = String.fromEnvironment(
    'AUTH_API_KEY',
    defaultValue: '6lYZkryM.j50CVZgnpBl8X7Nx6sy5KRyY6ET7k3Cb',
  );

  final String _baseUrl;
  final String _apiKey;
  final http.Client _client;

  Future<AuthLoginPayload> fetchUserByNik(String nik) async {
    final uri = Uri.parse(
      '$_baseUrl/user?nik=${Uri.encodeQueryComponent(nik)}',
    );
    final response = await _client.get(
      uri,
      headers: <String, String>{'X-Api-Key': _apiKey},
    );

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Response login tidak valid.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readMessage(body, 'Login API gagal (${response.statusCode}).'));
    }

    final success = body['success'] == true;
    if (!success) {
      throw Exception(_readMessage(body, 'Login ditolak server.'));
    }

    final user = body['user'];
    if (user is! Map<String, dynamic>) {
      throw Exception('Data user dari server tidak valid.');
    }

    final serverHash = _pickServerHash(body, user);
    if (serverHash.isEmpty) {
      throw Exception('Hash password dari API tidak tersedia.');
    }

    final nikValue = (user['nik'] ?? '').toString();
    final nama = (user['nama'] ?? user['name'] ?? '').toString();
    final jabatan = (user['bagian'] ?? user['jabatan'] ?? '').toString();
    final role = (user['role'] ?? 'user').toString();

    return AuthLoginPayload(
      user: AuthUser(
        nik: nikValue,
        name: nama,
        jabatan: jabatan,
        line: (user['line'] ?? '').toString(),
        branch: (user['branch'] ?? '').toString(),
        rfidUser: (user['rfid_user'] ?? '').toString(),
        telegram: (user['telegram'] ?? '').toString(),
        noHp: (user['no_hp'] ?? '').toString(),
        role: role,
        token: 'token-$nikValue',
      ),
      serverPasswordHash: serverHash,
    );
  }

  Future<void> registerUser(RegisterUserRequest request) async {
    final uri = Uri.parse('$_baseUrl/inputUser');
    final response = await _client.post(
      uri,
      headers: <String, String>{
        'X-Api-Key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      } else if (decoded is Map) {
        body = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      throw Exception('Response register tidak valid.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _readMessage(body, 'Register API gagal (${response.statusCode}).'),
      );
    }

    final successValue = body?['success'];
    if (successValue != null && successValue != true) {
      throw Exception(_readMessage(body, 'Registrasi ditolak server.'));
    }
  }

  static String _pickServerHash(
    Map<String, dynamic> body,
    Map<String, dynamic> user,
  ) {
    final hash = [
      body['password_hash'],
      user['pwd_md5'],
      user['password_hash'],
    ].map((v) => (v ?? '').toString().trim()).firstWhere(
      (v) => v.isNotEmpty,
      orElse: () => '',
    );
    return hash.toLowerCase();
  }

  static String _readMessage(Map<String, dynamic>? body, String fallback) {
    final message = body?['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
    return fallback;
  }
}
