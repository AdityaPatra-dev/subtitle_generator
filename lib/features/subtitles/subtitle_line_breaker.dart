class SubtitleLineBreaker {
  static const int maxCharactersPerLine = 42;
  static const int maxLinesPerCue = 2;

  /// Splits an English subtitle text into at most 2 balanced lines conforming to BBC/Netflix standards
  static String formatCueText(String text) {
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= maxCharactersPerLine) {
      return clean;
    }

    final words = clean.split(' ');
    if (words.length <= 1) {
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
          words[i].endsWith(':');
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
}

