import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/core/constants/enums.dart';
import 'package:subtitle_generator/features/media/media_engine.dart';
import 'package:subtitle_generator/features/translation/translation_service.dart';

void main() {
  group('TargetLanguage Tests', () {
    test('Default target language is English', () {
      expect(TargetLanguage.en.bcp47, 'en');
      expect(TargetLanguage.en.englishName, 'English');
      expect(TargetLanguage.fromCode(''), TargetLanguage.en);
      expect(TargetLanguage.fromCode(null), TargetLanguage.en);
    });

    test('BCP-47 lookup works accurately for major and minor languages', () {
      expect(TargetLanguage.fromCode('es'), TargetLanguage.es);
      expect(TargetLanguage.fromCode('zh-Hans'), TargetLanguage.zhHans);
      expect(TargetLanguage.fromCode('ja'), TargetLanguage.ja);
      expect(TargetLanguage.fromCode('hi'), TargetLanguage.hi);
      expect(TargetLanguage.fromCode('ar'), TargetLanguage.ar);
      expect(TargetLanguage.fromCode('is'), TargetLanguage.isl);
    });

    test('matches() supports multi-script fuzzy search', () {
      // Search by English name
      expect(TargetLanguage.es.matches('spanish'), true);
      expect(TargetLanguage.es.matches('SPANISH'), true);

      // Search by native script
      expect(TargetLanguage.es.matches('español'), true);
      expect(TargetLanguage.zhHans.matches('中文'), true);
      expect(TargetLanguage.ja.matches('日本語'), true);
      expect(TargetLanguage.hi.matches('हिन्दी'), true);
      expect(TargetLanguage.ar.matches('العربية'), true);

      // Search by BCP-47 code
      expect(TargetLanguage.es.matches('es'), true);
      expect(TargetLanguage.de.matches('de'), true);

      // Non-matching
      expect(TargetLanguage.es.matches('russian'), false);
    });

    test('Language metadata flags (RTL and CJK)', () {
      expect(TargetLanguage.ar.isRtl, true);
      expect(TargetLanguage.he.isRtl, true);
      expect(TargetLanguage.ur.isRtl, true);
      expect(TargetLanguage.fa.isRtl, true);
      expect(TargetLanguage.en.isRtl, false);

      expect(TargetLanguage.zhHans.isCjk, true);
      expect(TargetLanguage.zhHant.isCjk, true);
      expect(TargetLanguage.ja.isCjk, true);
      expect(TargetLanguage.ko.isCjk, true);
      expect(TargetLanguage.en.isCjk, false);
    });
  });

  group('SpeechProfile & VAD Battle Mode Tests', () {
    test('Action/Battle mode has high-sensitivity acoustic parameters', () {
      const profile = SpeechProfile.actionDonghua;
      expect(profile.noiseDb, -20.0);
      expect(profile.minSilenceDurationSeconds, 0.20);
      expect(profile.bitrateKbps, 128);
      expect(profile.highPassHz, 40);
      expect(profile.lowPassHz, 12000);
      expect(profile.enableDynaudnorm, true);
      expect(profile.promptHint.contains('shouting'), true);
      expect(profile.promptHint.contains('altered'), true);
    });

    test('Standard and Clear profiles have conservative parameters', () {
      const standard = SpeechProfile.standardBalanced;
      expect(standard.noiseDb, -30.0);
      expect(standard.minSilenceDurationSeconds, 0.35);
      expect(standard.enableDynaudnorm, false);

      const clear = SpeechProfile.clearDialogue;
      expect(clear.noiseDb, -38.0);
      expect(clear.minSilenceDurationSeconds, 0.50);
      expect(clear.enableDynaudnorm, false);
    });

    test('AudioExtractionConfig.fromSpeechProfile applies dynaudnorm and bitrates', () {
      final configBattle = AudioExtractionConfig.fromSpeechProfile(SpeechProfile.actionDonghua);
      expect(configBattle.bitrateKbps, 128);
      expect(configBattle.dynaudnorm, true);
      expect(configBattle.highPassHz, 40);
      expect(configBattle.lowPassHz, 12000);

      final filterStrBattle = configBattle.toFfmpegFilterString();
      expect(filterStrBattle.contains('dynaudnorm=f=150:g=15'), true);
      expect(filterStrBattle.contains('highpass=f=40'), true);
      expect(filterStrBattle.contains('lowpass=f=12000'), true);

      final configStandard = AudioExtractionConfig.fromSpeechProfile(SpeechProfile.standardBalanced);
      expect(configStandard.bitrateKbps, 64);
      expect(configStandard.dynaudnorm, false);
      final filterStrStandard = configStandard.toFfmpegFilterString();
      expect(filterStrStandard.contains('dynaudnorm'), false);
    });
  });

  group('TranslationService Dynamic Prompt Tests', () {
    test('buildSystemPrompt injects target language name and rules', () {
      final spanishPrompt = TranslationService.buildSystemPrompt('Spanish (Español)');
      expect(spanishPrompt.contains('Spanish (Español)'), true);
      expect(spanishPrompt.contains('under 40-42 characters per line'), true);
      expect(spanishPrompt.contains('Right-to-Left'), false);

      final japanesePrompt = TranslationService.buildSystemPrompt('Japanese (日本語)', isCjk: true);
      expect(japanesePrompt.contains('Japanese (日本語)'), true);
      expect(japanesePrompt.contains('under 18-20 characters per line'), true);

      final arabicPrompt = TranslationService.buildSystemPrompt('Arabic (العربية)', isRtl: true);
      expect(arabicPrompt.contains('Arabic (العربية)'), true);
      expect(arabicPrompt.contains('Right-to-Left (RTL)'), true);
    });
  });
}

