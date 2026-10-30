import 'dart:convert';
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

  TranslationService([Dio? dio]) : _dio = dio ?? Dio();

  static const String _systemPrompt = '''
You are a professional audiovisual subtitle translator specializing in Japanese, Chinese, and Korean to natural English translation.
Your task is to translate an array of subtitle segments into natural, idiomatic English subtitles following Netflix and BBC standards.

RULES:
1. Maintain exact 1:1 segment mapping. Input contains N segments; output MUST contain exactly N segments with matching "id" values.
2. Never invent, hallucinate, or alter timestamps. You only provide the "translation" text.
3. Keep translations concise and readable within standard subtitle reading speeds (under 42 characters per line).
4. Preserve proper names and cultural terms naturally (e.g., retain common Japanese honorifics like -san or translate appropriately according to context).
5. If a segment contains non-speech indicators like [Music], [Laughter], or (Applause), translate or preserve the bracketed notation cleanly.
6. Return strictly valid JSON adhering to the provided schema with NO conversational chatter or markdown fences.
''';

  /// Translates a full list of segments in batches of 60 to 80 segments
  Future<List<TranslationSegmentOutput>> translateSegments({
    required List<TranslationSegmentInput> segments,
    required TranslationModelType modelType,
    required String apiKey,
    int batchSize = 70,
  }) async {
    if (segments.isEmpty || modelType == TranslationModelType.none) {
      return segments
          .map((s) => TranslationSegmentOutput(id: s.id, translation: s.source))
          .toList();
    }

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
    int retryCount = 0,
  }) async {
    try {
      if (modelType == TranslationModelType.gemini25Flash) {
        return await _translateBatchGemini(
          batch: batch,
          batchIds: batchIds,
          apiKey: apiKey,
          previousContext: previousContext,
        );
      } else if (modelType == TranslationModelType.groqLlama3370b) {
        return await _translateBatchGroq(
          batch: batch,
          batchIds: batchIds,
          apiKey: apiKey,
          previousContext: previousContext,
        );
      } else {
        return batch.map((s) => TranslationSegmentOutput(id: s.id, translation: s.source)).toList();
      }
    } catch (e) {
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
          retryCount: retryCount + 1,
        );

        final res2 = await _translateBatchWithRetry(
          batch: part2,
          batchIds: part2.map((s) => s.id).toList(),
          modelType: modelType,
          apiKey: apiKey,
          previousContext: res1.isNotEmpty ? res1.last.translation : previousContext,
          retryCount: retryCount + 1,
        );

        return [...res1, ...res2];
      }
      rethrow;
    }
  }

  Future<List<TranslationSegmentOutput>> _translateBatchGemini({
    required List<TranslationSegmentInput> batch,
    required List<int> batchIds,
    required String apiKey,
    required String previousContext,
  }) async {
    final payload = {
      'systemInstruction': {
        'parts': [{'text': _systemPrompt}],
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

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
      queryParameters: {'key': apiKey.trim()},
      data: payload,
    );

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
  }) async {
    final userContent = jsonEncode({
      if (previousContext.isNotEmpty) 'dialogueContext': previousContext,
      'instructions': 'Translate each segment into natural English following BBC/Netflix standards. Return strictly JSON with format {"translations": [{"id": 1, "translation": "..."}]}.',
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
                {'role': 'system', 'content': _systemPrompt},
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

