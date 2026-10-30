import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/features/providers/deepgram_provider.dart';

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

  group('Deepgram Live Integration Tests', () {
    test('validates live Deepgram API key successfully', () async {
      final provider = DeepgramNovaProvider();
      final result = await provider.validateApiKey(deepgramApiKey);

      expect(result.isValid, true);
      expect(result.errorMessage, isNull);
    });

    test('transcribes live test audio chunk with Deepgram Nova-3', () async {
      // Generate a small 3-second test MP3 using ffmpeg
      final tempAudioPath = '${Directory.systemTemp.path}/deepgram_test_sample.mp3';
      final genResult = await Process.run('ffmpeg', [
        '-f', 'lavfi',
        '-i', 'sine=frequency=440:duration=3',
        '-c:a', 'libmp3lame',
        '-b:a', '48k',
        tempAudioPath,
        '-y',
      ]);

      expect(genResult.exitCode, 0, reason: 'Failed to synthesize test audio with ffmpeg');
      expect(await File(tempAudioPath).exists(), true);

      final provider = DeepgramNovaProvider();
      final transcription = await provider.transcribeChunk(
        audioChunkPath: tempAudioPath,
        apiKey: deepgramApiKey,
      );

      expect(transcription.durationSeconds, greaterThan(0.0));

      // Clean up temp test audio
      await File(tempAudioPath).delete();
    });
  });
}
