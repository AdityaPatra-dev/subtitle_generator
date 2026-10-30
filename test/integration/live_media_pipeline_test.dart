import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/features/media/media_engine.dart';
import 'package:subtitle_generator/features/media/process_media_engine.dart';
import 'package:subtitle_generator/features/providers/deepgram_provider.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_cue.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_line_breaker.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_serializer.dart';

String _resolveDeepgramApiKey() {
  if (Platform.environment.containsKey('DEEPGRAM_API_KEY')) {
    return Platform.environment['DEEPGRAM_API_KEY']!;
  }
  final envFile = File('.env.development');
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      if (line.startsWith('DEEPGRAM_API_KEY=')) {
        return line.substring('DEEPGRAM_API_KEY='.length).trim();
      }
    }
  }
  return const String.fromEnvironment('DEEPGRAM_API_KEY');
}

void main() {
  final deepgramApiKey = _resolveDeepgramApiKey();
  const mediaEngine = ProcessMediaEngine();

  group('Live Media Pipeline Tests on Trimmed Video Samples', () {
    test('Japanese 45s sample from 2+ hr video (HUNTC-432): extract + Deepgram Nova-3 transcribe + SRT', () async {
      const samplePath = 'test_samples/japanese_huntc_45s.mp4';
      expect(await File(samplePath).exists(), true, reason: 'Sample video not found');

      // 1. Probe media
      final mediaInfo = await mediaEngine.probe(samplePath);
      expect(mediaInfo.audioTracks.isNotEmpty, true);
      final audioStreamIndex = mediaInfo.primaryAudioTrack!.streamIndex;

      // 2. Extract audio (16kHz mono, EBU R128 loudness normalization)
      final tempAudioPath = '${Directory.systemTemp.path}/test_japanese_huntc.mp3';
      final extractResult = await mediaEngine.extractAudio(
        inputPath: samplePath,
        outputPath: tempAudioPath,
        audioStreamIndex: audioStreamIndex,
        config: const AudioExtractionConfig(),
      );

      expect(extractResult.fileSizeBytes, greaterThan(0));
      expect(await File(tempAudioPath).exists(), true);

      // 3. Transcribe with Deepgram Nova-3 (Japanese)
      final provider = DeepgramNovaProvider();
      final transcription = await provider.transcribeChunk(
        audioChunkPath: tempAudioPath,
        apiKey: deepgramApiKey,
        sourceLanguage: 'ja',
      );

      print('\n=== Japanese HUNTC-432 Transcript Result ===');
      print('Duration: ${transcription.durationSeconds.toStringAsFixed(2)}s');
      print('Detected segments count: ${transcription.segments.length}');
      for (final seg in transcription.segments) {
        print('  [${seg.startSeconds.toStringAsFixed(2)}s - ${seg.endSeconds.toStringAsFixed(2)}s]: ${seg.text}');
      }

      expect(transcription.segments.isNotEmpty, true, reason: 'Expected spoken segments in dialogue section');

      // 4. Generate SRT & VTT
      final List<SubtitleCue> cues = [];
      for (int i = 0; i < transcription.segments.length; i++) {
        final s = transcription.segments[i];
        cues.add(SubtitleCue(
          index: i + 1,
          startSeconds: s.startSeconds,
          endSeconds: s.endSeconds,
          text: SubtitleLineBreaker.formatCueText(s.text),
        ));
      }

      final srtOutput = SubtitleSerializer.toSrt(cues);
      final vttOutput = SubtitleSerializer.toVtt(cues, title: 'HUNTC-432 Japanese Sample');

      final srtFile = File('test_samples/japanese_huntc_45s.srt');
      await srtFile.writeAsString(srtOutput);

      final vttFile = File('test_samples/japanese_huntc_45s.vtt');
      await vttFile.writeAsString(vttOutput);

      print('\n=== Generated SRT Preview ===\n$srtOutput');

      expect(await srtFile.exists(), true);
      expect(await vttFile.exists(), true);

      // Clean up temp extracted mp3
      await File(tempAudioPath).delete();
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Japanese 45s sample (Solo Leveling): extract + Deepgram Nova-3 transcribe + SRT', () async {
      const samplePath = 'test_samples/japanese_solo_leveling_45s.mp4';
      expect(await File(samplePath).exists(), true);

      final mediaInfo = await mediaEngine.probe(samplePath);
      final audioStreamIndex = mediaInfo.primaryAudioTrack!.streamIndex;

      final tempAudioPath = '${Directory.systemTemp.path}/test_solo_leveling.mp3';
      await mediaEngine.extractAudio(
        inputPath: samplePath,
        outputPath: tempAudioPath,
        audioStreamIndex: audioStreamIndex,
        config: const AudioExtractionConfig(),
      );

      final provider = DeepgramNovaProvider();
      final transcription = await provider.transcribeChunk(
        audioChunkPath: tempAudioPath,
        apiKey: deepgramApiKey,
        sourceLanguage: 'ja',
      );

      print('\n=== Japanese Solo Leveling Transcript Result ===');
      print('Detected segments count: ${transcription.segments.length}');
      for (final seg in transcription.segments) {
        print('  [${seg.startSeconds.toStringAsFixed(2)}s - ${seg.endSeconds.toStringAsFixed(2)}s]: ${seg.text}');
      }

      final List<SubtitleCue> cues = [];
      for (int i = 0; i < transcription.segments.length; i++) {
        final s = transcription.segments[i];
        cues.add(SubtitleCue(
          index: i + 1,
          startSeconds: s.startSeconds,
          endSeconds: s.endSeconds,
          text: SubtitleLineBreaker.formatCueText(s.text),
        ));
      }

      final srtOutput = SubtitleSerializer.toSrt(cues);
      final srtFile = File('test_samples/japanese_solo_leveling_45s.srt');
      await srtFile.writeAsString(srtOutput);

      print('\n=== Generated SRT Preview ===\n$srtOutput');

      await File(tempAudioPath).delete();
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Chinese 30s dialogue sample (Soul Land 2): extract + Deepgram Nova-3 transcribe + SRT', () async {
      const samplePath = 'test_samples/chinese_soulland_dialogue_30s.mp4';
      expect(await File(samplePath).exists(), true);

      final mediaInfo = await mediaEngine.probe(samplePath);
      final audioStreamIndex = mediaInfo.primaryAudioTrack!.streamIndex;

      final tempAudioPath = '${Directory.systemTemp.path}/test_soulland_dialogue.mp3';
      await mediaEngine.extractAudio(
        inputPath: samplePath,
        outputPath: tempAudioPath,
        audioStreamIndex: audioStreamIndex,
        config: const AudioExtractionConfig(),
      );

      final provider = DeepgramNovaProvider();
      final transcription = await provider.transcribeChunk(
        audioChunkPath: tempAudioPath,
        apiKey: deepgramApiKey,
        sourceLanguage: 'zh',
      );

      print('\n=== Chinese Soul Land 2 Transcript Result ===');
      print('Duration: ${transcription.durationSeconds.toStringAsFixed(2)}s');
      print('Detected segments count: ${transcription.segments.length}');
      for (final seg in transcription.segments) {
        print('  [${seg.startSeconds.toStringAsFixed(2)}s - ${seg.endSeconds.toStringAsFixed(2)}s]: ${seg.text}');
      }

      expect(transcription.segments.isNotEmpty, true, reason: 'Expected Chinese spoken dialogue');

      final List<SubtitleCue> cues = [];
      for (int i = 0; i < transcription.segments.length; i++) {
        final s = transcription.segments[i];
        cues.add(SubtitleCue(
          index: i + 1,
          startSeconds: s.startSeconds,
          endSeconds: s.endSeconds,
          text: SubtitleLineBreaker.formatCueText(s.text),
        ));
      }

      final srtOutput = SubtitleSerializer.toSrt(cues);
      final srtFile = File('test_samples/chinese_soulland_dialogue_30s.srt');
      await srtFile.writeAsString(srtOutput);

      print('\n=== Generated SRT Preview ===\n$srtOutput');

      await File(tempAudioPath).delete();
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Chinese 30s dialogue sample (Battle Through The Heavens): extract + Deepgram Nova-3 transcribe + SRT', () async {
      const samplePath = 'test_samples/chinese_btth_dialogue_30s.mp4';
      expect(await File(samplePath).exists(), true);

      final mediaInfo = await mediaEngine.probe(samplePath);
      final audioStreamIndex = mediaInfo.primaryAudioTrack!.streamIndex;

      final tempAudioPath = '${Directory.systemTemp.path}/test_btth_dialogue.mp3';
      await mediaEngine.extractAudio(
        inputPath: samplePath,
        outputPath: tempAudioPath,
        audioStreamIndex: audioStreamIndex,
        config: const AudioExtractionConfig(),
      );

      final provider = DeepgramNovaProvider();
      final transcription = await provider.transcribeChunk(
        audioChunkPath: tempAudioPath,
        apiKey: deepgramApiKey,
        sourceLanguage: 'zh',
      );

      print('\n=== Chinese BTTH Transcript Result ===');
      print('Duration: ${transcription.durationSeconds.toStringAsFixed(2)}s');
      print('Detected segments count: ${transcription.segments.length}');
      for (final seg in transcription.segments) {
        print('  [${seg.startSeconds.toStringAsFixed(2)}s - ${seg.endSeconds.toStringAsFixed(2)}s]: ${seg.text}');
      }

      expect(transcription.segments.isNotEmpty, true, reason: 'Expected Chinese spoken dialogue');

      final List<SubtitleCue> cues = [];
      for (int i = 0; i < transcription.segments.length; i++) {
        final s = transcription.segments[i];
        cues.add(SubtitleCue(
          index: i + 1,
          startSeconds: s.startSeconds,
          endSeconds: s.endSeconds,
          text: SubtitleLineBreaker.formatCueText(s.text),
        ));
      }

      final srtOutput = SubtitleSerializer.toSrt(cues);
      final srtFile = File('test_samples/chinese_btth_dialogue_30s.srt');
      await srtFile.writeAsString(srtOutput);

      print('\n=== Generated SRT Preview ===\n$srtOutput');

      await File(tempAudioPath).delete();
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
