import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:subtitle_generator/core/constants/enums.dart';
import 'package:subtitle_generator/core/security/secure_storage_service.dart';
import 'package:subtitle_generator/core/storage/database.dart';
import 'package:subtitle_generator/features/media/process_media_engine.dart';
import 'package:subtitle_generator/features/transcription/pipeline_coordinator.dart';
import 'package:subtitle_generator/features/translation/translation_service.dart';

Map<String, String> _resolveKeys() {
  final keys = <String, String>{};
  final envFile = File('.env.development');
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      if (line.contains('=')) {
        final parts = line.split('=');
        final key = parts[0].trim();
        final val = parts.sublist(1).join('=').trim();
        keys[key] = val;
      }
    }
  }
  return keys;
}

class MemorySecureStorage extends SecureStorageService {
  final Map<String, String> _keys;
  MemorySecureStorage(this._keys);

  @override
  Future<String?> getGroqKey() async => _keys['GROQ_API_KEY'];
  @override
  Future<String?> getGeminiKey() async => _keys['GEMINI_API_KEY'];
  @override
  Future<String?> getDeepgramKey() async => _keys['DEEPGRAM_API_KEY'];
}

void main() {
  final keys = _resolveKeys();
  final groqKey = keys['GROQ_API_KEY'] ?? '';

  group('Full Video Pipeline Execution via PipelineCoordinator', () {
    test('Process Soul Land 2 Episode 177 (~15 min donghua) end-to-end', () async {
      expect(groqKey.isNotEmpty, true, reason: 'Groq API key required');

      setupSqliteOnLinux();
      const videoPath = 'test_vid/Soul Land 2 The Peerless Tang Sect Episode 177 Multiple Subtitles_1280x720.mp4';
      expect(await File(videoPath).exists(), true, reason: 'Video file not found');

      final db = AppDatabase(NativeDatabase.memory());
      const mediaEngine = ProcessMediaEngine();
      final secureStorage = MemorySecureStorage(keys);
      final translationService = TranslationService();

      final coordinator = PipelineCoordinator(
        db: db,
        mediaEngine: mediaEngine,
        secureStorage: secureStorage,
        translationService: translationService,
      );

      final tempDir = Directory('${Directory.systemTemp.path}/pipeline_full_test');
      await tempDir.create(recursive: true);

      final outputDir = Directory('test_samples/output_full_episode');
      await outputDir.create(recursive: true);

      print('\n========================================');
      print('Starting End-to-End Pipeline for: $videoPath');
      print('Transcriber: Groq Whisper Large-v3');
      print('Translator: Groq LLM (English)');
      print('========================================\n');

      final startTime = DateTime.now();

      await for (final progress in coordinator.processVideo(
        videoPath: videoPath,
        audioStreamIndex: 1,
        sourceLang: SourceLanguage.zhHans,
        providerType: TranscriptionProviderType.groqWhisperLargeV3,
        translationModel: TranslationModelType.groqLlama3370b,
        tempWorkDir: tempDir.path,
        outputDir: outputDir.path,
        exportVtt: true,
      )) {
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        print('[$elapsed s] [${(progress.progressPercent * 100).toStringAsFixed(0)}%] (${progress.status.displayName}) -> ${progress.statusMessage}');
      }

      final totalDuration = DateTime.now().difference(startTime);
      print('\nPipeline completed in ${totalDuration.inSeconds} seconds!');

      // Verify DB records
      final allJobs = await db.getAllJobs();
      expect(allJobs.isNotEmpty, true);
      final job = allJobs.first;
      expect(job.status, JobStatus.completed.name);
      print('Job ID: ${job.id}');
      print('Total chunks processed: ${job.totalChunks}');
      print('Audio Duration: ${job.durationSeconds.toStringAsFixed(1)}s');

      final allSubtitles = await db.getAllSubtitles();
      expect(allSubtitles.isNotEmpty, true);
      final sub = allSubtitles.first;
      print('Subtitle Title: ${sub.title}');
      print('Total Cues Generated: ${sub.cueCount}');
      print('Local SRT: ${sub.localSrtPath}');
      print('Local VTT: ${sub.localVttPath}');

      expect(await File(sub.localSrtPath).exists(), true);
      if (sub.localVttPath != null) {
        expect(await File(sub.localVttPath!).exists(), true);
      }

      // Read first 10 cues of the generated SRT
      final srtLines = await File(sub.localSrtPath).readAsLines();
      print('\n=== Generated SRT Preview (First 35 lines) ===');
      for (final line in srtLines.take(35)) {
        print(line);
      }

      await db.close();
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
