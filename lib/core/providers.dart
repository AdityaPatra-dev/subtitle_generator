import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'security/secure_storage_service.dart';
import 'services/audio_cache_manager.dart';
import 'storage/database.dart';
import '../features/media/media_engine.dart';
import '../features/media/process_media_engine.dart';
import '../features/media/ffmpeg_kit_media_engine.dart';
import '../features/translation/translation_service.dart';
import '../features/transcription/pipeline_coordinator.dart';

// Theme Mode Provider (Light/Dark mode toggle)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Secure Storage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Media Engine Provider
final mediaEngineProvider = Provider<MediaEngine>((ref) {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    return const FfmpegKitMediaEngine();
  }
  return const ProcessMediaEngine();
});

// Audio Cache Manager Provider
final audioCacheManagerProvider = Provider<AudioCacheManager>((ref) {
  return AudioCacheManager();
});

// Translation Service Provider
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

// Pipeline Coordinator Provider
final pipelineCoordinatorProvider = Provider<PipelineCoordinator>((ref) {
  return PipelineCoordinator(
    db: ref.watch(databaseProvider),
    mediaEngine: ref.watch(mediaEngineProvider),
    secureStorage: ref.watch(secureStorageProvider),
    translationService: ref.watch(translationServiceProvider),
    audioCacheManager: ref.watch(audioCacheManagerProvider),
  );
});

// Stream Providers
final allJobsStreamProvider = StreamProvider<List<JobEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllJobs();
});

final incompleteJobsStreamProvider = StreamProvider<List<JobEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchIncompleteJobs();
});

final activeSubtitlesStreamProvider = StreamProvider<List<SubtitleEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActiveSubtitles();
});

// Provider API Keys State
class ApiKeysState {
  final String? groqKey;
  final String? geminiKey;
  final String? deepgramKey;
  final bool isLoading;

  const ApiKeysState({
    this.groqKey,
    this.geminiKey,
    this.deepgramKey,
    this.isLoading = false,
  });

  bool get hasAnyKey =>
      (groqKey != null && groqKey!.isNotEmpty) ||
      (geminiKey != null && geminiKey!.isNotEmpty) ||
      (deepgramKey != null && deepgramKey!.isNotEmpty);

  ApiKeysState copyWith({
    String? groqKey,
    String? geminiKey,
    String? deepgramKey,
    bool? isLoading,
  }) {
    return ApiKeysState(
      groqKey: groqKey ?? this.groqKey,
      geminiKey: geminiKey ?? this.geminiKey,
      deepgramKey: deepgramKey ?? this.deepgramKey,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ApiKeysNotifier extends StateNotifier<ApiKeysState> {
  final SecureStorageService _storage;

  ApiKeysNotifier(this._storage) : super(const ApiKeysState(isLoading: true)) {
    loadKeys();
  }

  Future<void> loadKeys() async {
    state = state.copyWith(isLoading: true);
    final groq = await _storage.getGroqKey();
    final gemini = await _storage.getGeminiKey();
    final deepgram = await _storage.getDeepgramKey();
    state = ApiKeysState(
      groqKey: groq,
      geminiKey: gemini,
      deepgramKey: deepgram,
      isLoading: false,
    );
  }

  Future<void> setGroqKey(String key) async {
    await _storage.saveGroqKey(key);
    state = state.copyWith(groqKey: key);
  }

  Future<void> setGeminiKey(String key) async {
    await _storage.saveGeminiKey(key);
    state = state.copyWith(geminiKey: key);
  }

  Future<void> setDeepgramKey(String key) async {
    await _storage.saveDeepgramKey(key);
    state = state.copyWith(deepgramKey: key);
  }
}

final apiKeysProvider = StateNotifierProvider<ApiKeysNotifier, ApiKeysState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiKeysNotifier(storage);
});

