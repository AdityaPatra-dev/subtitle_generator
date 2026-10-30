import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'editor_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final subtitlesAsync = ref.watch(activeSubtitlesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtitle Library'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search subtitles by title or language...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),
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
                  return const Center(
                    child: Text('No subtitles found.', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final sub = filtered[i];
                    final durMins = (sub.durationSeconds / 60).toStringAsFixed(1);
                    final kb = (sub.fileSizeBytes.toInt() / 1024).toStringAsFixed(1);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    sub.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Chip(
                                  label: Text('${sub.sourceLanguage.toUpperCase()} ➔ EN'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Duration: $durMins mins · ${sub.cueCount} cues · ${kb}KB · Provider: ${sub.providerUsed}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final file = File(sub.localSrtPath);
                                    if (await file.exists()) {
                                      final srt = await file.readAsString();
                                      await Clipboard.setData(ClipboardData(text: srt));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('SRT copied to clipboard!')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy SRT'),
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
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Subtitle?'),
                                        content: Text('Remove "${sub.title}" from library?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Delete'),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading library: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
