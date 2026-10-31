import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_cue.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_line_breaker.dart';
import 'package:subtitle_generator/features/subtitles/subtitle_serializer.dart';

void main() {
  group('SubtitleCue and Formatting', () {
    test('formats SRT timecode with comma separator', () {
      const cue = SubtitleCue(
        index: 1,
        startSeconds: 83.450, // 00:01:23,450
        endSeconds: 86.200,   // 00:01:26,200
        text: 'Hello world!',
      );

      expect(cue.srtTimecode, '00:01:23,450 --> 00:01:26,200');
    });

    test('formats WebVTT timecode with period separator', () {
      const cue = SubtitleCue(
        index: 1,
        startSeconds: 83.450,
        endSeconds: 86.200,
        text: 'Hello world!',
      );

      expect(cue.vttTimecode, '00:01:23.450 --> 00:01:26.200');
    });
  });

  group('SubtitleLineBreaker', () {
    test('keeps short text on a single line', () {
      const text = 'Good morning everyone.';
      final formatted = SubtitleLineBreaker.formatCueText(text);
      expect(formatted, text);
      expect(formatted.contains('\n'), false);
    });

    test('splits long dialogue across two balanced lines prioritizing punctuation', () {
      const text = 'Welcome to Tokyo, we hope you enjoy your visit today at the tower!';
      final formatted = SubtitleLineBreaker.formatCueText(text);
      expect(formatted.contains('\n'), true);

      final lines = formatted.split('\n');
      expect(lines.length, 2);
      expect(lines[0].length <= SubtitleLineBreaker.maxCharactersPerLine, true);
      expect(lines[1].length <= SubtitleLineBreaker.maxCharactersPerLine, true);
      expect(lines[0], 'Welcome to Tokyo, we hope you enjoy');
      expect(lines[1], 'your visit today at the tower!');
    });

    test('breakLongSegment breaks Chinese donghua paragraph without spaces into short cues', () {
      const cjkParagraph = '王林深吸口气，踏入恒岳派山门。四周灵气浓郁，群峰隐于云雾之中。他心中暗下决心，定要踏上修仙长生之路。';
      final cues = SubtitleLineBreaker.breakLongSegment(
        startSeconds: 0.0,
        endSeconds: 15.0,
        text: cjkParagraph,
        startingIndex: 1,
      );

      expect(cues.length >= 2, true);
      for (final cue in cues) {
        expect(cue.text.isNotEmpty, true);
        expect(cue.text.length <= 30, true);
      }
    });

    test('breakLongSegment breaks a long paragraph into multiple timed cues', () {
      const paragraph =
          'Wang Lin stood on the mountaintop looking at the ancient sect below. '
          'He knew that the path of cultivation was filled with endless perils. '
          'Yet he had no choice but to step forward and defy the heavens themselves.';

      final cues = SubtitleLineBreaker.breakLongSegment(
        startSeconds: 10.0,
        endSeconds: 25.0,
        text: paragraph,
        startingIndex: 1,
      );

      // Should break into multiple short cues rather than one giant paragraph
      expect(cues.length >= 2, true);
      expect(cues.first.startSeconds, 10.0);
      expect(cues.last.endSeconds, 25.0);

      for (final cue in cues) {
        expect(cue.text.isNotEmpty, true);
        expect(cue.endSeconds > cue.startSeconds, true);
        // Each cue must not exceed max character line constraints
        final lines = cue.text.split('\n');
        for (final line in lines) {
          expect(line.length <= SubtitleLineBreaker.maxCharactersPerLine, true);
        }
      }
    });
  });

  group('SubtitleSerializer', () {
    test('serializes cues to SRT string and parses back', () {
      final cues = [
        const SubtitleCue(
          index: 1,
          startSeconds: 2.5,
          endSeconds: 4.8,
          text: 'First subtitle line',
        ),
        const SubtitleCue(
          index: 2,
          startSeconds: 5.1,
          endSeconds: 8.0,
          text: 'Second subtitle line\nWith two rows',
        ),
      ];

      final srt = SubtitleSerializer.toSrt(cues);
      expect(srt.contains('00:00:02,500 --> 00:00:04,800'), true);
      expect(srt.contains('First subtitle line'), true);

      final parsed = SubtitleSerializer.parseSrt(srt);
      expect(parsed.length, 2);
      expect(parsed[0].startSeconds, 2.5);
      expect(parsed[0].endSeconds, 4.8);
      expect(parsed[0].text, 'First subtitle line');
      expect(parsed[1].text, 'Second subtitle line\nWith two rows');
    });

    test('serializes cues to WebVTT with WEBVTT header', () {
      final cues = [
        const SubtitleCue(
          index: 1,
          startSeconds: 2.5,
          endSeconds: 4.8,
          text: 'First subtitle line',
        ),
      ];

      final vtt = SubtitleSerializer.toVtt(cues, title: 'Episode 1');
      expect(vtt.startsWith('WEBVTT'), true);
      expect(vtt.contains('NOTE Title: Episode 1'), true);
      expect(vtt.contains('00:00:02.500 --> 00:00:04.800'), true);
    });
  });
}
