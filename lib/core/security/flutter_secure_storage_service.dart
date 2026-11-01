import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_service.dart';

class FlutterSecureStorageService implements SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _keyGroq = 'byok_groq_api_key';
  static const String _keyGemini = 'byok_gemini_api_key';
  static const String _keyDeepgram = 'byok_deepgram_api_key';
  static const String _keyDeviceId = 'app_device_uuid';

  FlutterSecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
              mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  /// Checks if Linux Secret Service daemon is available
  static Future<bool> isLinuxSecretServiceAvailable() async {
    if (!Platform.isLinux) return true;
    try {
      final result = await Process.run('busctl', ['--user', 'status', 'org.freedesktop.secrets']);
      return result.exitCode == 0;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> saveGroqKey(String key) async {
    await _storage.write(key: _keyGroq, value: key.trim());
  }

  @override
  Future<String?> getGroqKey() async {
    return _storage.read(key: _keyGroq);
  }

  @override
  Future<void> deleteGroqKey() async {
    await _storage.delete(key: _keyGroq);
  }

  @override
  Future<void> saveGeminiKey(String key) async {
    await _storage.write(key: _keyGemini, value: key.trim());
  }

  @override
  Future<String?> getGeminiKey() async {
    return _storage.read(key: _keyGemini);
  }

  @override
  Future<void> deleteGeminiKey() async {
    await _storage.delete(key: _keyGemini);
  }

  @override
  Future<void> saveDeepgramKey(String key) async {
    await _storage.write(key: _keyDeepgram, value: key.trim());
  }

  @override
  Future<String?> getDeepgramKey() async {
    return _storage.read(key: _keyDeepgram);
  }

  @override
  Future<void> deleteDeepgramKey() async {
    await _storage.delete(key: _keyDeepgram);
  }

  @override
  Future<String?> getDeviceId() async {
    return _storage.read(key: _keyDeviceId);
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  @override
  Future<void> purgeAllCredentials() async {
    await _storage.deleteAll();
  }
}

