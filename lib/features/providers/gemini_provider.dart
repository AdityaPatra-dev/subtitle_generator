import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'transcription_provider.dart';

class GeminiProvider implements BaseTranscriptionProvider {
  final Dio _dio;

  GeminiProvider([Dio? dio]) : _dio = dio ?? Dio();

  @override
  String get name => 'Google Gemini Flash';

  @override
  String get modelId => _activeModelId;

  static const List<String> _candidateModels = [
    'gemini-3-flash-preview',
    'gemini-3.5-flash',
    'gemini-flash-latest',
    'gemini-2.5-flash',
  ];

  String _activeModelId = 'gemini-3-flash-preview';

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
    String? prompt,
  }) async {
    final file = File(audioChunkPath);
    if (!await file.exists()) {
      throw TranscriptionException(provider: name, message: 'Audio chunk file not found: $audioChunkPath');
    }

    final bytes = await file.readAsBytes();
    final base64Audio = base64Encode(bytes);

    final langPrompt = (sourceLanguage != null && sourceLanguage.isNotEmpty)
        ? 'The audio spoken language is $sourceLanguage.'
        : 'Detect the spoken language automatically.';

    final extraAcousticDirective = (prompt != null && prompt.isNotEmpty)
        ? '\nDOMAIN & ACOUSTIC DIRECTIVE: $prompt\nMANDATORY: Capture ALL speech, shouting during intense combat or explosions, whispered lines, and synthesized, robotic, computerized, metallic, or demonic villain voices. Never discard distorted character speech as background noise.'
        : '';

    final payload = {
      'contents': [
        {
          'parts': [
            {
              'text': 'You are a professional video subtitler. Transcribe this audio accurately into short, natural subtitle cues conforming strictly to standard subtitling rules. $langPrompt$extraAcousticDirective\n'
                  'MANDATORY SUBTITLING RULES:\n'
                  '1. Each subtitle cue MUST be short (typically 2.0 to 5.0 seconds, maximum 6.5 seconds).\n'
                  '2. NEVER combine long speeches, paragraphs, or multiple unrelated sentences into a single cue.\n'
                  '3. Break cues naturally at sentence boundaries, pauses, or breath marks.\n'
                  '4. Each cue text must be concise (max 40 characters per line, at most 2 lines).\n'
                  '5. Provide accurate start and end timestamps in seconds (e.g. 12.35).\n'
                  '6. Capture all dialogue faithfully with zero hallucination.',
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

    final modelsToTry = [
      _activeModelId,
      ..._candidateModels.where((m) => m != _activeModelId),
    ];

    DioException? lastDioException;
    String? lastErrorMessage;

    for (final model in modelsToTry) {
      try {
        final response = await _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          queryParameters: {'key': apiKey.trim()},
          data: payload,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200) {
          _activeModelId = model;
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
          lastErrorMessage = 'Gemini API error ($model): ${response.data}';
        }
      } on DioException catch (e) {
        lastDioException = e;
        final status = e.response?.statusCode;
        // If 404 (model not found / deprecated) or 503 (model overloaded), try next model
        if (status == 404 || status == 503) {
          continue;
        }
        throw TranscriptionException(
          provider: name,
          statusCode: e.response?.statusCode,
          message: e.message ?? 'Network error connecting to Gemini ($model)',
        );
      }
    }

    if (lastDioException != null) {
      throw TranscriptionException(
        provider: name,
        statusCode: lastDioException.response?.statusCode,
        message: lastDioException.message ?? 'All Gemini models exhausted',
      );
    }

    throw TranscriptionException(
      provider: name,
      message: lastErrorMessage ?? 'All Gemini models failed',
    );
  }
}

