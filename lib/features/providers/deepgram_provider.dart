import 'dart:io';
import 'package:dio/dio.dart';
import 'transcription_provider.dart';

class DeepgramNovaProvider implements BaseTranscriptionProvider {
  final Dio _dio;

  DeepgramNovaProvider([Dio? dio]) : _dio = dio ?? Dio();

  @override
  String get name => 'Deepgram Nova-3 Multilingual';

  @override
  String get modelId => 'nova-3';

  @override
  Future<ProviderValidationResult> validateApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return ProviderValidationResult.failure('API key cannot be empty');
    }

    try {
      final response = await _dio.get(
        'https://api.deepgram.com/v1/projects',
        options: Options(
          headers: {'Authorization': 'Token $cleanKey'},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        return ProviderValidationResult.success();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return ProviderValidationResult.failure('Invalid Deepgram API key (Unauthorized)');
      } else {
        return ProviderValidationResult.failure('Validation failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ProviderValidationResult.failure('Connection error: $e');
    }
  }

  @override
  Future<TranscriptionResult> transcribeChunk({
    required String audioChunkPath,
    required String apiKey,
    String? sourceLanguage,
  }) async {
    final file = File(audioChunkPath);
    if (!await file.exists()) {
      throw TranscriptionException(provider: name, message: 'Audio chunk file not found: $audioChunkPath');
    }

    final normalizedLang = (sourceLanguage?.startsWith('zh') == true) ? 'zh' : sourceLanguage;

    final queryParams = <String, dynamic>{
      'model': modelId,
      'smart_format': 'true',
      'utterances': 'true',
      'punctuate': 'true',
      if (normalizedLang != null && normalizedLang.isNotEmpty) 'language': normalizedLang,
    };

    try {
      final fileLength = await file.length();
      final response = await _dio.post(
        'https://api.deepgram.com/v1/listen',
        queryParameters: queryParams,
        data: file.openRead(),
        options: Options(
          headers: {
            'Authorization': 'Token ${apiKey.trim()}',
            'Content-Type': 'audio/mp3',
            'Content-Length': fileLength,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as Map<String, dynamic>? ?? {};
        final utterances = (results['utterances'] as List<dynamic>?) ?? [];

        final List<TranscriptionSegment> segments = [];

        if (utterances.isNotEmpty) {
          for (int i = 0; i < utterances.length; i++) {
            final u = utterances[i] as Map<String, dynamic>;
            final start = double.tryParse(u['start']?.toString() ?? '0.0') ?? 0.0;
            final end = double.tryParse(u['end']?.toString() ?? '0.0') ?? 0.0;
            final transcript = u['transcript']?.toString().trim() ?? '';
            final confidence = double.tryParse(u['confidence']?.toString() ?? '');
            final speaker = u['speaker']?.toString();

            if (transcript.isNotEmpty) {
              segments.add(TranscriptionSegment(
                index: i,
                startSeconds: start,
                endSeconds: end,
                text: transcript,
                speakerTag: speaker != null ? 'spk_$speaker' : null,
                confidence: confidence,
              ));
            }
          }
        } else {
          // Fallback to alternatives
          final channels = (results['channels'] as List<dynamic>?) ?? [];
          if (channels.isNotEmpty) {
            final alts = (channels.first['alternatives'] as List<dynamic>?) ?? [];
            if (alts.isNotEmpty) {
              final words = (alts.first['words'] as List<dynamic>?) ?? [];
              final fullText = alts.first['transcript']?.toString().trim() ?? '';
              if (words.isNotEmpty && fullText.isNotEmpty) {
                final start = double.tryParse(words.first['start']?.toString() ?? '0.0') ?? 0.0;
                final end = double.tryParse(words.last['end']?.toString() ?? '0.0') ?? 0.0;
                segments.add(TranscriptionSegment(
                  index: 0,
                  startSeconds: start,
                  endSeconds: end,
                  text: fullText,
                ));
              }
            }
          }
        }

        final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
        final durationSec = double.tryParse(metadata['duration']?.toString() ?? '0.0') ?? 0.0;

        return TranscriptionResult(
          segments: segments,
          durationSeconds: durationSec,
        );
      } else {
        throw TranscriptionException(
          provider: name,
          statusCode: response.statusCode,
          message: 'Deepgram API error: ${response.data}',
        );
      }
    } on DioException catch (e) {
      throw TranscriptionException(
        provider: name,
        statusCode: e.response?.statusCode,
        message: e.message ?? 'Network error connecting to Deepgram',
      );
    }
  }
}

