import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'transcription_provider.dart';

class GeminiProvider implements BaseTranscriptionProvider {
  final Dio _dio;

  GeminiProvider([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 60),
              ),
            );

  @override
  String get name => 'Google Gemini Flash';

  @override
  String get modelId => _activeModelId;

  static const List<String> _candidateModels = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-001',
    'gemini-1.5-flash-002',
    'gemini-2.0-flash',
    'gemini-2.0-flash-exp',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
  ];

  String _activeModelId = 'gemini-1.5-flash';
  static List<String>? _cachedDiscoveredModels;
  static DateTime? _lastDiscoveryTime;

  String _formatDioError(DioException e, [String? model]) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final prefix = model != null ? 'Gemini ($model): ' : 'Gemini: ';
    if (data != null) {
      if (data is Map && data['error'] != null) {
        final err = data['error'];
        if (err is Map && err['message'] != null) {
          return '$prefix${err['message']} (HTTP $status)';
        }
        return '$prefix$err (HTTP $status)';
      }
      return '$prefix$data (HTTP $status)';
    }
    return '$prefix${e.message ?? 'Unknown error'} (HTTP $status)';
  }

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
        options: Options(
          headers: {'x-goog-api-key': cleanKey},
          validateStatus: (status) => true,
        ),
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
                  '5. Provide accurate start and end timestamps in seconds (e.g. 12.35). Timestamps MUST strictly reflect real-time playback from 0.0 to the end of this audio chunk without drifting or stretching.\n'
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

    // Query Google to discover the exact models available for this API key (cached for 30m)
    List<String> discoveredModels = [];
    final cacheValid = _cachedDiscoveredModels != null &&
        _lastDiscoveryTime != null &&
        DateTime.now().difference(_lastDiscoveryTime!) < const Duration(minutes: 30);

    if (cacheValid) {
      discoveredModels = List<String>.from(_cachedDiscoveredModels!);
    } else {
      try {
        final listRes = await _dio.get(
          'https://generativelanguage.googleapis.com/v1beta/models',
          queryParameters: {'key': apiKey.trim()},
          options: Options(
            headers: {'x-goog-api-key': apiKey.trim()},
            validateStatus: (status) => true,
          ),
        );

        if (listRes.statusCode == 200 && listRes.data is Map) {
          final modelsList = (listRes.data['models'] as List<dynamic>?) ?? [];
          for (final m in modelsList) {
            final methods = (m['supportedGenerationMethods'] as List<dynamic>?) ?? [];
            if (methods.contains('generateContent')) {
              final rawName = (m['name'] as String? ?? '').replaceFirst('models/', '');
              // Filter out non-audio/text models: tts, embedding, imagen, aot, robotics
              final lower = rawName.toLowerCase();
              if (rawName.isEmpty ||
                  lower.contains('tts') ||
                  lower.contains('embedding') ||
                  lower.contains('imagen') ||
                  lower.contains('robotics')) {
                continue;
              }
              discoveredModels.add(rawName);
            }
          }
          if (discoveredModels.isNotEmpty) {
            _cachedDiscoveredModels = List<String>.from(discoveredModels);
            _lastDiscoveryTime = DateTime.now();
          }
        }
      } catch (_) {}
    }

    // Build the ordered model list: prioritize verified active model, then discovered models, then candidates
    final Set<String> combined = {};
    if (_activeModelId.isNotEmpty) {
      combined.add(_activeModelId);
    }
    if (discoveredModels.isNotEmpty) {
      // Prioritize standard flash models first (gemini-1.5-flash, gemini-2.0-flash, gemini-2.5-flash),
      // then any other general models, strictly excluding tts
      final flashModels = discoveredModels.where((m) {
        final l = m.toLowerCase();
        return l.contains('flash') && !l.contains('tts');
      }).toList();
      final otherModels = discoveredModels.where((m) {
        final l = m.toLowerCase();
        return !l.contains('flash') && !l.contains('tts');
      }).toList();
      combined.addAll(flashModels);
      combined.addAll(otherModels);
    }
    combined.addAll(_candidateModels);

    final modelsToTry = combined.toList();

    DioException? lastDioException;
    String? lastErrorMessage;

    for (final model in modelsToTry) {
      for (final apiVersion in ['v1beta', 'v1']) {
        try {
          final response = await _dio.post(
            'https://generativelanguage.googleapis.com/$apiVersion/models/$model:generateContent',
            queryParameters: {'key': apiKey.trim()},
            data: payload,
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey.trim(),
              },
            ),
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
          final errStr = _formatDioError(e, model);
          // If 404 (not found) or 503 (overloaded) or 429 (rate limited)
          // or 400 (modality not supported / unsupported model), try next model/version
          if (status == 404 ||
              status == 503 ||
              status == 429 ||
              (status == 400 &&
                  (errStr.toLowerCase().contains('modality') ||
                      errStr.toLowerCase().contains('not enabled') ||
                      errStr.toLowerCase().contains('not supported')))) {
            continue;
          }
          throw TranscriptionException(
            provider: name,
            statusCode: e.response?.statusCode,
            message: errStr,
          );
        }
      }
    }

    if (lastDioException != null) {
      final detail = discoveredModels.isEmpty
          ? 'No models supporting generateContent found for this API key. Verify that Generative Language API is enabled in Google AI Studio.'
          : 'Discovered models for your key: ${discoveredModels.take(4).join(", ")}.';
      throw TranscriptionException(
        provider: name,
        statusCode: lastDioException.response?.statusCode,
        message: '${_formatDioError(lastDioException, _activeModelId)}\n$detail',
      );
    }

    throw TranscriptionException(
      provider: name,
      message: lastErrorMessage ?? 'All Gemini models failed',
    );
  }
}

