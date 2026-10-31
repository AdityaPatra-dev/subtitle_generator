import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/providers.dart';
import '../../core/storage/database.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFileLocationDialog(BuildContext context, SubtitleEntry sub) {
    final srtFile = File(sub.localSrtPath);
    final folderPath = srtFile.parent.path;
    final vttPath = sub.localVttPath;

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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved File Location',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        'Where this subtitle is stored on device',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Directory Box
              const Text('Directory Folder:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

              // SRT File Path Box
              const Text('SRT File:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: SelectableText(
                  sub.localSrtPath,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.accentCyan),
                ),
              ),

              if (vttPath != null && vttPath.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('VTT File:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: SelectableText(
                    vttPath,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.amberAccent),
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: sub.localSrtPath));
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
                      label: const Text('Copy File Path', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (await srtFile.exists()) {
                          await OpenFilex.open(srtFile.path);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('File not found on storage')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open File', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
    final subtitlesAsync = ref.watch(activeSubtitlesStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Screen Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.subtitles_rounded, color: AppTheme.accentCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Subtitle Library',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by video title, language...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.white54),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.white54),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.darkCard,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim().toLowerCase());
                    },
                  ),
                ],
              ),
            ),

            // --- Subtitles List ---
            Expanded(
              child: subtitlesAsync.when(
                data: (subtitles) {
                  final filtered = subtitles.where((s) {
                    if (_searchQuery.isEmpty) return true;
                    return s.title.toLowerCase().contains(_searchQuery) ||
                        s.sourceLanguage.toLowerCase().contains(_searchQuery) ||
                        s.originalFilename.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.darkCard,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: const Icon(Icons.subtitles_off_rounded, size: 30, color: Colors.white38),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No subtitles created yet' : 'No matching subtitles found',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Generate subtitles in the Generate tab to see them here.',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final sub = filtered[i];
                      final durMins = (sub.durationSeconds / 60).toStringAsFixed(1);
                      final kb = (sub.fileSizeBytes.toInt() / 1024).toStringAsFixed(1);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sub.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '${sub.sourceLanguage.toUpperCase()} ➔ EN',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accentCyan,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildTag(Icons.timer_outlined, '$durMins mins'),
                                  _buildTag(Icons.short_text_rounded, '${sub.cueCount} cues'),
                                  _buildTag(Icons.memory_rounded, '${kb}KB'),
                                  _buildTag(Icons.smart_toy_outlined, sub.providerUsed),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Folder Icon Button: Shows exactly where it is saved
                                  IconButton(
                                    icon: const Icon(Icons.folder_open_rounded, color: AppTheme.accentCyan, size: 21),
                                    tooltip: 'Show File Location',
                                    onPressed: () => _showFileLocationDialog(context, sub),
                                  ),
                                  const SizedBox(width: 4),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final file = File(sub.localSrtPath);
                                      if (await file.exists()) {
                                        final srt = await file.readAsString();
                                        await Clipboard.setData(ClipboardData(text: srt));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(Icons.check, color: Colors.greenAccent, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('SRT copied to clipboard!'),
                                                ],
                                              ),
                                              backgroundColor: const Color(0xFF1E293B),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.borderSubtle),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.copy_rounded, size: 15, color: Colors.white70),
                                    label: const Text('Copy', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditorScreen(subtitle: sub),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryViolet,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                                    label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppTheme.darkCard,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                          title: const Text('Delete Subtitle?'),
                                          content: Text('Remove "${sub.title}" from library?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ref.read(databaseProvider).softDeleteSubtitle(sub.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentCyan),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading library: $err', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}
