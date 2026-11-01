import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../../core/storage/database.dart';
import '../../features/subtitles/subtitle_serializer.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

class RunsScreen extends ConsumerStatefulWidget {
  final void Function(JobEntry job)? onResumeJob;

  const RunsScreen({super.key, this.onResumeJob});

  @override
  ConsumerState<RunsScreen> createState() => _RunsScreenState();
}

class _RunsScreenState extends ConsumerState<RunsScreen> {
  final Map<String, int> _segmentCounts = {};
  final Map<String, int> _audioSizes = {};

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(incompleteJobsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Runs & Incomplete Tasks',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Purge All Incomplete Caches',
            icon: const Icon(Icons.cleaning_services_rounded, size: 20),
            onPressed: () => _confirmPurgeAllCache(context),
          ),
        ],
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return _buildEmptyState(textPrimary, textSecondary);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, idx) {
              final job = jobs[idx];
              _loadJobStats(job);
              return _buildRunCard(
                job: job,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentCyan),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load runs: $e', style: TextStyle(color: textSecondary)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 56,
                color: AppTheme.accentCyan,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Incomplete Runs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All subtitle generation jobs completed successfully or intermediate files have been cleaned up.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunCard({
    required JobEntry job,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final total = job.totalChunks > 0 ? job.totalChunks : 1;
    final completedChunks = job.currentChunkIndex.clamp(0, total);
    final progressFactor = (completedChunks / total).clamp(0.0, 1.0);
    final cueCount = _segmentCounts[job.id] ?? 0;
    final cachedBytes = _audioSizes[job.id] ?? 0;
    final audioMb = cachedBytes > 0
        ? (cachedBytes / (1024 * 1024)).toStringAsFixed(1)
        : (job.fileSizeBytes.toInt() / (1024 * 1024)).toStringAsFixed(1);

    final statusText = _resolveStatusBadge(job);
    final timeStr = _formatTimestamp(job.interruptedAt ?? job.updatedAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: job.status == 'failed'
              ? Colors.redAccent.withValues(alpha: 0.4)
              : AppTheme.primaryViolet.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Video name & Status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.video_file_rounded, color: AppTheme.accentCyan, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.originalFilename,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Job ID: ${job.id.substring(0, 8)} • $timeStr',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildBadge(statusText, isFailed: job.status == 'failed'),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar: Chunks Completed
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressFactor,
              minHeight: 6,
              backgroundColor: AppTheme.primaryViolet.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                job.status == 'failed' ? Colors.orangeAccent : AppTheme.accentCyan,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chunks: $completedChunks of ${job.totalChunks > 0 ? job.totalChunks : "?"} completed',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
              ),
              Text(
                '${(progressFactor * 100).toInt()}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metric Pills Row: Audio Size • Cues Done • Model
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPill(Icons.graphic_eq_rounded, '$audioMb MB Audio', Colors.greenAccent),
              _buildPill(Icons.subtitles_rounded, '$cueCount Cues Ready', AppTheme.accentCyan),
              _buildPill(Icons.psychology_rounded, job.provider, Colors.purpleAccent),
            ],
          ),

          // Diagnostic Error Box (if failed)
          if (job.errorMessage != null && job.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.errorMessage!,
                      style: const TextStyle(fontSize: 11, color: Colors.redAccent, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Action Toolbar: Folder • Export Partial SRT • Delete • Resume
          Row(
            children: [
              // Folder inspection icon
              IconButton(
                tooltip: 'Inspect File Locations',
                icon: const Icon(Icons.folder_outlined, size: 20, color: AppTheme.accentCyan),
                onPressed: () => _showFolderInspectorModal(context, job),
              ),
              // Export Partial SRT
              OutlinedButton.icon(
                onPressed: () => _exportPartialSrt(context, job),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download_rounded, size: 14, color: AppTheme.accentCyan),
                label: const Text('Partial SRT', style: TextStyle(fontSize: 11, color: AppTheme.accentCyan)),
              ),
              const Spacer(),
              // Delete & Clean
              IconButton(
                tooltip: 'Delete Run & Free Space',
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                onPressed: () => _confirmDeleteJob(context, job),
              ),
              const SizedBox(width: 4),
              // Resume
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onResumeJob != null) {
                    widget.onResumeJob!(job);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Resuming ${job.originalFilename} from chunk ${job.currentChunkIndex + 1}...')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Resume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {required bool isFailed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFailed ? Colors.redAccent.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFailed ? Colors.redAccent.withValues(alpha: 0.5) : Colors.amber.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isFailed ? Colors.redAccent : Colors.amber,
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  String _resolveStatusBadge(JobEntry job) {
    if (job.status == 'failed') {
      return 'FAILED CHUNK ${job.currentChunkIndex + 1}/${job.totalChunks > 0 ? job.totalChunks : "?"}';
    }
    if (job.status == 'extractingAudio') {
      return 'EXTRACTING AUDIO';
    }
    if (job.status == 'chunking') {
      return 'CHUNKING VAD';
    }
    if (job.status == 'translating') {
      return 'TRANSLATING';
    }
    return 'PAUSED AT ${job.currentChunkIndex + 1}/${job.totalChunks > 0 ? job.totalChunks : "?"}';
  }

  String _formatTimestamp(BigInt timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Future<void> _loadJobStats(JobEntry job) async {
    if (_segmentCounts.containsKey(job.id)) return;
    final db = ref.read(databaseProvider);
    final segments = await db.getSegmentsForJob(job.id);
    int audioSize = 0;
    if (job.cachedAudioPath != null) {
      final f = File(job.cachedAudioPath!);
      if (await f.exists()) {
        audioSize = await f.length();
      }
    }
    if (mounted) {
      setState(() {
        _segmentCounts[job.id] = segments.length;
        _audioSizes[job.id] = audioSize;
      });
    }
  }

  void _showFolderInspectorModal(BuildContext context, JobEntry job) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_special_rounded, color: AppTheme.accentCyan, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Storage & File Locations',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildLocationItem(
              title: 'Source Video Path',
              path: job.videoFilePath,
              icon: Icons.movie_outlined,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 12),
            _buildLocationItem(
              title: 'Cached Extracted Audio',
              path: job.cachedAudioPath ?? 'Audio not extracted yet or deleted',
              icon: Icons.audiotrack_outlined,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 12),
            _buildLocationItem(
              title: 'SQLite Database Checkpoint',
              path: 'subtitle_generator.sqlite (Job: ${job.id})',
              icon: Icons.storage_rounded,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required String title,
    required String path,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.accentCyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 3),
                Text(path, style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white60),
            tooltip: 'Copy Path',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Path copied to clipboard!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportPartialSrt(BuildContext context, JobEntry job) async {
    final db = ref.read(databaseProvider);
    final segments = await db.getSegmentsForJob(job.id);

    if (segments.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transcript cues generated yet for this run.')),
        );
      }
      return;
    }

    final notice = '[Subtitles paused at Chunk ${job.currentChunkIndex + 1} of ${job.totalChunks > 0 ? job.totalChunks : "?"} — Resume in Subtitle Generator]';
    final srtContent = SubtitleSerializer.segmentsToSrt(segments, finalNotice: notice);

    final cleanTitle = p.basenameWithoutExtension(job.originalFilename);
    Directory targetDir;
    if (Platform.isAndroid) {
      final pubDownload = Directory('/storage/emulated/0/Download');
      targetDir = await pubDownload.exists() ? pubDownload : await getApplicationDocumentsDirectory();
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }

    final partialFile = File(p.join(targetDir.path, '${cleanTitle}_partial.srt'));
    await partialFile.writeAsString(srtContent);

    final partialEntry = SubtitleEntry(
      id: 'partial_${job.id}',
      jobId: job.id,
      title: '${cleanTitle}_partial',
      originalFilename: job.originalFilename,
      sourceLanguage: job.sourceLanguage,
      targetLanguage: job.targetLanguage,
      durationSeconds: job.durationSeconds,
      providerUsed: job.provider,
      cueCount: segments.length,
      fileSizeBytes: BigInt.from(await partialFile.length()),
      localSrtPath: partialFile.path,
      isDirty: false,
      isDeleted: false,
      createdAt: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      updatedAt: BigInt.from(DateTime.now().millisecondsSinceEpoch),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Expanded(child: Text('Exported ${segments.length} cues to ${p.basename(partialFile.path)}')),
            ],
          ),
          action: SnackBarAction(
            label: 'View / Edit',
            textColor: AppTheme.accentCyan,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditorScreen(subtitle: partialEntry),
                ),
              );
            },
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteJob(BuildContext context, JobEntry job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Incomplete Run?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'This will permanently delete the run for "${job.originalFilename}" and purge all intermediate audio cache and chunk files to free device storage.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete & Purge'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. Delete cached audio file
      final cacheManager = ref.read(audioCacheManagerProvider);
      if (job.cachedAudioPath != null) {
        await cacheManager.deleteCachedAudio(job.cachedAudioPath!);
      }
      // 2. Delete database records
      final db = ref.read(databaseProvider);
      await db.deleteJobAndData(job.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Run deleted and intermediate storage freed.')),
        );
      }
    }
  }

  Future<void> _confirmPurgeAllCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Purge All Audio Caches?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear all cached extracted audio files. Any incomplete jobs will re-extract their audio if resumed.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Purge All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cacheManager = ref.read(audioCacheManagerProvider);
      await cacheManager.clearAllCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All intermediate audio caches cleared.')),
        );
      }
    }
  }
}
