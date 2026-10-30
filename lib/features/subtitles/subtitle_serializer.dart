import 'subtitle_cue.dart';

class SubtitleSerializer {
  /// Serializes cues to standard SubRip (.srt) UTF-8 format
  static String toSrt(List<SubtitleCue> cues) {
    final buffer = StringBuffer();
    for (int i = 0; i < cues.length; i++) {
      final cue = cues[i];
      buffer.writeln('${i + 1}');
      buffer.writeln(cue.srtTimecode);
      buffer.writeln(cue.text);
      buffer.writeln(); // Empty line separator
    }
    return '${buffer.toString().trimRight()}\n';
  }

  /// Serializes cues to standard WebVTT (.vtt) format
  static String toVtt(List<SubtitleCue> cues, {String? title}) {
    final buffer = StringBuffer();
    buffer.writeln('WEBVTT');
    if (title != null && title.isNotEmpty) {
      buffer.writeln('NOTE Title: $title');
    }
    buffer.writeln();

    for (int i = 0; i < cues.length; i++) {
      final cue = cues[i];
      buffer.writeln('${i + 1}');
      buffer.writeln(cue.vttTimecode);
      buffer.writeln(cue.text);
      buffer.writeln();
    }
    return '${buffer.toString().trimRight()}\n';
  }

  /// Parses an SRT string back into a list of SubtitleCue objects
  static List<SubtitleCue> parseSrt(String srtContent) {
    final List<SubtitleCue> cues = [];
    final blocks = srtContent.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 3) continue;

      final index = int.tryParse(lines[0].trim()) ?? (cues.length + 1);
      final timecodeLine = lines[1].trim();
      final textLines = lines.sublist(2).join('\n').trim();

      final timeParts = timecodeLine.split('-->');
      if (timeParts.length != 2) continue;

      final startSec = _parseSrtTimestamp(timeParts[0].trim());
      final endSec = _parseSrtTimestamp(timeParts[1].trim());

      cues.add(SubtitleCue(
        index: index,
        startSeconds: startSec,
        endSeconds: endSec,
        text: textLines,
      ));
    }

    return cues;
  }

  static double _parseSrtTimestamp(String timeStr) {
    // 00:01:23,450
    final clean = timeStr.replaceAll(',', '.');
    final parts = clean.split(':');
    if (parts.length != 3) return 0.0;

    final hrs = double.tryParse(parts[0]) ?? 0.0;
    final mins = double.tryParse(parts[1]) ?? 0.0;
    final secs = double.tryParse(parts[2]) ?? 0.0;
    return (hrs * 3600) + (mins * 60) + secs;
  }
}
