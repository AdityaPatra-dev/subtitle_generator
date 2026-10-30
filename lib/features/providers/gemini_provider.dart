import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'transcription_provider.dart';

class GeminiProvider implements BaseTranscriptionProvider {
  final Dio _dio;

  GeminiProvider([Dio? dio]) : _dio = dio ?? Dio();

  @override
  String get name => 'Google Gemini 2.5 Flash';

  @override
  String get modelId => 'gemini-2.5-flash';

  @override
  Future<ProviderValidationResult> validateApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return ProviderValidationResult.failure('API key cannot be empty');
    }

    try {
      final response = await _dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models',
        queryParameters: {'key': cleanKey},
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        return ProviderValidationResult.success();
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        return ProviderValidationResult.failure('Invalid Google Gemini API key');
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

    final bytes = await file.readAsBytes();
    final base64Audio = base64Encode(bytes);

    final langPrompt = (sourceLanguage != null && sourceLanguage.isNotEmpty)
        ? 'Spoken language is $sourceLanguage.'
        : 'Detect spoken language automatically.';

    final payload = {
      'contents': [
        {
          'parts': [
            {
              'text': 'Transcribe this audio accurately. $langPrompt '
                  'Provide precise start and end timestamps in seconds for every spoken segment. '
                  'Do not omit any dialogue.',
            },
            {
              'inlineData': {
                'mimeType': 'audio/mp3',
                'data': base64Audio,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'start': {'type': 'NUMBER'},
              'end': {'type': 'NUMBER'},
              'text': {'type': 'STRING'}
            },
            'required': ['start', 'end', 'text']
          }
        }
      }
    };

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent',
        queryParameters: {'key': apiKey.trim()},
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final candidates = (data['candidates'] as List<dynamic>?) ?? [];
        if (candidates.isEmpty) {
          return const TranscriptionResult(segments: [], durationSeconds: 0.0);
        }

        final content = candidates.first['content'] as Map<String, dynamic>? ?? {};
        final parts = (content['parts'] as List<dynamic>?) ?? [];
        if (parts.isEmpty) {
          return const TranscriptionResult(segments: [], durationSeconds: 0.0);
        }

        final rawJsonStr = parts.first['text']?.toString() ?? '[]';
        final List<dynamic> parsedList = jsonDecode(rawJsonStr) as List<dynamic>;

        final List<TranscriptionSegment> segments = [];
        double maxEnd = 0.0;

        for (int i = 0; i < parsedList.length; i++) {
          final item = parsedList[i] as Map<String, dynamic>;
          final start = double.tryParse(item['start']?.toString() ?? '0.0') ?? 0.0;
          final end = double.tryParse(item['end']?.toString() ?? '0.0') ?? 0.0;
          final text = item['text']?.toString().trim() ?? '';

          if (end > maxEnd) maxEnd = end;

          if (text.isNotEmpty) {
            segments.add(TranscriptionSegment(
              index: i,
              startSeconds: start,
              endSeconds: end,
              text: text,
            ));
          }
        }

        return TranscriptionResult(
          segments: segments,
          durationSeconds: maxEnd,
        );
      } else {
        throw TranscriptionException(
          provider: name,
          statusCode: response.statusCode,
          message: 'Gemini API error: ${response.data}',
        );
      }
    } on DioException catch (e) {
      throw TranscriptionException(
        provider: name,
        statusCode: e.response?.statusCode,
        message: e.message ?? 'Network error connecting to Gemini',
      );
    }
  }
}

