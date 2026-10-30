class TranscriptionSegment {
  final int index;
  final double startSeconds;
  final double endSeconds;
  final String text;
  final String? speakerTag;
  final double? confidence;

  const TranscriptionSegment({
    required this.index,
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
    this.speakerTag,
    this.confidence,
  });

  TranscriptionSegment copyWithOffset(double offsetSeconds, int newIndex) {
    return TranscriptionSegment(
      index: newIndex,
      startSeconds: startSeconds + offsetSeconds,
      endSeconds: endSeconds + offsetSeconds,
      text: text,
      speakerTag: speakerTag,
      confidence: confidence,
    );
  }
}

class TranscriptionResult {
  final List<TranscriptionSegment> segments;
  final String? detectedLanguage;
  final double durationSeconds;

  const TranscriptionResult({
    required this.segments,
    this.detectedLanguage,
    required this.durationSeconds,
  });
}

class ProviderValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ProviderValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ProviderValidationResult.success() => const ProviderValidationResult(isValid: true);
  factory ProviderValidationResult.failure(String message) => ProviderValidationResult(isValid: false, errorMessage: message);
}

abstract class BaseTranscriptionProvider {
  String get name;
  String get modelId;

  Future<ProviderValidationResult> validateApiKey(String apiKey);

  Future<TranscriptionResult> transcribeChunk({
    required String audioChunkPath,
    required String apiKey,
    String? sourceLanguage,
  });
}

class TranscriptionException implements Exception {
  final String provider;
  final String message;
  final int? statusCode;

  const TranscriptionException({
    required this.provider,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'TranscriptionException($provider, status: $statusCode): $message';
}

