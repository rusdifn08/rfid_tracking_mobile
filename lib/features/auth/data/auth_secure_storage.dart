import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

abstract class AuthSecureStorage {
  Future<void> saveUser(AuthUser user);
  Future<AuthUser?> readUser();
  Future<void> clearUser();
}

class FlutterAuthSecureStorage implements AuthSecureStorage {
  FlutterAuthSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auth_user';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveUser(AuthUser user) async {
    await _storage.write(key: _key, value: jsonEncode(user.toJson()));
  }

  @override
  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return AuthUser.fromJson(decoded);
  }

  @override
  Future<void> clearUser() async {
    await _storage.delete(key: _key);
  }
}

class MemoryAuthSecureStorage implements AuthSecureStorage {
  AuthUser? _cache;

  @override
  Future<void> clearUser() async {
    _cache = null;
  }

  @override
  Future<AuthUser?> readUser() async {
    return _cache;
  }

  @override
  Future<void> saveUser(AuthUser user) async {
    _cache = user;
  }
}

class SharedPrefsAuthStorage implements AuthSecureStorage {
  static const _key = 'auth_user';

  @override
  Future<void> saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }

  @override
  Future<AuthUser?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return AuthUser.fromJson(decoded);
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
