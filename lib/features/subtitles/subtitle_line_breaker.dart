import 'subtitle_cue.dart';

class SubtitleLineBreaker {
  static const int maxCharactersPerLine = 42;
  static const int maxCjkCharactersPerLine = 18;
  static const int maxLinesPerCue = 2;
  static const double maxCueDurationSeconds = 6.0;
  static const int maxWesternCueCharacters = 75;
  static const int maxCjkCueCharacters = 28;

  static bool isCjk(String text) {
    return RegExp(r'[\u4e00-\u9fa5\u3040-\u30ff\uac00-\ud7af]').hasMatch(text);
  }

  /// Splits an English/Roman or Asian subtitle text into at most 2 balanced lines conforming to BBC/Netflix standards
  static String formatCueText(String text) {
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cjk = isCjk(clean);
    final limit = cjk ? maxCjkCharactersPerLine : maxCharactersPerLine;

    if (clean.length <= limit) {
      return clean;
    }

    if (cjk) {
      // For Asian text without spaces, balance around midpoint or comma
      final midpoint = clean.length ~/ 2;
      int bestBreak = -1;
      int minDiff = 999;

      for (int i = 0; i < clean.length - 1; i++) {
        final char = clean[i];
        if (char == '，' || char == '、' || char == '；' || char == ' ' || char == '。' || char == '！' || char == '？') {
          final diff = (i - midpoint).abs();
          if (diff < minDiff) {
            minDiff = diff;
            bestBreak = i + 1;
          }
        }
      }

      if (bestBreak != -1 && bestBreak < clean.length) {
        return '${clean.substring(0, bestBreak).trim()}\n${clean.substring(bestBreak).trim()}';
      }

      // Fallback: split at exact midpoint if longer than limit
      return '${clean.substring(0, midpoint)}\n${clean.substring(midpoint)}';
    }

    final words = clean.split(' ');
    if (words.length <= 1) {
      if (clean.length > limit) {
        final mid = clean.length ~/ 2;
        return '${clean.substring(0, mid)}\n${clean.substring(mid)}';
      }
      return clean;
    }

    final midpoint = clean.length ~/ 2;
    int bestBreakIndex = -1;
    int minDiffFromMid = 99999;

    int currentLength = 0;
    for (int i = 0; i < words.length - 1; i++) {
      currentLength += words[i].length + (i == 0 ? 0 : 1);
      final diff = (currentLength - midpoint).abs();

      // Give bonus weight to breaks after punctuation marks
      final wordEndsWithPunct = words[i].endsWith(',') ||
          words[i].endsWith('.') ||
          words[i].endsWith('?') ||
          words[i].endsWith('!') ||
          words[i].endsWith(':') ||
          words[i].endsWith(';');
      final adjustedDiff = wordEndsWithPunct ? diff - 12 : diff;

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

  /// Splits a potentially long transcription segment (which may be a paragraph or long utterance)
  /// into multiple short, timed subtitle cues so that viewers never see a giant paragraph at once.
  static List<SubtitleCue> breakLongSegment({
    required double startSeconds,
    required double endSeconds,
    required String text,
    int startingIndex = 1,
  }) {
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return [];

    final totalDuration = endSeconds - startSeconds;
    final cjk = isCjk(clean);
    final maxChars = cjk ? maxCjkCueCharacters : maxWesternCueCharacters;

    // If already short enough, return a single cue
    if (clean.length <= maxChars && totalDuration <= maxCueDurationSeconds && !_hasMultipleSentences(clean)) {
      return [
        SubtitleCue(
          index: startingIndex,
          startSeconds: startSeconds,
          endSeconds: endSeconds,
          text: formatCueText(clean),
        ),
      ];
    }

    // Split by sentence boundaries or natural punctuation first
    final rawPhrases = _splitIntoPhrases(clean, cjk);
    if (rawPhrases.isEmpty) {
      return [
        SubtitleCue(
          index: startingIndex,
          startSeconds: startSeconds,
          endSeconds: endSeconds,
          text: formatCueText(clean),
        ),
      ];
    }

    // Merge very short phrases if they fit comfortably
    final List<String> balancedPhrases = [];
    String buffer = '';
    for (final p in rawPhrases) {
      if (buffer.isEmpty) {
        buffer = p;
      } else {
        final joiner = cjk ? '' : ' ';
        if ((buffer.length + joiner.length + p.length) <= maxChars) {
          buffer = '$buffer$joiner$p';
        } else {
          balancedPhrases.add(buffer);
          buffer = p;
        }
      }
    }
    if (buffer.isNotEmpty) {
      balancedPhrases.add(buffer);
    }

    if (balancedPhrases.length <= 1) {
      // Force chunking if still one giant phrase
      final chunks = cjk
          ? _chunkCjkChars(clean, maxCharsPerChunk: maxCjkCueCharacters)
          : _chunkWords(clean, maxWordsPerChunk: 9);

      return _interpolateCues(
        chunks: chunks,
        startSeconds: startSeconds,
        totalDuration: totalDuration,
        startingIndex: startingIndex,
      );
    }

    return _interpolateCues(
      chunks: balancedPhrases,
      startSeconds: startSeconds,
      totalDuration: totalDuration,
      startingIndex: startingIndex,
    );
  }

  static bool _hasMultipleSentences(String text) {
    final terminators = RegExp(r'[.!?。！？]').allMatches(text);
    return terminators.length > 1;
  }

  static List<String> _splitIntoPhrases(String text, bool cjk) {
    final List<String> phrases = [];
    // If CJK, also split on commas and semicolons when text is long
    final pattern = cjk
        ? RegExp(r'([^.!?。！？，,；;]+[.!?。！？，,；;]*)')
        : RegExp(r'([^.!?。！？]+[.!?。！？]*)');

    final matches = pattern.allMatches(text);
    for (final m in matches) {
      final part = m.group(0)?.trim() ?? '';
      if (part.isNotEmpty) {
        phrases.add(part);
      }
    }

    return phrases.isNotEmpty ? phrases : [text];
  }

  static List<String> _chunkCjkChars(String text, {int maxCharsPerChunk = 20}) {
    if (text.length <= maxCharsPerChunk) return [text];
    final List<String> chunks = [];
    for (int i = 0; i < text.length; i += maxCharsPerChunk) {
      final end = (i + maxCharsPerChunk < text.length) ? i + maxCharsPerChunk : text.length;
      chunks.add(text.substring(i, end));
    }
    return chunks;
  }

  static List<String> _chunkWords(String text, {int maxWordsPerChunk = 9}) {
    final words = text.split(' ');
    if (words.length <= maxWordsPerChunk) return [text];

    final List<String> chunks = [];
    for (int i = 0; i < words.length; i += maxWordsPerChunk) {
      final end = (i + maxWordsPerChunk < words.length) ? i + maxWordsPerChunk : words.length;
      chunks.add(words.sublist(i, end).join(' '));
    }
    return chunks;
  }

  static List<SubtitleCue> _interpolateCues({
    required List<String> chunks,
    required double startSeconds,
    required double totalDuration,
    required int startingIndex,
  }) {
    final totalChars = chunks.fold<int>(0, (sum, c) => sum + c.length);
    if (totalChars <= 0) return [];

    final List<SubtitleCue> result = [];
    double currentStart = startSeconds;

    for (int i = 0; i < chunks.length; i++) {
      final chunkText = chunks[i].trim();
      if (chunkText.isEmpty) continue;

      final proportion = chunkText.length / totalChars;
      double chunkDuration = totalDuration * proportion;

      if (chunkDuration < 1.2) chunkDuration = 1.2;

      final chunkEnd = (i == chunks.length - 1)
          ? startSeconds + totalDuration
          : currentStart + chunkDuration;

      result.add(
        SubtitleCue(
          index: startingIndex + result.length,
          startSeconds: currentStart,
          endSeconds: chunkEnd > currentStart ? chunkEnd : currentStart + 1.0,
          text: formatCueText(chunkText),
        ),
      );

      currentStart = chunkEnd;
    }

    return result;
  }
}
