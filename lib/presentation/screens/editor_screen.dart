import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/providers.dart';
import '../../core/storage/database.dart';
import '../../features/subtitles/subtitle_cue.dart';
import '../../features/subtitles/subtitle_line_breaker.dart';
import '../../features/subtitles/subtitle_serializer.dart';
import '../theme/app_theme.dart';

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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text('Subtitles saved successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _addNewCue() {
    final lastEnd = _cues.isNotEmpty ? _cues.last.endSeconds : 0.0;
    setState(() {
      _cues.add(
        SubtitleCue(
          index: _cues.length + 1,
          startSeconds: lastEnd + 0.1,
          endSeconds: lastEnd + 3.0,
          text: 'New subtitle line',
        ),
      );
    });
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

  void _showLocationDialog(BuildContext context) {
    final file = File(widget.subtitle.localSrtPath);
    final folderPath = file.parent.path;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_open_rounded, color: AppTheme.accentCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Subtitle File Location',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Folder Directory:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: SelectableText(
                  folderPath,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              const Text('SRT File Path:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: SelectableText(
                  widget.subtitle.localSrtPath,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.accentCyan),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: widget.subtitle.localSrtPath));
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File path copied to clipboard!'),
                              backgroundColor: Color(0xFF1E293B),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                      label: const Text('Copy Path', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (await file.exists()) {
                          await OpenFilex.open(file.path);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open File', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          widget.subtitle.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Folder icon button showing file location
          IconButton(
            icon: const Icon(Icons.folder_open_rounded, color: AppTheme.accentCyan, size: 22),
            tooltip: 'Show File Location',
            onPressed: () => _showLocationDialog(context),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCue,
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Line', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
          : _cues.isEmpty
              ? const Center(
                  child: Text('No subtitle cues found.', style: TextStyle(color: Colors.white60)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _cues.length,
                  itemBuilder: (context, i) {
                    final cue = _cues[i];
                    final lines = cue.text.split('\n');
                    final isOverCpl = lines.any((l) => l.length > SubtitleLineBreaker.maxCharactersPerLine);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '#${cue.index}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.accentCyan),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.schedule_rounded, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  cue.srtTimecode,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteCue(i),
                                  tooltip: 'Delete Line',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue: cue.text,
                              maxLines: null,
                              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white),
                              decoration: InputDecoration(
                                isDense: true,
                                fillColor: AppTheme.darkSurface.withValues(alpha: 0.4),
                                helperText: isOverCpl ? 'Warning: Line exceeds 42 characters' : null,
                                helperStyle: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                              ),
                              onChanged: (val) {
                                _cues[i] = cue.copyWith(text: val);
                              },
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildNudgeButton('Start -100ms', () => _nudgeStart(i, -0.1)),
                                _buildNudgeButton('Start +100ms', () => _nudgeStart(i, 0.1)),
                                _buildNudgeButton('End -100ms', () => _nudgeEnd(i, -0.1)),
                                _buildNudgeButton('End +100ms', () => _nudgeEnd(i, 0.1)),
                                OutlinedButton.icon(
                                  onPressed: () => _splitCue(i),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.borderSubtle),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.call_split_rounded, size: 14, color: AppTheme.accentCyan),
                                  label: const Text('Split Line', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                ),
                                if (i < _cues.length - 1)
                                  OutlinedButton.icon(
                                    onPressed: () => _mergeNext(i),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.borderSubtle),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.merge_rounded, size: 14, color: AppTheme.accentCyan),
                                    label: const Text('Merge Next', style: TextStyle(fontSize: 11, color: Colors.white70)),
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

  Widget _buildNudgeButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
    );
  }
}
