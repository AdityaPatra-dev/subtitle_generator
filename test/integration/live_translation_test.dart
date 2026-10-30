import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/core/constants/enums.dart';
import 'package:subtitle_generator/features/translation/translation_service.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_cue.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_line_breaker.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_serializer.dart';

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

void main() {
  final keys = _resolveKeys();
  final geminiKey = keys['GEMINI_API_KEY'] ?? '';
  final groqKey = keys['GROQ_API_KEY'] ?? '';

  group('Live Translation Verification (Groq)', () {
    final translationService = TranslationService();

    test('Groq translates Chinese BTTH segments into natural English SRT', () async {
      expect(groqKey.isNotEmpty, true, reason: 'Groq API key missing');

      final chineseSegments = [
        const TranslationSegmentInput(id: 1, source: '萧族的荣光萧炎必将其恢复'),
        const TranslationSegmentInput(id: 2, source: '当年我至未境之事'),
        const TranslationSegmentInput(id: 3, source: '说不定你真的可以完成'),
        const TranslationSegmentInput(id: 4, source: '尚还有些时间'),
        const TranslationSegmentInput(id: 5, source: '希望能够撑到你破'),
      ];

      print('\nTranslating Chinese BTTH segments using Groq...');
      final results = await translationService.translateSegments(
        segments: chineseSegments,
        modelType: TranslationModelType.groqLlama3370b,
        apiKey: groqKey,
      );

      print('\n=== Groq Chinese -> English Translation Results ===');
      for (final r in results) {
        print('  [ID ${r.id}]: "${chineseSegments[r.id - 1].source}" -> "${r.translation}"');
      }

      expect(results.length, chineseSegments.length);
    });
  });

  group('Live Translation Verification (Gemini 2.5 Flash)', () {
    final translationService = TranslationService();

    test('Gemini 2.5 Flash translates Chinese BTTH segments into natural English SRT', () async {
      expect(geminiKey.isNotEmpty, true, reason: 'Gemini API key missing');

      final chineseSegments = [
        const TranslationSegmentInput(id: 1, source: '萧族的荣光萧炎必将其恢复'),
        const TranslationSegmentInput(id: 2, source: '当年我至未境之事'),
        const TranslationSegmentInput(id: 3, source: '说不定你真的可以完成'),
        const TranslationSegmentInput(id: 4, source: '尚还有些时间'),
        const TranslationSegmentInput(id: 5, source: '希望能够撑到你破'),
      ];

      // Exact timestamps from Deepgram Nova-3 transcription
      final timestamps = [
        (start: 7.760, end: 10.800),
        (start: 19.465, end: 22.025),
        (start: 22.185, end: 24.825),
        (start: 26.491, end: 28.091),
        (start: 28.491, end: 31.851),
      ];

      print('\nTranslating Chinese BTTH segments using Gemini 2.5 Flash...');
      final results = await translationService.translateSegments(
        segments: chineseSegments,
        modelType: TranslationModelType.gemini25Flash,
        apiKey: geminiKey,
      );

      print('\n=== Chinese -> English Translation Results ===');
      for (final r in results) {
        print('  [ID ${r.id}]: "${chineseSegments[r.id - 1].source}" -> "${r.translation}"');
      }

      expect(results.length, chineseSegments.length);

      // Build Subtitle cues
      final List<SubtitleCue> englishCues = [];
      for (int i = 0; i < results.length; i++) {
        final t = results[i];
        final time = timestamps[i];
        englishCues.add(SubtitleCue(
          index: i + 1,
          startSeconds: time.start,
          endSeconds: time.end,
          text: SubtitleLineBreaker.formatCueText(t.translation),
        ));
      }

      final srt = SubtitleSerializer.toSrt(englishCues);
      print('\n=== Final English Subtitle (SRT) ===\n$srt');

      final outputFile = File('test_samples/chinese_btth_dialogue_30s.en.srt');
      await outputFile.writeAsString(srt);
      expect(await outputFile.exists(), true);
    });

    test('Gemini 2.5 Flash translates Japanese HUNTC dialogue into natural English SRT', () async {
      expect(geminiKey.isNotEmpty, true, reason: 'Gemini API key missing');

      final japaneseSegments = [
        const TranslationSegmentInput(id: 1, source: '一人でどうやってるとか'),
        const TranslationSegmentInput(id: 2, source: '想像もできないし。'),
        const TranslationSegmentInput(id: 3, source: 'そうね。'),
        const TranslationSegmentInput(id: 4, source: 'あのさ、'),
        const TranslationSegmentInput(id: 5, source: '男の子って'),
        const TranslationSegmentInput(id: 6, source: 'あれ'),
        const TranslationSegmentInput(id: 7, source: 'するじゃん'),
        const TranslationSegmentInput(id: 8, source: 'あれって。。。'),
        const TranslationSegmentInput(id: 9, source: '何'),
        const TranslationSegmentInput(id: 10, source: 'まあそういうこと。うーん。'),
      ];

      print('\nTranslating Japanese HUNTC segments using Gemini 2.5 Flash...');
      final results = await translationService.translateSegments(
        segments: japaneseSegments,
        modelType: TranslationModelType.gemini25Flash,
        apiKey: geminiKey,
      );

      print('\n=== Japanese -> English Translation Results ===');
      for (final r in results) {
        print('  [ID ${r.id}]: "${japaneseSegments[r.id - 1].source}" -> "${r.translation}"');
      }

      expect(results.length, japaneseSegments.length);

      final List<SubtitleCue> englishCues = [];
      for (int i = 0; i < results.length; i++) {
        final t = results[i];
        englishCues.add(SubtitleCue(
          index: i + 1,
          startSeconds: (i * 3.0),
          endSeconds: (i * 3.0) + 2.5,
          text: SubtitleLineBreaker.formatCueText(t.translation),
        ));
      }

      final srt = SubtitleSerializer.toSrt(englishCues);
      print('\n=== Final English Subtitle (SRT) Preview ===\n$srt');

      final outputFile = File('test_samples/japanese_huntc_45s.en.srt');
      await outputFile.writeAsString(srt);
      expect(await outputFile.exists(), true);
    });

    test('Gemini 2.5 Flash translates Chinese Soul Land 2 dialogue into natural English SRT', () async {
      expect(geminiKey.isNotEmpty, true);

      final soullandSegments = [
        const TranslationSegmentInput(id: 1, source: '我和武童只是误入此地没有干涉两位前辈的意思'),
        const TranslationSegmentInput(id: 2, source: '告辞'),
        const TranslationSegmentInput(id: 3, source: '哼'),
        const TranslationSegmentInput(id: 4, source: '我说过你们别走人'),
      ];

      final timestamps = [
        (start: 0.880, end: 4.800),
        (start: 5.120, end: 6.000),
        (start: 8.000, end: 8.640),
        (start: 10.880, end: 13.920),
      ];

      final results = await translationService.translateSegments(
        segments: soullandSegments,
        modelType: TranslationModelType.gemini25Flash,
        apiKey: geminiKey,
      );

      print('\n=== Soul Land 2 -> English Translation Results ===');
      for (final r in results) {
        print('  [ID ${r.id}]: "${soullandSegments[r.id - 1].source}" -> "${r.translation}"');
      }

      expect(results.length, soullandSegments.length);

      final List<SubtitleCue> englishCues = [];
      for (int i = 0; i < results.length; i++) {
        final t = results[i];
        final time = timestamps[i];
        englishCues.add(SubtitleCue(
          index: i + 1,
          startSeconds: time.start,
          endSeconds: time.end,
          text: SubtitleLineBreaker.formatCueText(t.translation),
        ));
      }

      final srt = SubtitleSerializer.toSrt(englishCues);
      final outputFile = File('test_samples/chinese_soulland_dialogue_30s.en.srt');
      await outputFile.writeAsString(srt);
      print('\n=== Soul Land 2 English Subtitles ===\n$srt');
    });
  });
}
