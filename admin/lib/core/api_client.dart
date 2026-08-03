import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Set at build time: --dart-define=SNAPPRINT_API_URL=https://api.snapprint.in
const _configuredBaseUrl = String.fromEnvironment('SNAPPRINT_API_URL');
const _localDevBaseUrl = 'http://localhost:8000';
const _tokenKey = 'admin_token';

String get _baseUrl {
  final value = _configuredBaseUrl.isEmpty
      ? (kReleaseMode
            ? throw StateError(
                'SNAPPRINT_API_URL must be set for release builds.',
              )
            : _localDevBaseUrl)
      : _configuredBaseUrl;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasAuthority) {
    throw StateError('SNAPPRINT_API_URL must be an absolute URL.');
  }
  if (kReleaseMode && uri.scheme != 'https') {
    throw StateError('SNAPPRINT_API_URL must use HTTPS in release builds.');
  }
  return value;
}

class AdminApiClient {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  late final Dio dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
}

final adminApiClientProvider =
    Provider<AdminApiClient>((_) => AdminApiClient());
