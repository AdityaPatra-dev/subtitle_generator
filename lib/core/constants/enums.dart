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
  gemini25Transcribe('Google Gemini Flash', 'gemini-3-flash-preview'),
  deepgramNova3('Deepgram Nova-3 Multilingual', 'nova-3');

  final String displayName;
  final String modelId;
  const TranscriptionProviderType(this.displayName, this.modelId);
}

enum TranslationModelType {
  gemini25Flash('Google Gemini Flash', 'gemini-3-flash-preview'),
  groqLlama3370b('Groq Llama 3.3 70B Versatile', 'llama-3.3-70b-versatile'),
  none('Original Language (No Translation)', 'none');

  final String displayName;
  final String modelId;
  const TranslationModelType(this.displayName, this.modelId);
}

enum SourceLanguage {
  auto('Auto-Detect Language', ''),
  en('English', 'en'),
  zhHans('Chinese Simplified (简体中文)', 'zh-Hans'),
  zhHant('Chinese Traditional (繁體中文)', 'zh-Hant'),
  ja('Japanese (日本語)', 'ja'),
  es('Spanish (Español)', 'es'),
  hi('Hindi (हिन्दी)', 'hi'),
  ko('Korean (한국어)', 'ko'),
  fr('French (Français)', 'fr'),
  de('German (Deutsch)', 'de'),
  ar('Arabic (العربية)', 'ar'),
  pt('Portuguese (Português)', 'pt'),
  ru('Russian (Русский)', 'ru'),
  it('Italian (Italiano)', 'it'),
  bn('Bengali (বাংলা)', 'bn'),
  id('Indonesian (Bahasa Indonesia)', 'id'),
  tr('Turkish (Türkçe)', 'tr'),
  vi('Vietnamese (Tiếng Việt)', 'vi'),
  th('Thai (ไทย)', 'th'),
  pl('Polish (Polski)', 'pl'),
  nl('Dutch (Nederlands)', 'nl'),
  uk('Ukrainian (Українська)', 'uk'),
  sv('Swedish (Svenska)', 'sv'),
  cs('Czech (Čeština)', 'cs'),
  el('Greek (Ελληνικά)', 'el'),
  ro('Romanian (Română)', 'ro'),
  hu('Hungarian (Magyar)', 'hu'),
  da('Danish (Dansk)', 'da'),
  fi('Finnish (Suomi)', 'fi'),
  ta('Tamil (தமிழ்)', 'ta'),
  te('Telugu (తెలుగు)', 'te'),
  mr('Marathi (मराठी)', 'mr'),
  ur('Urdu (اردو)', 'ur'),
  ms('Malay (Bahasa Melayu)', 'ms'),
  fa('Persian (فارسی)', 'fa'),
  he('Hebrew (עברית)', 'he'),
  no('Norwegian (Norsk)', 'no'),
  tl('Tagalog / Filipino', 'tl'),
  yue('Cantonese (廣東話)', 'yue');

  final String displayName;
  final String bcp47;
  const SourceLanguage(this.displayName, this.bcp47);

  static List<SourceLanguage> get majorLanguages => [
        auto,
        en,
        zhHans,
        zhHant,
        ja,
        es,
        hi,
        ko,
        fr,
        de,
        ar,
        pt,
        ru,
        it,
      ];
}

