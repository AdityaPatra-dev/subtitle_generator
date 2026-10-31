class AudioTrackInfo {
  final int streamIndex;
  final String codecName;
  final int channels;
  final String? language;
  final String? title;
  final int? bitRateBps;
  final double durationSeconds;
  final bool isDefault;

  const AudioTrackInfo({
    required this.streamIndex,
    required this.codecName,
    required this.channels,
    this.language,
    this.title,
    this.bitRateBps,
    required this.durationSeconds,
    this.isDefault = false,
  });

  String get displayName {
    final langStr = (language != null && language!.isNotEmpty) ? language!.toUpperCase() : 'Unknown';
    final codecStr = codecName.toUpperCase();
    final chanStr = channels == 1 ? 'Mono' : channels == 2 ? 'Stereo' : '$channels ch';
    final titleStr = (title != null && title!.isNotEmpty) ? ' ($title)' : '';
    return 'Track $streamIndex: $langStr · $codecStr · $chanStr$titleStr';
  }
}

class MediaInfo {
  final String filePath;
  final double durationSeconds;
  final int fileSizeBytes;
  final List<AudioTrackInfo> audioTracks;

  const MediaInfo({
    required this.filePath,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.audioTracks,
  });

  AudioTrackInfo? get primaryAudioTrack {
    if (audioTracks.isEmpty) return null;
    return audioTracks.firstWhere(
      (t) => t.isDefault,
      orElse: () => audioTracks.first,
    );
  }
}

class AudioExtractionConfig {
  final int sampleRate;
  final bool mono;
  final int highPassHz;
  final int lowPassHz;
  final bool loudnorm;
  final int bitrateKbps;

  const AudioExtractionConfig({
    this.sampleRate = 16000,
    this.mono = true,
    this.highPassHz = 80,
    this.lowPassHz = 8000,
    this.loudnorm = false,
    this.bitrateKbps = 48,
  });

  String toFfmpegFilterString() {
    final List<String> filters = [];
    if (highPassHz > 0) {
      filters.add('highpass=f=$highPassHz');
    }
    if (lowPassHz > 0) {
      filters.add('lowpass=f=$lowPassHz');
    }
    if (loudnorm) {
      filters.add('loudnorm=I=-16:TP=-1.5:LRA=11');
    }
    if (sampleRate > 0 || mono) {
      final sr = sampleRate > 0 ? 'sample_rates=$sampleRate:' : '';
      final ch = mono ? 'channel_layouts=mono' : '';
      filters.add('aformat=$sr$ch'.replaceAll(RegExp(r':$'), ''));
    }
    return filters.join(',');
  }
}

class AudioExtractionResult {
  final String outputPath;
  final int fileSizeBytes;
  final double durationSeconds;

  const AudioExtractionResult({
    required this.outputPath,
    required this.fileSizeBytes,
    required this.durationSeconds,
  });
}

abstract class MediaEngine {
  Future<MediaInfo> probe(String filePath);

  Future<AudioExtractionResult> extractAudio({
    required String inputPath,
    required String outputPath,
    required int audioStreamIndex,
    required AudioExtractionConfig config,
  });

  Future<List<String>> splitAudioAtTimestamps({
    required String inputPath,
    required List<double> splitPointsSeconds,
    required String outputDir,
    required String prefix,
  });

  Future<String> detectSilence({
    required String audioPath,
    double noiseDb = -30.0,
    double minDurationSeconds = 0.4,
  });
}

class MediaEngineException implements Exception {
  final String message;
  const MediaEngineException(this.message);
  @override
  String toString() => 'MediaEngineException: $message';
}

class FileNotFoundException implements Exception {
  final String message;
  const FileNotFoundException(this.message);
  @override
  String toString() => 'FileNotFoundException: $message';
}

