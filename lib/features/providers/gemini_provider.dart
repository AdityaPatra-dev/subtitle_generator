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
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 45),
                sendTimeout: const Duration(seconds: 45),
              ),
            );

  @override
  String get name => 'Google Gemini Flash';

  @override
  String get modelId => _activeModelId;

  String _activeModelId = 'gemini-2.5-flash';

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
    double? chunkDurationSeconds,
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
                  '6. Capture all dialogue faithfully with zero hallucination.\n'
                  '7. CRITICAL TIMING ACCURACY: Listen carefully to when characters speak across action scenes, battle noise, and background music. Never bunch, clamp, or dump subtitle timestamps at the end of the audio. Each sentence must have its own distinct, non-overlapping timestamp precisely matching when the actor begins speaking.\n'
                  '8. COMBAT & ACTION SPEECH ACCURACY: In battle sequences or intense action scenes with loud explosions, fighting, or background music, listen with utmost precision for spoken dialogue, character names called out, battle cries, and dramatic utterances. Transcribe every spoken sentence completely.\n'
                  '9. EXCLUDE NON-VERBAL EXERTION: Do NOT create cues for pure non-verbal exertion grunts or gasps (e.g. "Ah!", "Ha!", "Yah!", "Ugh!") unless they accompany actual spoken words, character names, or technique chants. Prioritize actual dialogue.',
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
        'temperature': 0.1,
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

    // Fast prioritized model list verified accessible on Gemini Free Tier
    final modelsToTry = [
      if (_activeModelId.isNotEmpty) _activeModelId,
      'gemini-2.5-flash',
      'gemini-3-flash-preview',
      'gemini-flash-lite-latest',
    ].toSet().toList();

    DioException? lastDioException;
    String? lastErrorMessage;
    String lastAttemptedModel = _activeModelId;

    for (final model in modelsToTry) {
      lastAttemptedModel = model;
      int modelAttempts = 0;
      while (modelAttempts < 2) {
        modelAttempts++;
        // Audio generateContent is exclusively supported on v1beta
        const apiVersion = 'v1beta';
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

            final List<TranscriptionSegment> rawSegments = [];
            double maxEnd = 0.0;

            for (int i = 0; i < parsedList.length; i++) {
              final item = parsedList[i] as Map<String, dynamic>;
              final start = double.tryParse(item['start']?.toString() ?? '0.0') ?? 0.0;
              final end = double.tryParse(item['end']?.toString() ?? '0.0') ?? 0.0;
              final text = item['text']?.toString().trim() ?? '';

              if (end > maxEnd) maxEnd = end;

              if (text.isNotEmpty) {
                rawSegments.add(TranscriptionSegment(
                  index: i,
                  startSeconds: start,
                  endSeconds: end > start ? end : start + 2.0,
                  text: text,
                ));
              }
            }

            final effectiveDuration = (chunkDurationSeconds != null && chunkDurationSeconds > 0)
                ? chunkDurationSeconds
                : maxEnd;

            final sanitizedSegments = _sanitizeAndFixClumpedTimestamps(
              rawSegments: rawSegments,
              chunkDurationSeconds: effectiveDuration,
            );

            return TranscriptionResult(
              segments: sanitizedSegments,
              durationSeconds: effectiveDuration,
            );
          } else {
            lastErrorMessage = 'Gemini API error ($model): ${response.data}';
          }
        } on DioException catch (e) {
          lastDioException = e;
          final status = e.response?.statusCode;
          if (status == 429) {
            // Rate limit (15 RPM free tier). Wait 8 seconds once, then retry same model.
            if (modelAttempts < 2) {
              await Future.delayed(const Duration(seconds: 8));
              continue;
            }
          }
          if (status == 404 || status == 503 || status == 400 || status == 500 || status == 429) {
            // Switch immediately on 503 demand spike / 404 / 400 / 500, or after 429 cooldown
            break;
          }
          rethrow;
        }
      }
    }

    if (lastDioException != null) {
      throw TranscriptionException(
        provider: name,
        statusCode: lastDioException.response?.statusCode,
        message: _formatDioError(lastDioException, lastAttemptedModel),
      );
    }

    throw TranscriptionException(
      provider: name,
      message: lastErrorMessage ?? 'All Gemini models failed',
    );
  }

  /// Detects and repairs LLM timestamp clumping / pileup artifacts where speech
  /// occurring across action/music scenes gets clamped to the chunk boundary
  /// or shares identical timestamps.
  static List<TranscriptionSegment> _sanitizeAndFixClumpedTimestamps({
    required List<TranscriptionSegment> rawSegments,
    required double chunkDurationSeconds,
  }) {
    if (rawSegments.isEmpty) return [];

    final List<TranscriptionSegment> cleaned = [];
    for (int i = 0; i < rawSegments.length; i++) {
      final s = rawSegments[i];
      final start = s.startSeconds < 0 ? 0.0 : s.startSeconds;
      final end = s.endSeconds > start ? s.endSeconds : start + 2.0;
      cleaned.add(TranscriptionSegment(
        index: i,
        startSeconds: start,
        endSeconds: end,
        text: s.text,
        speakerTag: s.speakerTag,
        confidence: s.confidence,
      ));
    }

    if (cleaned.length <= 1) return cleaned;

    // Detect if trailing segments are clumped at chunk boundary or have identical starts
    int clumpStartIndex = -1;
    for (int i = cleaned.length - 1; i >= 1; i--) {
      final curr = cleaned[i];
      final prev = cleaned[i - 1];

      final isClumpedAtEnd = curr.startSeconds >= (chunkDurationSeconds - 1.2) &&
          prev.startSeconds >= (chunkDurationSeconds - 1.2);
      final hasIdenticalStart = (curr.startSeconds - prev.startSeconds).abs() < 0.15;

      if (isClumpedAtEnd || hasIdenticalStart) {
        clumpStartIndex = i - 1;
      } else {
        break;
      }
    }

    // If clumping detected (2 or more trailing segments collapsed together)
    if (clumpStartIndex != -1 && clumpStartIndex < cleaned.length - 1) {
      final lastValidEnd = clumpStartIndex > 0 ? cleaned[clumpStartIndex - 1].endSeconds : 0.0;
      final clumpCount = cleaned.length - clumpStartIndex;

      // Desired duration per cue: ~2.5s, with 0.2s pause
      const targetCueDur = 2.5;
      const pauseDur = 0.2;
      final neededSpan = clumpCount * (targetCueDur + pauseDur);

      double spanStart;
      if (chunkDurationSeconds - neededSpan >= lastValidEnd + pauseDur) {
        spanStart = chunkDurationSeconds - neededSpan;
      } else {
        spanStart = lastValidEnd + pauseDur;
      }
      if (spanStart < 0) spanStart = 0.0;

      final availableSpan = (chunkDurationSeconds - spanStart).clamp(clumpCount * 1.5, chunkDurationSeconds);
      final segmentSlot = availableSpan / clumpCount;

      for (int k = 0; k < clumpCount; k++) {
        final idx = clumpStartIndex + k;
        final segStart = spanStart + (k * segmentSlot);
        final segEnd = (k == clumpCount - 1)
            ? (spanStart + availableSpan)
            : (segStart + segmentSlot - pauseDur);

        cleaned[idx] = TranscriptionSegment(
          index: idx,
          startSeconds: double.parse(segStart.toStringAsFixed(3)),
          endSeconds: double.parse((segEnd > segStart ? segEnd : segStart + 1.5).toStringAsFixed(3)),
          text: cleaned[idx].text,
          speakerTag: cleaned[idx].speakerTag,
          confidence: cleaned[idx].confidence,
        );
      }
    }

    // Final monotonicity pass: ensure strictly non-overlapping & sequential timestamps
    final List<TranscriptionSegment> result = [];
    double lastEnd = 0.0;
    for (int i = 0; i < cleaned.length; i++) {
      final s = cleaned[i];
      double start = s.startSeconds;
      if (start < lastEnd) {
        start = lastEnd + 0.1;
      }
      double end = s.endSeconds;
      if (end <= start) {
        end = start + 2.0;
      }
      result.add(TranscriptionSegment(
        index: i,
        startSeconds: double.parse(start.toStringAsFixed(3)),
        endSeconds: double.parse(end.toStringAsFixed(3)),
        text: s.text,
        speakerTag: s.speakerTag,
        confidence: s.confidence,
      ));
      lastEnd = end;
    }

    return result;
  }
}

