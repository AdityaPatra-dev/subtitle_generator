import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'media_engine.dart';

class FfmpegKitMediaEngine implements MediaEngine {
  const FfmpegKitMediaEngine();

  @override
  Future<MediaInfo> probe(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileNotFoundException('File not found: $filePath');
    }
    final fileSizeBytes = await file.length();

    final session = await FFprobeKit.getMediaInformation(filePath);
    final mediaInfo = session.getMediaInformation();

    if (mediaInfo == null) {
      final logs = await session.getAllLogsAsString();
      final failStack = await session.getFailStackTrace();
      throw MediaEngineException(
        'Failed to probe media with FFprobeKit: $logs ${failStack ?? ""}'.trim(),
      );
    }

    final durationSec = double.tryParse(mediaInfo.getDuration() ?? '0.0') ?? 0.0;
    final streams = mediaInfo.getStreams();
    final List<AudioTrackInfo> audioTracks = [];

    for (int i = 0; i < streams.length; i++) {
      final s = streams[i];
      if (s.getType()?.toLowerCase() != 'audio') continue;

      final tags = s.getTags() ?? {};
      final streamIndex = int.tryParse(s.getProperty('index')?.toString() ?? '') ?? i;
      final codecName = s.getCodec() ?? s.getProperty('codec_name')?.toString() ?? 'unknown';
      final channels = int.tryParse(s.getProperty('channels')?.toString() ?? '') ?? 2;
      final language = tags['language']?.toString();
      final title = tags['title']?.toString();
      final bitRate = int.tryParse(s.getProperty('bit_rate')?.toString() ?? '');
      final streamDuration = double.tryParse(s.getProperty('duration')?.toString() ?? '') ?? durationSec;
      final disposition = s.getProperty('disposition') as Map<dynamic, dynamic>? ?? {};
      final isDefault = disposition['default'] == 1 || disposition['default'] == '1';

      audioTracks.add(AudioTrackInfo(
        streamIndex: streamIndex,
        codecName: codecName,
        channels: channels,
        language: language,
        title: title,
        bitRateBps: bitRate,
        durationSeconds: streamDuration,
        isDefault: isDefault,
      ));
    }

    return MediaInfo(
      filePath: filePath,
      durationSeconds: durationSec,
      fileSizeBytes: fileSizeBytes,
      audioTracks: audioTracks,
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

    final session = await FFmpegKit.executeWithArguments(args);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      final failStack = await session.getFailStackTrace();
      throw MediaEngineException(
        'Audio extraction failed with FFmpegKit (code $returnCode): $logs ${failStack ?? ""}'.trim(),
      );
    }

    final resultFile = File(outputPath);
    if (!await resultFile.exists()) {
      throw MediaEngineException('Extracted audio file was not created: $outputPath');
    }

    final size = await resultFile.length();
    // Estimate or probe duration
    final probeResult = await probe(outputPath);

    return AudioExtractionResult(
      outputPath: outputPath,
      fileSizeBytes: size,
      durationSeconds: probeResult.durationSeconds,
    );
  }

  @override
  Future<List<String>> splitAudioAtTimestamps({
    required String inputPath,
    required List<double> splitPointsSeconds,
    required String outputDir,
    required String prefix,
  }) async {
    await Directory(outputDir).create(recursive: true);

    final List<String> chunkPaths = [];
    final totalPoints = splitPointsSeconds.length;

    for (int i = 0; i < totalPoints - 1; i++) {
      final start = splitPointsSeconds[i];
      final end = splitPointsSeconds[i + 1];
      final chunkName = '${prefix}_chunk_${i.toString().padLeft(4, '0')}.mp3';
      final chunkPath = p.join(outputDir, chunkName);

      final List<String> args = [
        '-ss', start.toStringAsFixed(3),
        '-to', end.toStringAsFixed(3),
        '-i', inputPath,
        '-c', 'copy',
        chunkPath,
        '-y',
      ];

      final session = await FFmpegKit.executeWithArguments(args);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        throw MediaEngineException(
          'Splitting chunk $i failed ($start-$end) with FFmpegKit: $logs',
        );
      }

      chunkPaths.add(chunkPath);
    }

    return chunkPaths;
  }

  @override
  Future<String> detectSilence({
    required String audioPath,
    double noiseDb = -30.0,
    double minDurationSeconds = 0.4,
  }) async {
    final List<String> args = [
      '-i', audioPath,
      '-af', 'silencedetect=noise=${noiseDb}dB:d=$minDurationSeconds',
      '-f', 'null',
      '-',
    ];

    final session = await FFmpegKit.executeWithArguments(args);
    final logs = await session.getAllLogsAsString() ?? '';
    return logs;
  }
}
