import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/features/audio_processing/vad_chunk_calculator.dart';

void main() {
  group('VadChunkCalculator', () {
    test('parses FFmpeg silencedetect output accurately', () {
      const mockStderr = '''
[silencedetect @ 0x55d2890] silence_start: 124.52
[silencedetect @ 0x55d2890] silence_end: 125.32 | silence_duration: 0.8
[silencedetect @ 0x55d2890] silence_start: 718.10
[silencedetect @ 0x55d2890] silence_end: 719.50 | silence_duration: 1.4
[silencedetect @ 0x55d2890] silence_start: 722.00
[silencedetect @ 0x55d2890] silence_end: 722.60 | silence_duration: 0.6
''';

      final intervals = VadChunkCalculator.parseSilenceOutput(mockStderr);
      expect(intervals.length, 3);
      expect(intervals[0].start, 124.52);
      expect(intervals[0].end, 125.32);
      expect(intervals[0].duration, closeTo(0.8, 0.001));

      expect(intervals[1].start, 718.10);
      expect(intervals[1].end, 719.50);
      expect(intervals[1].duration, closeTo(1.4, 0.001));
    });

    test('picks natural silence midpoint within window', () {
      final silences = [
        const SilenceInterval(start: 100.0, end: 101.0),
        const SilenceInterval(start: 710.0, end: 712.0), // midpoint 711.0 (dur 2.0)
        const SilenceInterval(start: 730.0, end: 730.5), // midpoint 730.25 (dur 0.5)
      ];

      // Duration: 1800s (30 mins)
      final splits = VadChunkCalculator.calculateSplitPoints(
        totalDurationSeconds: 1800.0,
        silenceIntervals: silences,
        minChunkDurationSeconds: 600.0, // 10 min
        maxChunkDurationSeconds: 840.0, // 14 min
        targetChunkDurationSeconds: 720.0, // 12 min
      );

      expect(splits.isNotEmpty, true);
      // Should pick 711.0 because duration is 2.0s vs 0.5s
      expect(splits[0], 711.0);
    });

    test('falls back to target duration when no silence exists in window', () {
      final silences = [
        const SilenceInterval(start: 100.0, end: 101.0), // outside 600-840 window
      ];

      final splits = VadChunkCalculator.calculateSplitPoints(
        totalDurationSeconds: 1800.0,
        silenceIntervals: silences,
        minChunkDurationSeconds: 600.0,
        maxChunkDurationSeconds: 840.0,
        targetChunkDurationSeconds: 720.0,
      );

      expect(splits.isNotEmpty, true);
      expect(splits[0], 720.0); // exact fallback
    });

    test('enforces 20MB hard cap failsafe check', () {
      expect(VadChunkCalculator.exceedsHardCap(15 * 1024 * 1024), false);
      expect(VadChunkCalculator.exceedsHardCap(20 * 1024 * 1024), false);
      expect(VadChunkCalculator.exceedsHardCap(21 * 1024 * 1024), true);
    });
  });
}

