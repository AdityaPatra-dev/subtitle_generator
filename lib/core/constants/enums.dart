enum JobStatus {
  pending,
  extractingAudio,
  chunking,
  transcribing,
  translating,
  formatting,
  syncing,
  completed,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.extractingAudio:
        return 'Extracting Audio';
      case JobStatus.chunking:
        return 'Analyzing Silence & Chunking';
      case JobStatus.transcribing:
        return 'Transcribing Audio';
      case JobStatus.translating:
        return 'Translating Subtitles';
      case JobStatus.formatting:
        return 'Formatting Subtitles';
      case JobStatus.syncing:
        return 'Syncing to Cloud';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.failed:
        return 'Failed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal => this == completed || this == failed || this == cancelled;
  bool get isActive => !isTerminal && this != pending;
}

enum TranscriptionProviderType {
  groqWhisperLargeV3('Groq Whisper Large-v3', 'whisper-large-v3'),
  gemini25Transcribe('Google Gemini 2.5 Flash', 'gemini-2.5-flash'),
  deepgramNova3('Deepgram Nova-3 Multilingual', 'nova-3');

  final String displayName;
  final String modelId;
  const TranscriptionProviderType(this.displayName, this.modelId);
}

enum TranslationModelType {
  gemini25Flash('Google Gemini 2.5 Flash', 'gemini-2.5-flash'),
  groqLlama3370b('Groq Llama 3.3 70B Versatile', 'llama-3.3-70b-versatile'),
  none('Original Language (No Translation)', 'none');

  final String displayName;
  final String modelId;
  const TranslationModelType(this.displayName, this.modelId);
}

enum SourceLanguage {
  ja('Japanese (日本語)', 'ja'),
  zhHans('Chinese Simplified (简体中文)', 'zh-Hans'),
  zhHant('Chinese Traditional (繁體中文)', 'zh-Hant'),
  ko('Korean (한국어)', 'ko'),
  es('Spanish (Español)', 'es'),
  fr('French (Français)', 'fr'),
  de('German (Deutsch)', 'de'),
  auto('Auto Detect Language', '');

  final String displayName;
  final String bcp47;
  const SourceLanguage(this.displayName, this.bcp47);
}

