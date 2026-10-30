class SubtitleCue {
  final int index;
  final double startSeconds;
  final double endSeconds;
  final String text;

  const SubtitleCue({
    required this.index,
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
  });

  String get srtTimecode {
    return '${_formatTime(startSeconds, ',')} --> ${_formatTime(endSeconds, ',')}';
  }

  String get vttTimecode {
    return '${_formatTime(startSeconds, '.')} --> ${_formatTime(endSeconds, '.')}';
  }

  static String _formatTime(double seconds, String decimalSeparator) {
    if (seconds < 0) seconds = 0;
    final int hrs = seconds ~/ 3600;
    final int mins = (seconds % 3600) ~/ 60;
    final int secs = seconds.toInt() % 60;
    final int ms = ((seconds - seconds.toInt()) * 1000).round();
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}$decimalSeparator${ms.toString().padLeft(3, '0')}';
  }

  SubtitleCue copyWith({
    int? index,
    double? startSeconds,
    double? endSeconds,
    String? text,
  }) {
    return SubtitleCue(
      index: index ?? this.index,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      text: text ?? this.text,
    );
  }
}

