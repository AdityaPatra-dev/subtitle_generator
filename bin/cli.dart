import 'dart:io';
import 'package:args/args.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../lib/core/constants/enums.dart';
import '../lib/core/security/secure_storage_service.dart';
import '../lib/core/services/audio_cache_manager.dart';
import '../lib/core/storage/database.dart';
import '../lib/features/media/process_media_engine.dart';
import '../lib/features/transcription/pipeline_coordinator.dart';
import '../lib/features/translation/translation_service.dart';

class CliSecureStorage extends SecureStorageService {
  final String? groqKey;
  final String? geminiKey;
  final String? deepgramKey;

  CliSecureStorage({this.groqKey, this.geminiKey, this.deepgramKey});

  @override
  Future<String?> getGroqKey() async => groqKey ?? Platform.environment['GROQ_API_KEY'];

  @override
  Future<String?> getGeminiKey() async => geminiKey ?? Platform.environment['GEMINI_API_KEY'];

  @override
  Future<String?> getDeepgramKey() async => deepgramKey ?? Platform.environment['DEEPGRAM_API_KEY'];

  @override
  Future<void> saveGroqKey(String key) async {}

  @override
  Future<void> deleteGroqKey() async {}

  @override
  Future<void> saveGeminiKey(String key) async {}

  @override
  Future<void> deleteGeminiKey() async {}

  @override
  Future<void> saveDeepgramKey(String key) async {}

  @override
  Future<void> deleteDeepgramKey() async {}

  @override
  Future<String?> getDeviceId() async => 'cli_device';

  @override
  Future<void> saveDeviceId(String deviceId) async {}

  @override
  Future<void> purgeAllCredentials() async {}
}

void printBanner() {
  stdout.writeln('================================================================');
  stdout.writeln('🎬 AI Subtitle Generator — Autonomous Speech & Translation CLI');
  stdout.writeln('================================================================');
}

void main(List<String> rawArgs) async {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'Path to video or audio file (MP4, MKV, MOV, WEBM, AVI, etc.)')
    ..addOption('output-dir', abbr: 'o', defaultsTo: './output', help: 'Directory to export generated .srt and .vtt subtitles')
    ..addOption('source-lang', abbr: 's', defaultsTo: 'auto', help: 'Spoken audio language (e.g. auto, zh, ja, en, ko, es, hi)')
    ..addOption('target-lang', abbr: 't', defaultsTo: 'en', help: 'Target subtitle language (e.g. en, es, hi, ja, zh-Hans, fr, de, ar)')
    ..addOption('profile', abbr: 'p', defaultsTo: 'action', help: 'Speech/VAD profile: action (battle/loud BGM), standard (balanced), podcast (dialogue)')
    ..addOption('provider', defaultsTo: 'gemini', help: 'Transcription provider: gemini (default), groq, deepgram')
    ..addOption('translation', defaultsTo: 'gemini', help: 'Translation model: gemini (default), groq, none')
    ..addOption('gemini-key', help: 'Google Gemini API Key (or set GEMINI_API_KEY env var)')
    ..addOption('groq-key', help: 'Groq API Key (or set GROQ_API_KEY env var)')
    ..addOption('deepgram-key', help: 'Deepgram API Key (or set DEEPGRAM_API_KEY env var)')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print CLI usage and options');

  ArgResults args;
  try {
    args = parser.parse(rawArgs);
  } catch (e) {
    stderr.writeln('Error parsing arguments: $e');
    stdout.writeln(parser.usage);
    exit(1);
  }

  if (args['help'] as bool || !args.wasParsed('input')) {
    printBanner();
    stdout.writeln('Usage: subtitle-generator -i <video_file> [options]\n');
    stdout.writeln(parser.usage);
    exit(args['help'] as bool ? 0 : 1);
  }

  final inputPath = args['input'] as String;
  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('❌ Error: Input file not found: $inputPath');
    exit(1);
  }

  final outDir = args['output-dir'] as String;
  await Directory(outDir).create(recursive: true);

  // Parse Source Language
  final sourceCode = (args['source-lang'] as String).toLowerCase();
  final sourceLang = SourceLanguage.values.firstWhere(
    (l) => l.bcp47.toLowerCase() == sourceCode || l.name.toLowerCase() == sourceCode,
    orElse: () => SourceLanguage.auto,
  );

  // Parse Target Language
  final targetCode = (args['target-lang'] as String).toLowerCase();
  final targetLang = TargetLanguage.fromCode(targetCode);

  // Parse Speech Profile
  final profileStr = (args['profile'] as String).toLowerCase();
  SpeechProfile profile;
  if (profileStr.contains('action') || profileStr.contains('battle') || profileStr.contains('high')) {
    profile = SpeechProfile.actionDonghua;
  } else if (profileStr.contains('podcast') || profileStr.contains('clear')) {
    profile = SpeechProfile.clearDialogue;
  } else {
    profile = SpeechProfile.standardBalanced;
  }

  // Parse Provider
  final provStr = (args['provider'] as String).toLowerCase();
  TranscriptionProviderType providerType;
  if (provStr.contains('groq') || provStr.contains('whisper')) {
    providerType = TranscriptionProviderType.groqWhisperLargeV3;
  } else if (provStr.contains('deepgram') || provStr.contains('nova')) {
    providerType = TranscriptionProviderType.deepgramNova3;
  } else {
    providerType = TranscriptionProviderType.gemini25Transcribe;
  }

  // Parse Translation Model
  final transStr = (args['translation'] as String).toLowerCase();
  TranslationModelType translationModel;
  if (transStr.contains('none') || transStr.contains('off') || transStr == 'false') {
    translationModel = TranslationModelType.none;
  } else if (transStr.contains('groq') || transStr.contains('llama')) {
    translationModel = TranslationModelType.groqLlama3370b;
  } else {
    translationModel = TranslationModelType.gemini25Flash;
  }

  printBanner();
  stdout.writeln('📂 Input Video:    ${inputFile.path}');
  stdout.writeln('📁 Output Folder:  $outDir');
  stdout.writeln('🗣️  Source Lang:    ${sourceLang.displayName}');
  stdout.writeln('🌐 Target Lang:    ${targetLang.displayName}');
  stdout.writeln('⚡ Speech Profile: ${profile.displayName} [${profile.badge}]');
  stdout.writeln('🤖 STT Provider:   ${providerType.displayName}');
  stdout.writeln('🔄 Translation:    ${translationModel.displayName}');
  stdout.writeln('----------------------------------------------------------------');

  setupSqliteOnLinux();
  final db = AppDatabase(NativeDatabase.memory());
  const mediaEngine = ProcessMediaEngine();
  final secureStorage = CliSecureStorage(
    geminiKey: args['gemini-key'] as String?,
    groqKey: args['groq-key'] as String?,
    deepgramKey: args['deepgram-key'] as String?,
  );
  final translationService = TranslationService();
  final audioCacheManager = AudioCacheManager();

  final coordinator = PipelineCoordinator(
    db: db,
    mediaEngine: mediaEngine,
    secureStorage: secureStorage,
    translationService: translationService,
    audioCacheManager: audioCacheManager,
  );

  final tempDir = Directory.systemTemp.createTempSync('cli_subtitles_');

  try {
    final stream = coordinator.processVideo(
      videoPath: inputFile.path,
      originalFilename: p.basename(inputFile.path),
      audioStreamIndex: 0,
      sourceLang: sourceLang,
      targetLang: targetLang,
      speechProfile: profile,
      providerType: providerType,
      translationModel: translationModel,
      tempWorkDir: tempDir.path,
      outputDir: outDir,
    );

    await for (final progress in stream) {
      final pct = (progress.progressPercent * 100).toStringAsFixed(0);
      final elapsed = progress.elapsedFormatted;
      stdout.write('\r[$pct%] [$elapsed] ${progress.statusMessage.padRight(70)}');
      if (progress.status == JobStatus.completed) {
        stdout.writeln('\n\n✅ Subtitle generation completed successfully!');
        final baseName = p.basenameWithoutExtension(inputFile.path);
        stdout.writeln('📄 SRT: ${p.join(outDir, "$baseName.srt")}');
        stdout.writeln('📄 VTT: ${p.join(outDir, "$baseName.vtt")}');
      }
    }
  } catch (err) {
    stderr.writeln('\n\n❌ Pipeline execution failed: $err');
    exit(1);
  } finally {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
    await db.close();
  }
}
