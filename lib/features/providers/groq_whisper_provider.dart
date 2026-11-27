import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'transcription_provider.dart';

class GroqWhisperProvider implements BaseTranscriptionProvider {
  final Dio _dio;

  GroqWhisperProvider([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 60),
              ),
            );

  @override
  String get name => 'Groq Whisper Large-v3';

  @override
  String get modelId => 'whisper-large-v3';

  @override
  Future<ProviderValidationResult> validateApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return ProviderValidationResult.failure('API key cannot be empty');
    }

    try {
      final response = await _dio.get(
        'https://api.groq.com/openai/v1/models',
        options: Options(
          headers: {'Authorization': 'Bearer $cleanKey'},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        return ProviderValidationResult.success();
      } else if (response.statusCode == 401) {
        return ProviderValidationResult.failure('Invalid Groq API key (Unauthorized)');
      } else {
        return ProviderValidationResult.failure('Validation failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ProviderValidationResult.failure('Connection error: $e');
    }
  }

  static String normalizeWhisperLanguage(String? lang) {
    if (lang == null || lang.isEmpty) return '';
    final lower = lang.toLowerCase().trim();
    if (lower.startsWith('zh')) return 'zh';
    if (lower.startsWith('ja')) return 'ja';
    if (lower.startsWith('ko')) return 'ko';
    if (lower.startsWith('es')) return 'es';
    if (lower.startsWith('fr')) return 'fr';
    if (lower.startsWith('de')) return 'de';
    if (lower.startsWith('en')) return 'en';
    if (lower.contains('-')) return lower.split('-').first;
    return lower;
  }

  static final RegExp _hallucinationRegex = RegExp(
    r'(ご視聴ありがとうございました|チャンネル登録|お楽しみください|ご覧いただき|'
    r'全片以.*拍摄|請按下小鈴鐺|请按下小铃铛|點讚|点赞|訂閱|订阅|謝謝觀看|谢谢观看|謝謝大家|谢谢大家|'
    r'thank you for watching|thanks for watching|please subscribe|subtitles by|'
    r'sound effects are not only)',
    caseSensitive: false,
  );

  /// Whisper's prompt is NOT an LLM instruction prompt.
  /// Passing instruction sentences (e.g. "Transcribe dialogue...") corrupts Whisper's
  /// acoustic decoding and causes it to hallucinate and drop real speech.
  static String? sanitizeWhisperPrompt(String? prompt) {
    if (prompt == null || prompt.trim().isEmpty) return null;
    final lower = prompt.toLowerCase();
    if (lower.contains('transcribe') ||
        lower.contains('accurately') ||
        lower.contains('shouting') ||
        lower.contains('spoken dialogue') ||
        lower.contains('background music') ||
        lower.contains('action phrases') ||
        prompt.split(' ').length > 10) {
      return null;
    }
    return prompt.trim();
  }

  static bool _isWhisperHallucination(Map<String, dynamic> seg) {
    final text = seg['text']?.toString().trim() ?? '';
    if (text.isEmpty) return true;

    final noSpeechProb = double.tryParse(seg['no_speech_prob']?.toString() ?? '0.0') ?? 0.0;
    final compressionRatio = double.tryParse(seg['compression_ratio']?.toString() ?? '0.0') ?? 0.0;
    final start = double.tryParse(seg['start']?.toString() ?? '0.0') ?? 0.0;
    final end = double.tryParse(seg['end']?.toString() ?? '0.0') ?? 0.0;
    final duration = end - start;

    // Repetitive decode loops
    if (compressionRatio > 2.4) return true;

    // High no-speech probability
    if (noSpeechProb > 0.85) return true;

    // Matches known YouTube/silence boilerplate
    if (_hallucinationRegex.hasMatch(text)) {
      if (noSpeechProb > 0.3 || duration > 8.0) return true;
    }

    // Long silence stretched into a single short phrase
    if (duration > 20.0 && noSpeechProb > 0.6) return true;

    return false;
  }

  @override
  Future<TranscriptionResult> transcribeChunk({
    required String audioChunkPath,
    required String apiKey,
    String? sourceLanguage,
    String? prompt,
    double? chunkDurationSeconds,
  }) async {
    final file = File(audioChunkPath);
    if (!await file.exists()) {
      throw TranscriptionException(provider: name, message: 'Audio chunk file not found: $audioChunkPath');
    }

    final normalizedLang = normalizeWhisperLanguage(sourceLanguage);
    final cleanPrompt = sanitizeWhisperPrompt(prompt);

    int attempts = 0;
    const int maxAttempts = 4;
    Duration backoff = const Duration(seconds: 2);

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            audioChunkPath,
            filename: 'chunk.mp3',
            contentType: MediaType('audio', 'mpeg'),
          ),
          'model': modelId,
          'response_format': 'verbose_json',
          'temperature': '0.0',
          if (normalizedLang.isNotEmpty) 'language': normalizedLang,
          if (cleanPrompt != null && cleanPrompt.isNotEmpty) 'prompt': cleanPrompt,
        });

        final response = await _dio.post(
          'https://api.groq.com/openai/v1/audio/transcriptions',
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final rawSegments = (data['segments'] as List<dynamic>?) ?? [];
          final detectedLang = data['language']?.toString();
          final durationSec = double.tryParse(data['duration']?.toString() ?? '0.0') ?? 0.0;

          final List<TranscriptionSegment> segments = [];
          int validIndex = 0;
          for (int i = 0; i < rawSegments.length; i++) {
            final seg = rawSegments[i] as Map<String, dynamic>;
            if (_isWhisperHallucination(seg)) {
              continue;
            }
            final start = double.tryParse(seg['start']?.toString() ?? '0.0') ?? 0.0;
            final end = double.tryParse(seg['end']?.toString() ?? '0.0') ?? 0.0;
            final text = seg['text']?.toString().trim() ?? '';

            if (text.isNotEmpty) {
              segments.add(TranscriptionSegment(
                index: validIndex++,
                startSeconds: start,
                endSeconds: end,
                text: text,
              ));
            }
          }

          return TranscriptionResult(
            segments: segments,
            detectedLanguage: detectedLang,
            durationSeconds: durationSec,
          );
        } else if (response.statusCode == 429) {
          if (attempts >= maxAttempts) {
            throw TranscriptionException(
              provider: name,
              statusCode: 429,
              message: 'Rate limit exceeded (HTTP 429). Please wait before retrying.',
            );
          }
          await Future.delayed(backoff);
          backoff *= 2;
          continue;
        } else {
          throw TranscriptionException(
            provider: name,
            statusCode: response.statusCode,
            message: 'Groq API error: ${response.data}',
          );
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 429 && attempts < maxAttempts) {
          await Future.delayed(backoff);
          backoff *= 2;
          continue;
        }
        throw TranscriptionException(
          provider: name,
          statusCode: e.response?.statusCode,
          message: e.message ?? 'Network error connecting to Groq',
        );
      }
    }

    throw TranscriptionException(provider: name, message: 'Max retries exhausted');
  }
}

