import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/core/constants/enums.dart';
import 'package:subtitle_generator/features/providers/gemini_provider.dart';
import 'package:subtitle_generator/features/providers/groq_whisper_provider.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_cue.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_line_breaker.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_serializer.dart';
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

void main() {
  final keys = _resolveKeys();
  final groqKey = keys['GROQ_API_KEY'] ?? '';
  final geminiKey = keys['GEMINI_API_KEY'] ?? '';

  group('Live Transcriber & Translator Multi-Provider Verification', () {
    // 1. Groq Whisper Transcription Test
    test('Groq Whisper Large-v3 transcribes Japanese and Chinese dialogue chunks', () async {
      expect(groqKey.isNotEmpty, true, reason: 'Groq API key required');

      final groqProvider = GroqWhisperProvider();
      
      // A. Japanese Audio
      const jaPath = '/tmp/japanese_dialogue.mp3';
      expect(await File(jaPath).exists(), true);

      print('\n--- Testing Groq Whisper Transcriber (Japanese) ---');
      final jaResult = await groqProvider.transcribeChunk(
        audioChunkPath: jaPath,
        apiKey: groqKey,
        sourceLanguage: 'ja',
      );

      print('Japanese Detected Language: ${jaResult.detectedLanguage}');
      print('Segments Count: ${jaResult.segments.length}');
      for (final s in jaResult.segments) {
        print('  [${s.startSeconds.toStringAsFixed(2)}s - ${s.endSeconds.toStringAsFixed(2)}s]: ${s.text}');
      }
      expect(jaResult.segments.isNotEmpty, true);

      // B. Chinese Audio
      const zhPath = '/tmp/soulland_dialogue.mp3';
      expect(await File(zhPath).exists(), true);

      print('\n--- Testing Groq Whisper Transcriber (Chinese) ---');
      final zhResult = await groqProvider.transcribeChunk(
        audioChunkPath: zhPath,
        apiKey: groqKey,
        sourceLanguage: 'zh',
      );

      print('Chinese Detected Language: ${zhResult.detectedLanguage}');
      print('Segments Count: ${zhResult.segments.length}');
      for (final s in zhResult.segments) {
        print('  [${s.startSeconds.toStringAsFixed(2)}s - ${s.endSeconds.toStringAsFixed(2)}s]: ${s.text}');
      }
      expect(zhResult.segments.isNotEmpty, true);
    }, timeout: const Timeout(Duration(minutes: 2)));

    // 2. Gemini 2.5 Flash Audio Transcription Test
    test('Gemini 2.5 Flash transcribes audio chunk with timestamps', () async {
      expect(geminiKey.isNotEmpty, true, reason: 'Gemini API key required');

      final geminiProvider = GeminiProvider();
      const zhPath = '/tmp/soulland_dialogue.mp3';
      expect(await File(zhPath).exists(), true);

      print('\n--- Testing Google Gemini 2.5 Flash Transcriber (Chinese) ---');
      final geminiResult = await geminiProvider.transcribeChunk(
        audioChunkPath: zhPath,
        apiKey: geminiKey,
        sourceLanguage: 'zh',
      );

      print('Gemini Segments Count: ${geminiResult.segments.length}');
      for (final s in geminiResult.segments) {
        print('  [${s.startSeconds.toStringAsFixed(2)}s - ${s.endSeconds.toStringAsFixed(2)}s]: ${s.text}');
      }
      expect(geminiResult.segments.isNotEmpty, true);
    }, timeout: const Timeout(Duration(minutes: 2)));

    // 3. Groq Translation Pipeline (Transcribe with Groq Whisper -> Translate with Groq)
    test('End-to-End Pipeline: Groq Whisper transcribe -> Groq translate to English SRT', () async {
      expect(groqKey.isNotEmpty, true);

      final groqProvider = GroqWhisperProvider();
      final translationService = TranslationService();

      print('\n--- Testing Groq End-to-End (Whisper -> Groq Translation) ---');
      // Step A: Transcribe Chinese audio
      final zhResult = await groqProvider.transcribeChunk(
        audioChunkPath: '/tmp/soulland_dialogue.mp3',
        apiKey: groqKey,
        sourceLanguage: 'zh',
      );

      final translationInputs = zhResult.segments
          .map((s) => TranslationSegmentInput(id: s.index + 1, source: s.text))
          .toList();

      // Step B: Translate with Groq
      final translatedOutputs = await translationService.translateSegments(
        segments: translationInputs,
        modelType: TranslationModelType.groqLlama3370b,
        apiKey: groqKey,
      );

      print('\n=== Groq Translated Output ===');
      for (final t in translatedOutputs) {
        print('  [ID ${t.id}]: "${translationInputs[t.id - 1].source}" -> "${t.translation}"');
      }

      // Step C: Format into final SRT
      final List<SubtitleCue> cues = [];
      for (int i = 0; i < translatedOutputs.length; i++) {
        final t = translatedOutputs[i];
        final s = zhResult.segments[i];
        cues.add(SubtitleCue(
          index: i + 1,
          startSeconds: s.startSeconds,
          endSeconds: s.endSeconds,
          text: SubtitleLineBreaker.formatCueText(t.translation),
        ));
      }

      final srtOutput = SubtitleSerializer.toSrt(cues);
      print('\n=== Final Groq English SRT ===\n$srtOutput');

      final srtFile = File('test_samples/groq_pipeline_soulland.en.srt');
      await srtFile.writeAsString(srtOutput);
      expect(await srtFile.exists(), true);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
