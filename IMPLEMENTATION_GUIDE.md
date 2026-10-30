# Implementation Guide & Technical Execution Manual

This document provides ready-to-use implementation assets, algorithms, prompt templates, and dependency definitions for developing the Subtitle Generator application.

---

## 1. Verified Flutter Dependencies (`pubspec.yaml`)

```yaml
name: subtitle_generator
description: "Cross-platform AI Subtitle Generator with Smart Edge-Cloud Hybrid Architecture."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Local Database & Storage
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0

  # Hardware-Backed Key Storage
  flutter_secure_storage: ^9.0.0

  # Networking & HTTP
  dio: ^5.4.3+1
  http_parser: ^4.0.2

  # Firebase Suite (Cloud Sync & Auth)
  firebase_core: ^2.30.1
  firebase_auth: ^4.19.4
  cloud_firestore: ^4.17.2
  firebase_storage: ^11.7.4
  google_sign_in: ^6.2.1

  # Media & File Picking
  file_picker: ^8.0.3

  # Audio Demuxing (Android)
  ffmpeg_kit_flutter_full: ^6.0.3

  # Utilities
  uuid: ^4.4.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  drift_dev: ^2.18.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0

flutter:
  uses-material-design: true
  assets:
    - assets/bin/ # Windows ffmpeg.exe & Apple static helpers
```

---

## 2. Silence-Aware VAD Splitter Algorithm (Dart)

### 2.1 FFmpeg Silence Detect Execution
```bash
ffmpeg -i preprocessed_audio.mp3 -af silencedetect=noise=-30dB:d=0.4 -f null -
```

### 2.2 Dart Parser Implementation
```dart
class SilenceInterval {
  final double start;
  final double end;
  double get duration => end - start;
  double get midpoint => start + (duration / 2);
  const SilenceInterval({required this.start, required this.end});
}

class VadChunkCalculator {
  static final RegExp _silenceStartRegex = RegExp(r'silence_start:\s*([0-9.]+)');
  static final RegExp _silenceEndRegex = RegExp(r'silence_end:\s*([0-9.]+)\s*\|\s*silence_duration:\s*([0-9.]+)');

  /// Parses FFmpeg stderr output to extract silent windows
  static List<SilenceInterval> parseSilenceOutput(String ffmpegStderr) {
    final List<SilenceInterval> intervals = [];
    double? currentStart;

    for (final line in ffmpegStderr.split('\n')) {
      final startMatch = _silenceStartRegex.firstMatch(line);
      if (startMatch != null) {
        currentStart = double.tryParse(startMatch.group(1)!);
        continue;
      }

      final endMatch = _silenceEndRegex.firstMatch(line);
      if (endMatch != null && currentStart != null) {
        final end = double.tryParse(endMatch.group(1)!);
        if (end != null) {
          intervals.add(SilenceInterval(start: currentStart, end: end));
        }
        currentStart = null;
      }
    }
    return intervals;
  }

  /// Calculates optimal split timestamps (in seconds)
  static List<double> calculateSplitPoints({
    required double totalDurationSeconds,
    required List<SilenceInterval> silenceIntervals,
    double targetChunkDurationSeconds = 720.0, // 12 minutes
    double minChunkDurationSeconds = 600.0,    // 10 minutes
    double maxChunkDurationSeconds = 840.0,    // 14 minutes
  }) {
    final List<double> splitPoints = [];
    double currentWindowStart = 0.0;

    while (currentWindowStart + maxChunkDurationSeconds < totalDurationDuration(totalDurationSeconds)) {
      final searchMin = currentWindowStart + minChunkDurationSeconds;
      final searchMax = currentWindowStart + maxChunkDurationSeconds;

      // Find all silent intervals within the target window
      final candidates = silenceIntervals.where((s) => s.midpoint >= searchMin && s.midpoint <= searchMax).toList();

      if (candidates.isNotEmpty) {
        // Pick the longest silence duration (most natural pause)
        candidates.sort((a, b) => b.duration.compareTo(a.duration));
        final chosenSplit = candidates.first.midpoint;
        splitPoints.add(chosenSplit);
        currentWindowStart = chosenSplit;
      } else {
        // Fallback: No silence found in window -> Hard cut at target boundary
        final hardSplit = currentWindowStart + targetChunkDurationSeconds;
        splitPoints.add(hardSplit);
        currentWindowStart = hardSplit;
      }
    }

    return splitPoints;
  }

  static double totalDurationDuration(double d) => d;
}
```

---

## 3. Stage 2 Translation Prompt & JSON Schema

When sending Stage 1 original transcripts to Gemini 2.5 Flash or Groq Llama 3.3 70B:

### 3.1 System Prompt
```text
You are a professional audiovisual subtitle translator specializing in Japanese, Chinese, and Korean to natural English translation.
Your task is to translate an array of subtitle segments into natural, idiomatic English subtitles following Netflix and BBC standards.

RULES:
1. Maintain exact 1:1 segment mapping. Input contains N segments; output MUST contain exactly N segments with matching "id" values.
2. Never invent, hallucinate, or alter timestamps. You only provide the "translation" text.
3. Keep translations concise and readable within standard subtitle reading speeds (under 42 characters per line).
4. Preserve proper names and cultural terms naturally (e.g., retain common Japanese honorifics like -san or translate appropriately according to context).
5. If a segment contains non-speech indicators like [Music], [Laughter], or (Applause), translate or preserve the bracketed notation cleanly.
6. Return strictly valid JSON adhering to the provided schema with NO conversational chatter or markdown fences.
```

### 3.2 Request Payload (Batch of 60–80 Segments)
```json
{
  "context": "Previous dialogue: We just arrived at Shinjuku station. It's very crowded today.",
  "segments": [
    {
      "id": 101,
      "source": "次はどこに行きますか？"
    },
    {
      "id": 102,
      "source": "東京タワーの近くにあるカフェに行きましょう。"
    }
  ]
}
```

### 3.3 Expected Model Output
```json
{
  "translations": [
    {
      "id": 101,
      "translation": "Where are we heading next?"
    },
    {
      "id": 102,
      "translation": "Let's go to that cafe near Tokyo Tower."
    }
  ]
}
```

### 3.4 Dart Validation Interceptor
```dart
void validateTranslations(List<int> inputIds, Map<String, dynamic> jsonResponse) {
  final List translations = jsonResponse['translations'] as List? ?? [];
  if (translations.length != inputIds.length) {
    throw SegmentCountMismatchException(
      expected: inputIds.length,
      actual: translations.length,
    );
  }

  final responseIds = translations.map((e) => e['id'] as int).toSet();
  for (final id in inputIds) {
    if (!responseIds.contains(id)) {
      throw MissingSegmentIdException(missingId: id);
    }
  }
}
```

---

## 4. Deterministic CJK Subtitle Breaking Rules

```dart
class SubtitleLineBreaker {
  static const int maxCharactersPerLine = 42;
  static const int maxLinesPerCue = 2;

  /// Splits an English subtitle text into at most 2 balanced lines
  static String formatCueText(String text) {
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= maxCharactersPerLine) {
      return clean;
    }

    final words = clean.split(' ');
    final midpoint = clean.length ~/ 2;
    int bestBreakIndex = -1;
    int minDiffFromMid = 9999;

    int currentLength = 0;
    for (int i = 0; i < words.length - 1; i++) {
      currentLength += words[i].length + (i == 0 ? 0 : 1);
      final diff = (currentLength - midpoint).abs();

      // Prioritize breaks after punctuation marks
      final wordEndsWithPunct = words[i].endsWith(',') || words[i].endsWith('.') || words[i].endsWith('?');
      final adjustedDiff = wordEndsWithPunct ? diff - 10 : diff;

      if (adjustedDiff < minDiffFromMid) {
        minDiffFromMid = adjustedDiff;
        bestBreakIndex = i;
      }
    }

    if (bestBreakIndex != -1) {
      final line1 = words.sublist(0, bestBreakIndex + 1).join(' ');
      final line2 = words.sublist(bestBreakIndex + 1).join(' ');
      return '$line1\n$line2';
    }

    return clean;
  }
}
```

---

## 5. Token-Efficient Instructions for AI Coding Agents

When working on this repository, observe the following rules to conserve tokens and avoid architectural blunders:
1. **Never redefine schemas**: Reference `SCHEMA.md` directly for database tables and DTOs.
2. **Never re-invent media extraction**: Consult §4 of `ChatGPT-Build Subtitle Generator-20261030-1630.md` for the per-platform engine selection.
3. **Never upload video or audio to Firebase**: Only `.srt` and `.vtt` text files touch Firebase Cloud Storage.
4. **Never ask LLMs to generate timestamps**: Timestamps come 100% from Stage 1 acoustic models.
5. **Always clean up temporary audio chunks**: Delete individual chunk files immediately after their transcription response is persisted in SQLite.

