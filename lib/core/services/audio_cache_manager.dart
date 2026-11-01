import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioCacheManager {
  static const String _folderName = 'audio_cache';

  /// Returns the persistent directory where extracted audio files are cached
  Future<Directory> getAudioCacheDir() async {
    final baseDir = await getApplicationSupportDirectory();
    final cacheDir = Directory(p.join(baseDir.path, _folderName));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generates a deterministic, collision-free cache key for a specific video & audio track
  String generateCacheKey({
    required String filename,
    required int fileSizeBytes,
    required int audioStreamIndex,
  }) {
    final cleanBase = p
        .basenameWithoutExtension(filename)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return '${cleanBase}_${fileSizeBytes}_track$audioStreamIndex.mp3';
  }

  /// Checks if a valid, non-empty extracted audio file already exists in cache
  Future<File?> getValidCachedAudio(String cacheKey) async {
    final cacheDir = await getAudioCacheDir();
    final file = File(p.join(cacheDir.path, cacheKey));
    if (await file.exists()) {
      final len = await file.length();
      if (len > 1024) {
        return file;
      }
    }
    return null;
  }

  /// Returns the expected absolute target path for a cache key
  Future<String> getTargetFilePath(String cacheKey) async {
    final cacheDir = await getAudioCacheDir();
    return p.join(cacheDir.path, cacheKey);
  }

  /// Safely deletes a cached audio file by path or key
  Future<bool> deleteCachedAudio(String pathOrKey) async {
    try {
      File file;
      if (pathOrKey.contains(Platform.pathSeparator)) {
        file = File(pathOrKey);
      } else {
        final dir = await getAudioCacheDir();
        file = File(p.join(dir.path, pathOrKey));
      }
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Calculates total bytes used by cached audio files
  Future<int> getTotalCacheSizeBytes() async {
    int total = 0;
    try {
      final dir = await getAudioCacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
    } catch (_) {}
    return total;
  }

  /// Purges all cached audio files
  Future<void> clearAllCache() async {
    try {
      final dir = await getAudioCacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }
}
