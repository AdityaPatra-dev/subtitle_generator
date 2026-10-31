class SilenceInterval {
  final double start;
  final double end;
  double get duration => end - start;
  double get midpoint => start + (duration / 2);

  const SilenceInterval({required this.start, required this.end});

  @override
  String toString() => 'SilenceInterval(${start.toStringAsFixed(2)}s -> ${end.toStringAsFixed(2)}s, dur: ${duration.toStringAsFixed(2)}s)';
}

class VadChunkCalculator {
  static final RegExp _silenceStartRegex = RegExp(r'silence_start:\s*([0-9.]+)');
  static final RegExp _silenceEndRegex = RegExp(r'silence_end:\s*([0-9.]+)\s*\|\s*silence_duration:\s*([0-9.]+)');

  /// Parses FFmpeg stderr output from silencedetect filter
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
        if (end != null && end > currentStart) {
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
    double targetChunkDurationSeconds = 120.0, // 2 minutes
    double minChunkDurationSeconds = 90.0,    // 1.5 minutes
    double maxChunkDurationSeconds = 150.0,   // 2.5 minutes
  }) {
    // If total audio is shorter than maxChunkDuration, no splits needed
    if (totalDurationSeconds <= maxChunkDurationSeconds) {
      return [];
    }

    final List<double> splitPoints = [];
    double currentWindowStart = 0.0;

    while (currentWindowStart + maxChunkDurationSeconds < totalDurationSeconds) {
      final searchMin = currentWindowStart + minChunkDurationSeconds;
      final searchMax = currentWindowStart + maxChunkDurationSeconds;

      // Find all silent intervals whose midpoint falls within the search window
      final candidates = silenceIntervals
          .where((s) => s.midpoint >= searchMin && s.midpoint <= searchMax)
          .toList();

      if (candidates.isNotEmpty) {
        // Pick the longest silence duration (most natural pause)
        candidates.sort((a, b) => b.duration.compareTo(a.duration));
        final chosenSplit = candidates.first.midpoint;
        splitPoints.add(chosenSplit);
        currentWindowStart = chosenSplit;
      } else {
        // Fallback: No silence pause found in window -> Hard cut at target boundary
        final hardSplit = currentWindowStart + targetChunkDurationSeconds;
        splitPoints.add(hardSplit);
        currentWindowStart = hardSplit;
      }
    }

    return splitPoints;
  }

  /// Hard-cap failsafe: Checks if a file size exceeds the 20MB ceiling
  static bool exceedsHardCap(int fileSizeBytes, [int hardCapBytes = 20 * 1024 * 1024]) {
    return fileSizeBytes > hardCapBytes;
  }
}

