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

enum TargetLanguage {
  en('English', 'English', 'English', 'en', false, false),
  es('Spanish (Español)', 'Spanish', 'Español', 'es', false, false),
  zhHans('Chinese Simplified (简体中文)', 'Chinese Simplified', '简体中文', 'zh-Hans', false, true),
  zhHant('Chinese Traditional (繁體中文)', 'Chinese Traditional', '繁體中文', 'zh-Hant', false, true),
  ja('Japanese (日本語)', 'Japanese', '日本語', 'ja', false, true),
  hi('Hindi (हिन्दी)', 'Hindi', 'हिन्दी', 'hi', false, false),
  fr('French (Français)', 'French', 'Français', 'fr', false, false),
  de('German (Deutsch)', 'German', 'Deutsch', 'de', false, false),
  ar('Arabic (العربية)', 'Arabic', 'العربية', 'ar', true, false),
  pt('Portuguese (Português)', 'Portuguese', 'Português', 'pt', false, false),
  ru('Russian (Русский)', 'Russian', 'Русский', 'ru', false, false),
  it('Italian (Italiano)', 'Italian', 'Italiano', 'it', false, false),
  ko('Korean (한국어)', 'Korean', '한국어', 'ko', false, true),
  bn('Bengali (বাংলা)', 'Bengali', 'বাংলা', 'bn', false, false),
  id('Indonesian (Bahasa Indonesia)', 'Indonesian', 'Bahasa Indonesia', 'id', false, false),
  tr('Turkish (Türkçe)', 'Turkish', 'Türkçe', 'tr', false, false),
  vi('Vietnamese (Tiếng Việt)', 'Vietnamese', 'Tiếng Việt', 'vi', false, false),
  th('Thai (ไทย)', 'Thai', 'ไทย', 'th', false, false),
  pl('Polish (Polski)', 'Polish', 'Polski', 'pl', false, false),
  nl('Dutch (Nederlands)', 'Dutch', 'Nederlands', 'nl', false, false),
  uk('Ukrainian (Українська)', 'Ukrainian', 'Українська', 'uk', false, false),
  sv('Swedish (Svenska)', 'Swedish', 'Svenska', 'sv', false, false),
  cs('Czech (Čeština)', 'Czech', 'Čeština', 'cs', false, false),
  el('Greek (Ελληνικά)', 'Greek', 'Ελληνικά', 'el', false, false),
  ro('Romanian (Română)', 'Romanian', 'Română', 'ro', false, false),
  hu('Hungarian (Magyar)', 'Hungarian', 'Magyar', 'hu', false, false),
  da('Danish (Dansk)', 'Danish', 'Dansk', 'da', false, false),
  fi('Finnish (Suomi)', 'Finnish', 'Suomi', 'fi', false, false),
  ta('Tamil (தமிழ்)', 'Tamil', 'தமிழ்', 'ta', false, false),
  te('Telugu (తెలుగు)', 'Telugu', 'తెలుగు', 'te', false, false),
  mr('Marathi (मराठी)', 'Marathi', 'मराठी', 'mr', false, false),
  ur('Urdu (اردو)', 'Urdu', 'اردو', 'ur', true, false),
  ms('Malay (Bahasa Melayu)', 'Malay', 'Bahasa Melayu', 'ms', false, false),
  fa('Persian (فارسی)', 'Persian', 'فارسی', 'fa', true, false),
  he('Hebrew (עברית)', 'Hebrew', 'עברית', 'he', true, false),
  no('Norwegian (Norsk)', 'Norwegian', 'Norsk', 'no', false, false),
  tl('Tagalog (Filipino)', 'Tagalog', 'Filipino', 'tl', false, false),
  sw('Swahili (Kiswahili)', 'Swahili', 'Kiswahili', 'sw', false, false),
  bg('Bulgarian (Български)', 'Bulgarian', 'Български', 'bg', false, false),
  sk('Slovak (Slovenčina)', 'Slovak', 'Slovenčina', 'sk', false, false),
  hr('Croatian (Hrvatski)', 'Croatian', 'Hrvatski', 'hr', false, false),
  sr('Serbian (Српски)', 'Serbian', 'Српски', 'sr', false, false),
  lt('Lithuanian (Lietuvių)', 'Lithuanian', 'Lietuvių', 'lt', false, false),
  sl('Slovenian (Slovenščina)', 'Slovenian', 'Slovenščina', 'sl', false, false),
  et('Estonian (Eesti)', 'Estonian', 'Eesti', 'et', false, false),
  lv('Latvian (Latviešu)', 'Latvian', 'Latviešu', 'lv', false, false),
  gu('Gujarati (ગુજરાતી)', 'Gujarati', 'ગુજરાતી', 'gu', false, false),
  kn('Kannada (ಕನ್ನಡ)', 'Kannada', 'ಕನ್ನಡ', 'kn', false, false),
  ml('Malayalam (മലയാളം)', 'Malayalam', 'മലയാളം', 'ml', false, false),
  pa('Punjabi (ਪੰਜਾਬੀ)', 'Punjabi', 'ਪੰਜਾਬੀ', 'pa', false, false),
  my('Burmese (မြန်မာဘာသာ)', 'Burmese', 'မြန်မာဘာသာ', 'my', false, false),
  km('Khmer (ភាសាខ្មែរ)', 'Khmer', 'ភាសាខ្មែរ', 'km', false, false),
  am('Amharic (አማርኛ)', 'Amharic', 'አማርኛ', 'am', false, false),
  af('Afrikaans', 'Afrikaans', 'Afrikaans', 'af', false, false),
  ca('Catalan (Català)', 'Catalan', 'Català', 'ca', false, false),
  cy('Welsh (Cymraeg)', 'Welsh', 'Cymraeg', 'cy', false, false),
  isl('Icelandic (Íslenska)', 'Icelandic', 'Íslenska', 'is', false, false),
  ka('Georgian (ქართული)', 'Georgian', 'ქართული', 'ka', false, false),
  hy('Armenian (Հայերեն)', 'Armenian', 'Հայերեն', 'hy', false, false),
  az('Azerbaijani (Azərbaycan)', 'Azerbaijani', 'Azərbaycan', 'az', false, false),
  kk('Kazakh (Қазақша)', 'Kazakh', 'Қазақша', 'kk', false, false),
  uz('Uzbek (Oʻzbekcha)', 'Uzbek', 'Oʻzbekcha', 'uz', false, false),
  mn('Mongolian (Монгол)', 'Mongolian', 'Монгол', 'mn', false, false),
  ne('Nepali (नेपाली)', 'Nepali', 'नेपाली', 'ne', false, false),
  si('Sinhala (සිංහල)', 'Sinhala', 'සිංහල', 'si', false, false),
  kmr('Kurdish (Kurdî)', 'Kurdish', 'Kurdî', 'kmr', false, false),
  sq('Albanian (Shqip)', 'Albanian', 'Shqip', 'sq', false, false),
  mk('Macedonian (Македонски)', 'Macedonian', 'Македонски', 'mk', false, false),
  bs('Bosnian (Bosanski)', 'Bosnian', 'Bosanski', 'bs', false, false),
  gl('Galician (Galego)', 'Galician', 'Galego', 'gl', false, false),
  eu('Basque (Euskara)', 'Basque', 'Euskara', 'eu', false, false);

  final String displayName;
  final String englishName;
  final String nativeName;
  final String bcp47;
  final bool isRtl;
  final bool isCjk;

  const TargetLanguage(
    this.displayName,
    this.englishName,
    this.nativeName,
    this.bcp47,
    this.isRtl,
    this.isCjk,
  );

  bool matches(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;
    return englishName.toLowerCase().contains(clean) ||
        nativeName.toLowerCase().contains(clean) ||
        displayName.toLowerCase().contains(clean) ||
        bcp47.toLowerCase().startsWith(clean);
  }

  static TargetLanguage fromCode(String? code) {
    if (code == null || code.isEmpty) return TargetLanguage.en;
    final lower = code.toLowerCase().trim();
    return TargetLanguage.values.firstWhere(
      (l) => l.bcp47.toLowerCase() == lower || l.name.toLowerCase() == lower,
      orElse: () => TargetLanguage.en,
    );
  }

  static List<TargetLanguage> get majorLanguages => [
        en,
        es,
        zhHans,
        zhHant,
        ja,
        hi,
        fr,
        de,
        ar,
        pt,
        ru,
        it,
        ko,
      ];
}

enum SpeechProfile {
  actionDonghua(
    displayName: 'Action & Loud Audio (High Sensitivity)',
    shortLabel: 'Action Mode',
    description: 'Optimized for loud background music, sound effects, explosions & altered or synthetic voices',
    badge: 'HIGH SENSITIVITY',
    noiseDb: -20.0,
    minSilenceDurationSeconds: 0.20,
    bitrateKbps: 128,
    highPassHz: 40,
    lowPassHz: 12000,
    enableDynaudnorm: true,
    promptHint:
        'Transcribe all dialogue, shouting, action phrases, modulated, robotic, and altered character voices accurately over loud background music and sound effects.',
  ),
  standardBalanced(
    displayName: 'Standard (Balanced)',
    shortLabel: 'Standard',
    description: 'Balanced profile for movies, TV series, shows, and online videos',
    badge: 'DEFAULT',
    noiseDb: -30.0,
    minSilenceDurationSeconds: 0.35,
    bitrateKbps: 64,
    highPassHz: 80,
    lowPassHz: 8000,
    enableDynaudnorm: false,
    promptHint: 'Transcribe all spoken dialogue clearly and accurately.',
  ),
  clearDialogue(
    displayName: 'Clear Speech / Dialogue',
    shortLabel: 'Dialogue Mode',
    description: 'Strict voice isolation for podcasts, interviews, audiobooks, and conversations',
    badge: 'CONSERVATIVE',
    noiseDb: -38.0,
    minSilenceDurationSeconds: 0.50,
    bitrateKbps: 48,
    highPassHz: 100,
    lowPassHz: 7500,
    enableDynaudnorm: false,
    promptHint: 'Transcribe clear speech and conversation.',
  );

  final String displayName;
  final String shortLabel;
  final String description;
  final String badge;
  final double noiseDb;
  final double minSilenceDurationSeconds;
  final int bitrateKbps;
  final int highPassHz;
  final int lowPassHz;
  final bool enableDynaudnorm;
  final String promptHint;

  const SpeechProfile({
    required this.displayName,
    required this.shortLabel,
    required this.description,
    required this.badge,
    required this.noiseDb,
    required this.minSilenceDurationSeconds,
    required this.bitrateKbps,
    required this.highPassHz,
    required this.lowPassHz,
    required this.enableDynaudnorm,
    required this.promptHint,
  });

  static SpeechProfile fromName(String? name) {
    if (name == null || name.isEmpty) return SpeechProfile.standardBalanced;
    return SpeechProfile.values.firstWhere(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
      orElse: () => SpeechProfile.standardBalanced,
    );
  }
}

