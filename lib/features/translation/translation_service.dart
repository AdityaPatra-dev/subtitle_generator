import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/enums.dart';

class TranslationSegmentInput {
  final int id;
  final String source;

  const TranslationSegmentInput({required this.id, required this.source});

  Map<String, dynamic> toJson() => {'id': id, 'source': source};
}

class TranslationSegmentOutput {
  final int id;
  final String translation;

  const TranslationSegmentOutput({required this.id, required this.translation});

  factory TranslationSegmentOutput.fromJson(Map<String, dynamic> json) {
    return TranslationSegmentOutput(
      id: json['id'] as int,
      translation: json['translation']?.toString().trim() ?? '',
    );
  }
}

class TranslationService {
  final Dio _dio;

  TranslationService([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                sendTimeout: const Duration(seconds: 60),
              ),
            );

  static String buildSystemPrompt(String targetLanguage, {bool isCjk = false, bool isRtl = false}) {
    final maxChars = isCjk ? '18-20 characters per line' : '40-42 characters per line';
    final rtlNote = isRtl ? '\n7. The target language is written Right-to-Left (RTL). Ensure appropriate punctuation and phrasing.' : '';
    return '''
You are a professional audiovisual subtitle translator.
Your task is to translate an array of subtitle segments into natural, idiomatic $targetLanguage subtitles following standard broadcasting guidelines (Netflix and BBC standards).

RULES:
1. Maintain exact 1:1 segment mapping. Input contains N segments; output MUST contain exactly N segments with matching "id" values.
2. Never invent, hallucinate, or alter timestamps. You only provide the "translation" text.
3. Keep translations concise and readable within standard subtitle reading speeds (under $maxChars, at most 2 lines).
4. Preserve proper character names, cultivation realm terms, martial arts techniques, and cultural terms naturally.
5. If a segment contains non-speech indicators like [Music], [Laughter], or (Applause), translate or preserve the bracketed notation cleanly.
6. Return strictly valid JSON adhering to the provided schema with NO conversational chatter or markdown fences.$rtlNote
''';
  }

  /// Translates a full list of segments in batches of 60 to 80 segments
  Future<List<TranslationSegmentOutput>> translateSegments({
    required List<TranslationSegmentInput> segments,
    required TranslationModelType modelType,
    required String apiKey,
    TargetLanguage targetLanguage = TargetLanguage.en,
    int batchSize = 70,
  }) async {
    if (segments.isEmpty || modelType == TranslationModelType.none) {
      return segments
          .map((s) => TranslationSegmentOutput(id: s.id, translation: s.source))
          .toList();
    }

    final systemPrompt = buildSystemPrompt(
      targetLanguage.displayName,
      isCjk: targetLanguage.isCjk,
      isRtl: targetLanguage.isRtl,
    );

    final List<TranslationSegmentOutput> allResults = [];
    String previousContext = '';

    int effectiveBatchSize = batchSize;
    if (modelType == TranslationModelType.groqLlama3370b && effectiveBatchSize > 25) {
      // Groq free tier has an 8,000 TPM limit; use smaller batches of 25 segments
      effectiveBatchSize = 25;
    }

    for (int i = 0; i < segments.length; i += effectiveBatchSize) {
      final batch = segments.sublist(i, (i + effectiveBatchSize > segments.length) ? segments.length : i + effectiveBatchSize);
      final batchIds = batch.map((s) => s.id).toList();

      final batchOutputs = await _translateBatchWithRetry(
        batch: batch,
        batchIds: batchIds,
        modelType: modelType,
        apiKey: apiKey,
        previousContext: previousContext,
        systemPrompt: systemPrompt,
        targetLanguageName: targetLanguage.displayName,
      );

      allResults.addAll(batchOutputs);

      // Keep last 2 translated sentences as context for the next batch
      if (batchOutputs.length >= 2) {
        previousContext = '${batchOutputs[batchOutputs.length - 2].translation} ${batchOutputs.last.translation}';
      } else if (batchOutputs.isNotEmpty) {
        previousContext = batchOutputs.last.translation;
      }

      // Small throttle between batches to avoid rate limit spikes
      if (i + effectiveBatchSize < segments.length) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    return allResults;
  }

  Future<List<TranslationSegmentOutput>> _translateBatchWithRetry({
    required List<TranslationSegmentInput> batch,
    required List<int> batchIds,
    required TranslationModelType modelType,
    required String apiKey,
    required String previousContext,
    required String systemPrompt,
    required String targetLanguageName,
    int retryCount = 0,
  }) async {
    int netAttempts = 0;
    while (true) {
      try {
        netAttempts++;
        if (modelType == TranslationModelType.gemini25Flash) {
          return await _translateBatchGemini(
            batch: batch,
            batchIds: batchIds,
            apiKey: apiKey,
            previousContext: previousContext,
            systemPrompt: systemPrompt,
          );
        } else if (modelType == TranslationModelType.groqLlama3370b) {
          return await _translateBatchGroq(
            batch: batch,
            batchIds: batchIds,
            apiKey: apiKey,
            previousContext: previousContext,
            systemPrompt: systemPrompt,
            targetLanguageName: targetLanguageName,
          );
        } else {
          return batch.map((s) => TranslationSegmentOutput(id: s.id, translation: s.source)).toList();
        }
      } catch (e) {
        if (netAttempts < 3 && _isTransientError(e)) {
          await Future.delayed(Duration(seconds: netAttempts * 2));
          continue;
        }

        // If validation failed or segment count mismatched, split into two smaller batches
        if (retryCount < 2 && batch.length > 10) {
          final mid = batch.length ~/ 2;
          final part1 = batch.sublist(0, mid);
          final part2 = batch.sublist(mid);

          final res1 = await _translateBatchWithRetry(
            batch: part1,
            batchIds: part1.map((s) => s.id).toList(),
            modelType: modelType,
            apiKey: apiKey,
            previousContext: previousContext,
            systemPrompt: systemPrompt,
            targetLanguageName: targetLanguageName,
            retryCount: retryCount + 1,
          );

          final res2 = await _translateBatchWithRetry(
            batch: part2,
            batchIds: part2.map((s) => s.id).toList(),
            modelType: modelType,
            apiKey: apiKey,
            previousContext: res1.isNotEmpty ? res1.last.translation : previousContext,
            systemPrompt: systemPrompt,
            targetLanguageName: targetLanguageName,
            retryCount: retryCount + 1,
          );

          return [...res1, ...res2];
        }
        rethrow;
      }
    }
  }

  static bool _isTransientError(dynamic error) {
    if (error is SocketException || error is HttpException || error is TimeoutException) {
      return true;
    }
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return true;
      }
      final status = error.response?.statusCode;
      if (status == 429 || status == 500 || status == 502 || status == 503 || status == 504) {
        return true;
      }
    }
    final s = error.toString().toLowerCase();
    return s.contains('failed host lookup') ||
        s.contains('connection error') ||
        s.contains('socketexception') ||
        s.contains('timed out') ||
        s.contains('429');
  }

  static List<String>? _cachedTranslationModels;
  static DateTime? _lastDiscoveryTime;

  Future<List<TranslationSegmentOutput>> _translateBatchGemini({
    required List<TranslationSegmentInput> batch,
    required List<int> batchIds,
    required String apiKey,
    required String previousContext,
    required String systemPrompt,
  }) async {
    final payload = {
      'systemInstruction': {
        'parts': [{'text': systemPrompt}],
      },
      'contents': [
        {
          'parts': [
            {
              'text': jsonEncode({
                if (previousContext.isNotEmpty) 'dialogueContext': previousContext,
                'segments': batch.map((s) => s.toJson()).toList(),
              })
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'translations': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'id': {'type': 'INTEGER'},
                  'translation': {'type': 'STRING'}
                },
                'required': ['id', 'translation']
              }
            }
          },
          'required': ['translations']
        }
      }
    };

    // Query Google to discover the exact models available for this API key (cached for 30m)
    List<String> discoveredModels = [];
    final cacheValid = _cachedTranslationModels != null &&
        _lastDiscoveryTime != null &&
        DateTime.now().difference(_lastDiscoveryTime!) < const Duration(minutes: 30);

    if (cacheValid) {
      discoveredModels = List<String>.from(_cachedTranslationModels!);
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
            _cachedTranslationModels = List<String>.from(discoveredModels);
            _lastDiscoveryTime = DateTime.now();
          }
        }
      } catch (_) {}
    }

    final Set<String> combined = {};
    if (discoveredModels.isNotEmpty) {
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

    final fallbackModels = [
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash-001',
      'gemini-1.5-flash-002',
      'gemini-2.0-flash',
      'gemini-2.0-flash-exp',
      'gemini-1.5-flash-8b',
      'gemini-1.5-pro',
    ];
    combined.addAll(fallbackModels);
    final modelsToTry = combined.toList();

    Response? response;
    DioException? lastDioException;
    for (final model in modelsToTry) {
      for (final apiVersion in ['v1beta', 'v1']) {
        try {
          response = await _dio.post(
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
          if (response.statusCode == 200) break;
        } on DioException catch (e) {
          lastDioException = e;
          final status = e.response?.statusCode;
          if (status == 404 || status == 503 || status == 429 || status == 400) {
            continue;
          }
          rethrow;
        }
      }
      if (response != null && response.statusCode == 200) break;
    }

    if (response == null) {
      final err = lastDioException?.response?.data ?? lastDioException?.message ?? 'Unknown';
      throw Exception('All Gemini translation models failed. Last error: $err');
    }

    final data = response.data as Map<String, dynamic>;
    final candidates = (data['candidates'] as List<dynamic>?) ?? [];
    final text = candidates.first['content']['parts'][0]['text']?.toString() ?? '{}';
    final parsed = jsonDecode(text) as Map<String, dynamic>;

    return _validateAndParseResponse(batchIds, parsed);
  }

  Future<List<TranslationSegmentOutput>> _translateBatchGroq({
    required List<TranslationSegmentInput> batch,
    required List<int> batchIds,
    required String apiKey,
    required String previousContext,
    required String systemPrompt,
    required String targetLanguageName,
  }) async {
    final userContent = jsonEncode({
      if (previousContext.isNotEmpty) 'dialogueContext': previousContext,
      'instructions': 'Translate each segment into natural $targetLanguageName following BBC/Netflix standards. Return strictly JSON with format {"translations": [{"id": 1, "translation": "..."}]}.',
      'segments': batch.map((s) => s.toJson()).toList(),
    });

    final modelsToTry = [
      'llama-3.3-70b-versatile',
      'qwen/qwen3.8-27b',
      'openai/gpt-oss-120b',
    ];

    Response? response;
    DioException? lastError;

    for (final model in modelsToTry) {
      int attempts = 0;
      while (attempts < 3) {
        attempts++;
        try {
          response = await _dio.post(
            'https://api.groq.com/openai/v1/chat/completions',
            options: Options(headers: {
              'Authorization': 'Bearer ${apiKey.trim()}',
              'Content-Type': 'application/json',
            }),
            data: {
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userContent}
              ],
              'response_format': {'type': 'json_object'},
              'temperature': 0.1,
            },
          );
          if (response.statusCode == 200) {
            break;
          }
        } on DioException catch (e) {
          lastError = e;
          if (e.response?.statusCode == 429) {
            // Rate limited; wait with exponential backoff and retry
            final waitSeconds = attempts * 3;
            await Future.delayed(Duration(seconds: waitSeconds));
            continue;
          }
          if (e.response?.statusCode == 404) {
            // Model not found on this account tier; try next model
            break;
          }
          rethrow;
        }
      }

      if (response != null && response.statusCode == 200) {
        break;
      }
    }

    if (response == null) {
      if (lastError != null) throw lastError;
      throw Exception('Failed to get translation from Groq');
    }

    final data = response.data as Map<String, dynamic>;
    final choices = (data['choices'] as List<dynamic>?) ?? [];
    final text = choices.first['message']['content']?.toString() ?? '{}';
    final parsed = jsonDecode(text) as Map<String, dynamic>;

    return _validateAndParseResponse(batchIds, parsed);
  }

  List<TranslationSegmentOutput> _validateAndParseResponse(List<int> expectedIds, Map<String, dynamic> jsonResponse) {
    final rawTranslations = (jsonResponse['translations'] as List<dynamic>?) ?? [];
    if (rawTranslations.length != expectedIds.length) {
      throw SegmentCountMismatchException(
        expected: expectedIds.length,
        actual: rawTranslations.length,
      );
    }

    final List<TranslationSegmentOutput> outputs = [];
    final Map<int, String> mapById = {};

    for (final item in rawTranslations) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as int? ?? -1;
      final trans = map['translation']?.toString().trim() ?? '';
      mapById[id] = trans;
    }

    for (final id in expectedIds) {
      if (!mapById.containsKey(id)) {
        throw MissingSegmentIdException(missingId: id);
      }
      outputs.add(TranslationSegmentOutput(id: id, translation: mapById[id]!));
    }

    return outputs;
  }
}

class SegmentCountMismatchException implements Exception {
  final int expected;
  final int actual;

  const SegmentCountMismatchException({required this.expected, required this.actual});

  @override
  String toString() => 'SegmentCountMismatchException: Expected $expected segments, got $actual';
}

class MissingSegmentIdException implements Exception {
  final int missingId;

  const MissingSegmentIdException({required this.missingId});

  @override
  String toString() => 'MissingSegmentIdException: Missing translation for segment ID $missingId';
}

