import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'media_engine.dart';

class ProcessMediaEngine implements MediaEngine {
  final String ffmpegPath;
  final String ffprobePath;

  const ProcessMediaEngine({
    this.ffmpegPath = 'ffmpeg',
    this.ffprobePath = 'ffprobe',
  });

  @override
  Future<MediaInfo> probe(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileNotFoundException('File not found: $filePath');
    }
    final fileSizeBytes = await file.length();

    final result = await Process.run(
      ffprobePath,
      [
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        '-select_streams', 'a',
        filePath,
      ],
    );

    if (result.exitCode != 0) {
      throw MediaEngineException('ffprobe failed: ${result.stderr}');
    }

    final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final format = json['format'] as Map<String, dynamic>? ?? {};
    final durationSec = double.tryParse(format['duration']?.toString() ?? '0.0') ?? 0.0;

    final streams = json['streams'] as List<dynamic>? ?? [];
    final List<AudioTrackInfo> tracks = [];

    for (int i = 0; i < streams.length; i++) {
      final s = streams[i] as Map<String, dynamic>;
      final tags = s['tags'] as Map<String, dynamic>? ?? {};
      final disposition = s['disposition'] as Map<String, dynamic>? ?? {};

      tracks.add(AudioTrackInfo(
        streamIndex: s['index'] as int? ?? i,
        codecName: s['codec_name']?.toString() ?? 'unknown',
        channels: s['channels'] as int? ?? 2,
        language: tags['language']?.toString(),
        title: tags['title']?.toString(),
        bitRateBps: int.tryParse(s['bit_rate']?.toString() ?? ''),
        durationSeconds: double.tryParse(s['duration']?.toString() ?? '') ?? durationSec,
        isDefault: (disposition['default'] as int? ?? 0) == 1,
      ));
    }

    return MediaInfo(
      filePath: filePath,
      durationSeconds: durationSec,
      fileSizeBytes: fileSizeBytes,
      audioTracks: tracks,
    );
  }

  @override
  Future<AudioExtractionResult> extractAudio({
    required String inputPath,
    required String outputPath,
    required int audioStreamIndex,
    required AudioExtractionConfig config,
  }) async {
    final outFile = File(outputPath);
    if (await outFile.exists()) {
      await outFile.delete();
    }
    await outFile.parent.create(recursive: true);

    final List<String> args = [
      '-i', inputPath,
      '-vn',
      '-map', '0:$audioStreamIndex',
    ];

    final filterStr = config.toFfmpegFilterString();
    if (filterStr.isNotEmpty) {
      args.addAll(['-af', filterStr]);
    }

    args.addAll([
      '-c:a', 'libmp3lame',
      '-b:a', '${config.bitrateKbps}k',
      outputPath,
      '-y',
    ]);

    final result = await Process.run(ffmpegPath, args);
    if (result.exitCode != 0) {
      throw MediaEngineException('ffmpeg audio extraction failed: ${result.stderr}');
    }

    if (!await outFile.exists()) {
      throw const MediaEngineException('Audio extraction produced no output file');
    }

    final sizeBytes = await outFile.length();
    // Probe output audio to get exact extracted duration
    double extractedDuration = 0.0;
    try {
      final info = await probe(outputPath);
      extractedDuration = info.durationSeconds;
    } catch (_) {}

    return AudioExtractionResult(
      outputPath: outputPath,
      fileSizeBytes: sizeBytes,
      durationSeconds: extractedDuration,
    );
  }

  @override
  Future<String> detectSilence({
    required String audioPath,
    double noiseDb = -30.0,
    double minDurationSeconds = 0.4,
  }) async {
    final result = await Process.run(
      ffmpegPath,
      [
        '-i', audioPath,
        '-af', 'silencedetect=noise=${noiseDb}dB:d=$minDurationSeconds',
        '-f', 'null',
        '-',
      ],
    );

    // silencedetect outputs to stderr
    return result.stderr as String;
  }

  @override
  Future<List<String>> splitAudioAtTimestamps({
    required String inputPath,
    required List<double> splitPointsSeconds,
    required String outputDir,
    required String prefix,
  }) async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final List<String> chunkPaths = [];
    double currentStart = 0.0;
    final List<double> allBoundaries = [...splitPointsSeconds];

    // Determine end time of original audio
    final probeInfo = await probe(inputPath);
    final totalDuration = probeInfo.durationSeconds;
    if (allBoundaries.isEmpty || allBoundaries.last < totalDuration) {
      allBoundaries.add(totalDuration);
    }

    for (int i = 0; i < allBoundaries.length; i++) {
      final end = allBoundaries[i];
      if (end <= currentStart) continue;

      final chunkFile = p.join(outputDir, '${prefix}_chunk_${i.toString().padLeft(2, '0')}.mp3');
      final duration = end - currentStart;

      final result = await Process.run(
        ffmpegPath,
        [
          '-ss', currentStart.toStringAsFixed(3),
          '-t', duration.toStringAsFixed(3),
          '-i', inputPath,
          '-c', 'copy',
          chunkFile,
          '-y',
        ],
      );

      if (result.exitCode != 0) {
        throw MediaEngineException('Failed to split audio chunk $i: ${result.stderr}');
      }

      chunkPaths.add(chunkFile);
      currentStart = end;
    }

    return chunkPaths;
  }
}
