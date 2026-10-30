import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/storage/database.dart';
import '../../features/subtitles/subtitle_cue.dart';
import '../../features/subtitles/subtitle_line_breaker.dart';
import '../../features/subtitles/subtitle_serializer.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final SubtitleEntry subtitle;

  const EditorScreen({super.key, required this.subtitle});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  List<SubtitleCue> _cues = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCues();
  }

  Future<void> _loadCues() async {
    final file = File(widget.subtitle.localSrtPath);
    if (await file.exists()) {
      final content = await file.readAsString();
      final parsed = SubtitleSerializer.parseSrt(content);
      setState(() {
        _cues = parsed;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final srtContent = SubtitleSerializer.toSrt(_cues);
    final file = File(widget.subtitle.localSrtPath);
    await file.writeAsString(srtContent);

    // If VTT exists, update it too
    if (widget.subtitle.localVttPath != null) {
      final vttContent = SubtitleSerializer.toVtt(_cues, title: widget.subtitle.title);
      await File(widget.subtitle.localVttPath!).writeAsString(vttContent);
    }

    // Update SQLite record
    final db = ref.read(databaseProvider);
    final size = await file.length();
    await db.updateSubtitle(SubtitlesCompanion(
      id: drift.Value(widget.subtitle.id),
      cueCount: drift.Value(_cues.length),
      fileSizeBytes: drift.Value(BigInt.from(size)),
      isDirty: const drift.Value(true),
      updatedAt: drift.Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
    ));

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
    }
  }

  void _nudgeStart(int index, double deltaSeconds) {
    setState(() {
      final cue = _cues[index];
      final newStart = (cue.startSeconds + deltaSeconds).clamp(0.0, cue.endSeconds - 0.1);
      _cues[index] = cue.copyWith(startSeconds: newStart);
    });
  }

  void _nudgeEnd(int index, double deltaSeconds) {
    setState(() {
      final cue = _cues[index];
      final newEnd = (cue.endSeconds + deltaSeconds).clamp(cue.startSeconds + 0.1, 999999.0);
      _cues[index] = cue.copyWith(endSeconds: newEnd);
    });
  }

  void _deleteCue(int index) {
    setState(() {
      _cues.removeAt(index);
      for (int i = 0; i < _cues.length; i++) {
        _cues[i] = _cues[i].copyWith(index: i + 1);
      }
    });
  }

  void _splitCue(int index) {
    final cue = _cues[index];
    final midTime = cue.startSeconds + ((cue.endSeconds - cue.startSeconds) / 2);
    final words = cue.text.split(' ');
    final midWord = words.length ~/ 2;

    final text1 = words.sublist(0, midWord).join(' ');
    final text2 = words.sublist(midWord).join(' ');

    setState(() {
      _cues[index] = cue.copyWith(endSeconds: midTime, text: text1);
      _cues.insert(
        index + 1,
        SubtitleCue(
          index: index + 2,
          startSeconds: midTime,
          endSeconds: cue.endSeconds,
          text: text2,
        ),
      );
      for (int i = 0; i < _cues.length; i++) {
        _cues[i] = _cues[i].copyWith(index: i + 1);
      }
    });
  }

  void _mergeNext(int index) {
    if (index >= _cues.length - 1) return;
    final cur = _cues[index];
    final next = _cues[index + 1];

    setState(() {
      _cues[index] = cur.copyWith(
        endSeconds: next.endSeconds,
        text: '${cur.text} ${next.text}'.trim(),
      );
      _cues.removeAt(index + 1);
      for (int i = 0; i < _cues.length; i++) {
        _cues[i] = _cues[i].copyWith(index: i + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.subtitle.title}'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cues.isEmpty
              ? const Center(child: Text('No subtitle cues found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cues.length,
                  itemBuilder: (context, i) {
                    final cue = _cues[i];
                    final lines = cue.text.split('\n');
                    final isOverCpl = lines.any((l) => l.length > SubtitleLineBreaker.maxCharactersPerLine);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text('#${cue.index}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text(
                                  cue.srtTimecode,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteCue(i),
                                  tooltip: 'Delete Cue',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: cue.text,
                              maxLines: null,
                              decoration: InputDecoration(
                                isDense: true,
                                helperText: isOverCpl ? 'Warning: Line exceeds 42 characters' : null,
                                helperStyle: const TextStyle(color: Colors.orange),
                              ),
                              onChanged: (val) {
                                _cues[i] = cue.copyWith(text: val);
                              },
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _nudgeStart(i, -0.1),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                  child: const Text('Start -100ms'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _nudgeStart(i, 0.1),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                  child: const Text('Start +100ms'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _nudgeEnd(i, -0.1),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                  child: const Text('End -100ms'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _nudgeEnd(i, 0.1),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                  child: const Text('End +100ms'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _splitCue(i),
                                  icon: const Icon(Icons.call_split, size: 16),
                                  label: const Text('Split'),
                                ),
                                if (i < _cues.length - 1)
                                  TextButton.icon(
                                    onPressed: () => _mergeNext(i),
                                    icon: const Icon(Icons.merge, size: 16),
                                    label: const Text('Merge Next'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

