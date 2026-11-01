import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/core/services/audio_cache_manager.dart';
import 'package:subtitle_generator/core/storage/database.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_serializer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioCacheManager Tests', () {
    late AudioCacheManager cacheManager;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('audio_cache_test_');
      cacheManager = AudioCacheManager();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generateCacheKey produces deterministic clean filename', () {
      final key1 = cacheManager.generateCacheKey(
        filename: 'My Test Video! [1080p].mp4',
        fileSizeBytes: 1048576,
        audioStreamIndex: 0,
      );

      final key2 = cacheManager.generateCacheKey(
        filename: 'My Test Video! [1080p].mp4',
        fileSizeBytes: 1048576,
        audioStreamIndex: 0,
      );

      expect(key1, key2);
      expect(key1.endsWith('.mp3'), true);
      expect(key1.contains('My_Test_Video___1080p_'), true);
      expect(key1.contains('_1048576_track0'), true);
    });

    test('deleteCachedAudio removes file safely', () async {
      final dummyFile = File('${tempDir.path}/test_cache_del.mp3');
      await dummyFile.writeAsString('dummy data content');
      expect(await dummyFile.exists(), true);

      final deleted = await cacheManager.deleteCachedAudio(dummyFile.path);
      expect(deleted, true);
      expect(await dummyFile.exists(), false);
    });
  });

  group('SubtitleSerializer partial export tests', () {
    test('segmentsToSrt formats segments with notice', () {
      final segments = [
        const TranscriptSegmentEntry(
          id: 1,
          jobId: 'job-1',
          chunkId: 'c1',
          segmentIndex: 0,
          startSeconds: 0.0,
          endSeconds: 3.5,
          sourceText: 'Hello world.',
          translatedText: 'Hola mundo.',
          isTranslated: true,
        ),
        const TranscriptSegmentEntry(
          id: 2,
          jobId: 'job-1',
          chunkId: 'c1',
          segmentIndex: 1,
          startSeconds: 4.0,
          endSeconds: 7.2,
          sourceText: 'This is a test run.',
          translatedText: 'Esta es una ejecución de prueba.',
          isTranslated: true,
        ),
      ];

      final srt = SubtitleSerializer.segmentsToSrt(
        segments,
        finalNotice: '[Paused at chunk 1 - resume later]',
      );

      expect(srt.contains('Hola mundo.'), true);
      expect(srt.contains('Esta es una ejecución de prueba.'), true);
      expect(srt.contains('[Paused at chunk 1 - resume later]'), true);
      expect(srt.contains('00:00:00,000 --> 00:00:03,500'), true);
    });
  });
}
