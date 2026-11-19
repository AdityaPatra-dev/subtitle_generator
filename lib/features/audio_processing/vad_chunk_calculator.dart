import '../../core/constants/enums.dart';

class SilenceInterval {
  final double start;
  final double end;
  double get duration => end - start;
  double get midpoint => start + (duration / 2);

  const SilenceInterval({required this.start, required this.end});

  @override
  String toString() => 'SilenceInterval(${start.toStringAsFixed(2)}s -> ${end.toStringAsFixed(2)}s, dur: ${duration.toStringAsFixed(2)}s)';
}

class ChunkDurationConfig {
  final double targetDurationSeconds;
  final double minDurationSeconds;
  final double maxDurationSeconds;
  final int maxConcurrency;

  const ChunkDurationConfig({
    required this.targetDurationSeconds,
    required this.minDurationSeconds,
    required this.maxDurationSeconds,
    required this.maxConcurrency,
  });
}

class VadChunkCalculator {
  static final RegExp _silenceStartRegex = RegExp(r'silence_start:\s*([0-9.]+)');
  static final RegExp _silenceEndRegex = RegExp(r'silence_end:\s*([0-9.]+)\s*\|\s*silence_duration:\s*([0-9.]+)');

  /// Resolves optimal chunk duration parameters based on provider & user strategy
  static ChunkDurationConfig getChunkConfig({
    required TranscriptionProviderType provider,
    required ProcessingStrategy strategy,
  }) {
    switch (provider) {
      case TranscriptionProviderType.groqWhisperLargeV3:
        // Whisper has a 30s sliding window. Chunks capped at 3.5m to guarantee zero drift.
        // Free tier rate limit: 20 RPM & 7,200 audio-sec/hr.
        if (strategy == ProcessingStrategy.parallel) {
          return const ChunkDurationConfig(
            targetDurationSeconds: 180.0, // 3 mins
            minDurationSeconds: 150.0,    // 2.5 mins
            maxDurationSeconds: 210.0,    // 3.5 mins max (zero drift)
            maxConcurrency: 2,
          );
        } else {
          return const ChunkDurationConfig(
            targetDurationSeconds: 180.0,
            minDurationSeconds: 150.0,
            maxDurationSeconds: 210.0,
            maxConcurrency: 1,
          );
        }

      case TranscriptionProviderType.gemini25Transcribe:
        // Gemini has 1M context with unified audio-token attention. 0 drift.
        // Free tier rate limit: 15 RPM.
        if (strategy == ProcessingStrategy.parallel) {
          return const ChunkDurationConfig(
            targetDurationSeconds: 240.0, // 4 mins
            minDurationSeconds: 180.0,    // 3 mins
            maxDurationSeconds: 300.0,    // 5 mins
            maxConcurrency: 2,           // 2 workers consumes ~8 RPM max (<15 RPM)
          );
        } else if (strategy == ProcessingStrategy.largeChunk) {
          return const ChunkDurationConfig(
            targetDurationSeconds: 720.0, // 12 mins
            minDurationSeconds: 600.0,    // 10 mins
            maxDurationSeconds: 900.0,    // 15 mins (single chunk if <= 15m!)
            maxConcurrency: 1,
          );
        } else {
          return const ChunkDurationConfig(
            targetDurationSeconds: 240.0,
            minDurationSeconds: 180.0,
            maxDurationSeconds: 300.0,
            maxConcurrency: 1,
          );
        }

      case TranscriptionProviderType.deepgramNova3:
        // Deepgram uses frame-level CTC acoustic alignment. 0 drift.
        if (strategy == ProcessingStrategy.parallel) {
          return const ChunkDurationConfig(
            targetDurationSeconds: 300.0, // 5 mins
            minDurationSeconds: 240.0,    // 4 mins
            maxDurationSeconds: 360.0,    // 6 mins
            maxConcurrency: 2,
          );
        } else if (strategy == ProcessingStrategy.largeChunk) {
          return const ChunkDurationConfig(
            targetDurationSeconds: 720.0, // 12 mins
            minDurationSeconds: 600.0,    // 10 mins
            maxDurationSeconds: 900.0,    // 15 mins
            maxConcurrency: 1,
          );
        } else {
          return const ChunkDurationConfig(
            targetDurationSeconds: 300.0,
            minDurationSeconds: 240.0,
            maxDurationSeconds: 360.0,
            maxConcurrency: 1,
          );
        }
    }
  }

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
    double targetChunkDurationSeconds = 240.0, // 4 minutes (optimal for speed & low API overhead)
    double minChunkDurationSeconds = 180.0,    // 3 minutes
    double maxChunkDurationSeconds = 300.0,   // 5 minutes
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

