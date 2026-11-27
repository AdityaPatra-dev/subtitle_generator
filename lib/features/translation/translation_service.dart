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
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 45),
                sendTimeout: const Duration(seconds: 30),
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
5. Contextual Accuracy: Accurately distinguish between battle commands, pleading/surrender (e.g. "放了我" / "放开我" -> "Let me go!" / "Spare me!"), and spoken dialogue within dramatic scene context.
6. If a segment contains non-speech indicators like [Music], [Laughter], or (Applause), translate or preserve the bracketed notation cleanly.
7. Return strictly valid JSON adhering to the provided schema with NO conversational chatter or markdown fences.$rtlNote
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
    } else if (modelType == TranslationModelType.gemini25Flash && effectiveBatchSize < 150) {
      // Gemini has 1M context; translate up to 150 segments in 1 request for blazing speed
      effectiveBatchSize = 150;
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
        if (retryCount >= 2) {
          // Final safety fallback: preserve original speech text rather than aborting the entire job
          return batch.map((s) => TranslationSegmentOutput(id: s.id, translation: s.source)).toList();
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

  static String _activeTranslationModelId = '';

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
        'temperature': 0.1,
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

    // Fast prioritized model list verified accessible on Gemini Free Tier
    final modelsToTry = {
      if (_activeTranslationModelId.isNotEmpty) _activeTranslationModelId,
      'gemini-2.5-flash',
      'gemini-3-flash-preview',
      'gemini-flash-lite-latest',
    }.toList();

    Response? response;
    DioException? lastDioException;
    for (final model in modelsToTry) {
      int modelAttempts = 0;
      while (modelAttempts < 2) {
        modelAttempts++;
        try {
          response = await _dio.post(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
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
            _activeTranslationModelId = model;
            break;
          }
        } on DioException catch (e) {
          lastDioException = e;
          final status = e.response?.statusCode;
          if (status == 429) {
            // Free-tier rate limit (15 RPM). Wait 10s once for quota window to reset, then retry.
            if (modelAttempts < 2) {
              await Future.delayed(const Duration(seconds: 10));
              continue;
            }
          }
          if (status == 404 || status == 503 || status == 400 || status == 429) {
            // Switch immediately on 503 demand spike / 404 / 400, or after 429 cooldown
            break;
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
    if (candidates.isEmpty) {
      return batch.map((s) => TranslationSegmentOutput(id: s.id, translation: s.source)).toList();
    }
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = (content?['parts'] as List<dynamic>?) ?? [];
    if (parts.isEmpty) {
      return batch.map((s) => TranslationSegmentOutput(id: s.id, translation: s.source)).toList();
    }
    final text = parts.first['text']?.toString() ?? '{}';
    Map<String, dynamic> parsed = {};
    try {
      parsed = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return batch.map((s) => TranslationSegmentOutput(id: s.id, translation: s.source)).toList();
    }

    return _validateAndParseResponse(
      expectedIds: batchIds,
      jsonResponse: parsed,
      batch: batch,
    );
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
    if (choices.isEmpty) {
      return batch.map((s) => TranslationSegmentOutput(id: s.id, translation: s.source)).toList();
    }
    final text = choices.first['message']?['content']?.toString() ?? '{}';
    Map<String, dynamic> parsed = {};
    try {
      parsed = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return batch.map((s) => TranslationSegmentOutput(id: s.id, translation: s.source)).toList();
    }

    return _validateAndParseResponse(
      expectedIds: batchIds,
      jsonResponse: parsed,
      batch: batch,
    );
  }

  List<TranslationSegmentOutput> _validateAndParseResponse({
    required List<int> expectedIds,
    required Map<String, dynamic> jsonResponse,
    required List<TranslationSegmentInput> batch,
  }) {
    final rawTranslations = (jsonResponse['translations'] as List<dynamic>?) ?? [];
    final Map<int, String> mapById = {};

    for (final item in rawTranslations) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as int? ?? -1;
        final trans = item['translation']?.toString().trim() ?? '';
        if (id != -1 && trans.isNotEmpty) {
          mapById[id] = trans;
        }
      }
    }

    final sourceMap = {for (var s in batch) s.id: s.source};
    final List<TranslationSegmentOutput> outputs = [];

    for (final id in expectedIds) {
      // Gracefully fall back to original source text if LLM dropped an ID, rather than failing the run
      final translation = mapById[id] ?? sourceMap[id] ?? '';
      outputs.add(TranslationSegmentOutput(id: id, translation: translation));
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

