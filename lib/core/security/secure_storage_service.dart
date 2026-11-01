abstract class SecureStorageService {
  Future<void> saveGroqKey(String key);
  Future<String?> getGroqKey();
  Future<void> deleteGroqKey();

  Future<void> saveGeminiKey(String key);
  Future<String?> getGeminiKey();
  Future<void> deleteGeminiKey();

  Future<void> saveDeepgramKey(String key);
  Future<String?> getDeepgramKey();
  Future<void> deleteDeepgramKey();

  Future<String?> getDeviceId();
  Future<void> saveDeviceId(String deviceId);

  Future<void> purgeAllCredentials();
}
