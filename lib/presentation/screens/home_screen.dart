import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/enums.dart';
import '../../core/providers.dart';
import '../../core/storage/database.dart';
import '../../features/media/media_engine.dart';
import '../../features/transcription/pipeline_coordinator.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final JobEntry? initialResumeJob;

  const HomeScreen({super.key, this.initialResumeJob});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _mediaChannel = MethodChannel('com.subtitlegenerator.subtitle_generator/media_resolver');

  String? _selectedVideoPath;
  String? _selectedVideoName;
  MediaInfo? _mediaInfo;
  int _selectedAudioStreamIndex = 0;
  bool _isProbing = false;
  JobEntry? _incompleteJob;

  SourceLanguage _selectedLanguage = SourceLanguage.auto;
  TranscriptionProviderType _selectedProvider = TranscriptionProviderType.gemini25Transcribe;
  TranslationModelType _selectedTranslationModel = TranslationModelType.gemini25Flash;

  bool _isProcessing = false;
  PipelineProgress? _currentProgress;
  DateTime? _processStartTime;
  Duration _liveElapsed = Duration.zero;
  Timer? _liveTicker;

  @override
  void dispose() {
    _liveTicker?.cancel();
    super.dispose();
  }

  String get _formattedLiveElapsed {
    final m = _liveElapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_liveElapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _calculateLiveEta(double progressPercent) {
    if (progressPercent <= 0.05 || _liveElapsed.inSeconds < 2) {
      return 'calculating...';
    }
    if (progressPercent >= 1.0) {
      return 'finishing up...';
    }
    final estimatedTotalSec = _liveElapsed.inSeconds / progressPercent;
    final remainingSec = (estimatedTotalSec - _liveElapsed.inSeconds).round().clamp(1, 3600);
    if (remainingSec < 60) {
      return '~${remainingSec}s remaining';
    }
    final m = remainingSec ~/ 60;
    final s = remainingSec % 60;
    return '~${m}m ${s}s remaining';
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _mediaChannel.invokeMethod('requestMediaPermission').catchError((_) => null);
    }
    if (widget.initialResumeJob != null) {
      final job = widget.initialResumeJob!;
      _selectedVideoPath = job.videoFilePath;
      _selectedVideoName = job.originalFilename;
      _selectedAudioStreamIndex = job.audioStreamIndex;
      _incompleteJob = job;
      _probeInitialVideo(job.videoFilePath);
    }
  }

  Future<void> _probeInitialVideo(String path) async {
    try {
      final engine = ref.read(mediaEngineProvider);
      final info = await engine.probe(path);
      if (mounted) {
        setState(() {
          _mediaInfo = info;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    if (Platform.isAndroid) {
      await _mediaChannel.invokeMethod('requestMediaPermission').catchError((_) => null);
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'mov', 'webm', 'avi', 'flv', 'ts', 'm4v', '3gp', 'wmv'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      final picked = result.files.single;
      final path = picked.path!;
      final displayName = (picked.name.isNotEmpty) ? picked.name : p.basename(path);

      setState(() {
        _selectedVideoPath = path;
        _selectedVideoName = displayName;
        _isProbing = true;
      });

      try {
        final engine = ref.read(mediaEngineProvider);
        final info = await engine.probe(path);

        // Intelligently resolve the real video filename if Android photo picker assigned a numeric ID
        final realName = await _resolveRealFilename(path, displayName, info.fileSizeBytes);

        final db = ref.read(databaseProvider);
        final incomplete = await db.findIncompleteJobForFile(realName, info.fileSizeBytes);

        setState(() {
          _mediaInfo = info;
          _selectedVideoName = realName;
          _selectedAudioStreamIndex = info.primaryAudioTrack?.streamIndex ?? 0;
          _incompleteJob = incomplete;
          _isProbing = false;
        });
      } catch (e) {
        setState(() => _isProbing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to probe video: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<String> _resolveRealFilename(String path, String currentName, int fileSizeBytes) async {
    final cleanName = currentName.trim();
    final nameWithoutExt = p.basenameWithoutExtension(cleanName);
    final isNumeric = RegExp(r'^\d+$').hasMatch(nameWithoutExt);

    if (!isNumeric && cleanName.isNotEmpty) {
      return cleanName;
    }

    if (Platform.isAndroid) {
      try {
        final resolved = await _mediaChannel.invokeMethod<String>('getDisplayNameForMedia', {
          'mediaId': nameWithoutExt,
          'fileSizeBytes': fileSizeBytes,
        });
        if (resolved != null && resolved.trim().isNotEmpty) {
          final ext = p.extension(resolved);
          if (ext.isEmpty) {
            return '$resolved${p.extension(cleanName)}';
          }
          return resolved.trim();
        }
      } catch (_) {}
    }

    return cleanName;
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: p.basenameWithoutExtension(_selectedVideoName ?? 'video'));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppTheme.accentCyan),
            SizedBox(width: 8),
            Text('Subtitle & Video Name'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the name to use for your generated .srt and .vtt files:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                suffixText: '.srt',
                hintText: 'e.g. Renegade Immortal Ep 158',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final ext = p.extension(_selectedVideoName ?? '.mp4');
                setState(() {
                  _selectedVideoName = '$newName$ext';
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
            child: const Text('Set Name'),
          ),
        ],
      ),
    );
  }

  Future<void> _startProcessing({String? resumeJobId}) async {
    if (_selectedVideoPath == null) return;

    final coordinator = ref.read(pipelineCoordinatorProvider);
    final tempDir = await getTemporaryDirectory();

    // Determine clean output directory
    String outDir;
    if (Platform.isAndroid) {
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (await publicDownload.exists()) {
        outDir = publicDownload.path;
      } else {
        outDir = (await getApplicationDocumentsDirectory()).path;
      }
    } else {
      outDir = (await getApplicationDocumentsDirectory()).path;
    }

    _processStartTime = DateTime.now();
    _liveElapsed = Duration.zero;
    _liveTicker?.cancel();
    _liveTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isProcessing) {
        timer.cancel();
        return;
      }
      setState(() {
        _liveElapsed = DateTime.now().difference(_processStartTime!);
      });
    });

    setState(() {
      _isProcessing = true;
    });

    final activeResumeId = resumeJobId ?? _incompleteJob?.id;

    try {
      final stream = coordinator.processVideo(
        videoPath: _selectedVideoPath!,
        originalFilename: _selectedVideoName,
        audioStreamIndex: _selectedAudioStreamIndex,
        sourceLang: _selectedLanguage,
        providerType: _selectedProvider,
        translationModel: _selectedTranslationModel,
        tempWorkDir: tempDir.path,
        outputDir: outDir,
        resumeJobId: activeResumeId,
      );

      await for (final progress in stream) {
        if (!mounted) break;
        setState(() {
          _currentProgress = progress;
        });
      }

      _incompleteJob = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Subtitles for "$_selectedVideoName" generated successfully! Check Library.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (_selectedVideoName != null && _mediaInfo != null) {
        final db = ref.read(databaseProvider);
        _incompleteJob = await db.findIncompleteJobForFile(_selectedVideoName!, _mediaInfo!.fileSizeBytes);
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('Run Interrupted', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              'Generation stopped: $e\n\nAll completed chunks and extracted audio have been safely preserved. You can resume this job anytime from the "Runs" tab without losing compute.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startProcessing(resumeJobId: activeResumeId);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Retry / Resume'),
              ),
            ],
          ),
        );
      }
    } finally {
      _liveTicker?.cancel();
      _liveTicker = null;
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showLanguagePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchableLanguageModal(
        selected: _selectedLanguage,
        onSelected: (lang) {
          setState(() => _selectedLanguage = lang);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keysState = ref.watch(apiKeysProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? Colors.white60 : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.borderSubtle : AppTheme.lightBorderSubtle;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // --- Modern Header Bar with App Logo & Theme Toggle ---
            Row(
              children: [
                const AppLogo(size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Subtitle Generator',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Edge-Cloud Hybrid Video Transcription',
                        style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                // Light / Dark Mode Toggle
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDark ? Colors.amberAccent : AppTheme.primaryViolet,
                      size: 20,
                    ),
                    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).state =
                          isDark ? ThemeMode.light : ThemeMode.dark;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // --- Hero Video Selection Card ---
            _buildVideoPickerCard(cardBg, textPrimary, textSecondary, borderCol),
            const SizedBox(height: 20),

            // --- Audio Stream Selector (if multi-track) ---
            if (_mediaInfo != null && _mediaInfo!.audioTracks.length > 1) ...[
              _buildSectionTitle('Audio Track Selection', Icons.audiotrack_rounded, textPrimary),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedAudioStreamIndex,
                    dropdownColor: cardBg,
                    isExpanded: true,
                    items: _mediaInfo!.audioTracks.map((t) {
                      return DropdownMenuItem<int>(
                        value: t.streamIndex,
                        child: Text(
                          t.displayName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedAudioStreamIndex = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // --- Spoken Language Selector (Searchable BottomSheet) ---
            _buildSectionTitle('Spoken Language', Icons.translate_rounded, textPrimary),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showLanguagePickerModal(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedLanguage == SourceLanguage.auto ? Icons.auto_awesome : Icons.language_rounded,
                      color: AppTheme.accentCyan,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedLanguage.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (_selectedLanguage == SourceLanguage.auto) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DEFAULT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.search_rounded, size: 20, color: textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // --- AI Transcription Engine ---
            _buildSectionTitle('Transcription Model (BYOK)', Icons.psychology_rounded, textPrimary),
            const SizedBox(height: 8),
            _buildProviderCard(
              title: 'Google Gemini Flash',
              subtitle: 'Multi-lingual contextual audio reasoning',
              type: TranscriptionProviderType.gemini25Transcribe,
              badge: 'Gemini 3',
              icon: Icons.auto_awesome_rounded,
              iconColor: Colors.cyanAccent,
              hasKey: keysState.geminiKey?.isNotEmpty == true,
              isDark: isDark,
              cardBg: cardBg,
              borderCol: borderCol,
              textPrimary: textPrimary,
            ),
            _buildProviderCard(
              title: 'Groq Whisper Large-v3',
              subtitle: 'Near-instant cloud STT (<8s per chunk)',
              type: TranscriptionProviderType.groqWhisperLargeV3,
              badge: 'Ultra-Fast',
              icon: Icons.bolt_rounded,
              iconColor: Colors.amberAccent,
              hasKey: keysState.groqKey?.isNotEmpty == true,
              isDark: isDark,
              cardBg: cardBg,
              borderCol: borderCol,
              textPrimary: textPrimary,
            ),
            _buildProviderCard(
              title: 'Deepgram Nova-3',
              subtitle: 'Word timestamps & speaker diarization',
              type: TranscriptionProviderType.deepgramNova3,
              badge: 'High Accuracy',
              icon: Icons.mic_rounded,
              iconColor: Colors.purpleAccent,
              hasKey: keysState.deepgramKey?.isNotEmpty == true,
              isDark: isDark,
              cardBg: cardBg,
              borderCol: borderCol,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 22),

            // --- Translation Target ---
            _buildSectionTitle('Translation Mode (Stage 2)', Icons.g_translate_rounded, textPrimary),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderCol),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TranslationModelType>(
                  value: _selectedTranslationModel,
                  dropdownColor: cardBg,
                  isExpanded: true,
                  items: TranslationModelType.values.map((m) {
                    return DropdownMenuItem<TranslationModelType>(
                      value: m,
                      child: Text(
                        m.displayName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTranslationModel = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 26),

            // --- Incomplete Run Recovery Banner (if prior run stopped midway) ---
            if (_incompleteJob != null && !_isProcessing) ...[
              _buildIncompleteJobBanner(cardBg, textPrimary, textSecondary),
              const SizedBox(height: 18),
            ],

            // --- Live Processing HUD Card with Smooth Progress & ETA ---
            if (_isProcessing && _currentProgress != null) ...[
              _buildProgressCard(cardBg, textPrimary, textSecondary),
              const SizedBox(height: 18),
            ],

            // --- Generate Action Button ---
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: (_isProcessing || _selectedVideoPath == null)
                    ? null
                    : AppTheme.brandGradient,
                boxShadow: (_isProcessing || _selectedVideoPath == null)
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryViolet.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: (_isProcessing || _selectedVideoPath == null) ? null : _startProcessing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isProcessing || _selectedVideoPath == null)
                      ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1))
                      : Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.closed_caption_rounded, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _isProcessing ? 'Generating Subtitles...' : 'Generate Subtitles (SRT & VTT)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.accentCyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.1, color: textColor),
        ),
      ],
    );
  }

  Widget _buildVideoPickerCard(Color cardBg, Color textPrimary, Color textSecondary, Color borderCol) {
    final hasVideo = _selectedVideoPath != null;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasVideo ? AppTheme.primaryViolet : borderCol,
          width: hasVideo ? 1.5 : 1.0,
        ),
        boxShadow: hasVideo
            ? [
                BoxShadow(
                  color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : _pickVideo,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: hasVideo
                        ? Colors.greenAccent.withValues(alpha: 0.15)
                        : AppTheme.primaryViolet.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasVideo ? Icons.check_circle_rounded : Icons.video_file_outlined,
                    size: 32,
                    color: hasVideo ? Colors.green : AppTheme.accentCyan,
                  ),
                ),
                const SizedBox(height: 14),
                if (hasVideo) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _selectedVideoName ?? 'Selected Video',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.accentCyan),
                        tooltip: 'Rename Subtitle Title',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _showRenameDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Saves as: ${p.basenameWithoutExtension(_selectedVideoName ?? "video")}.srt',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                    ),
                  ),
                ] else
                  Text(
                    'Choose Video to Generate Subtitles',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 6),
                Text(
                  hasVideo ? 'Tap card to choose different video' : 'Supports MP4, MKV, MOV, WEBM & AVI',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                if (_isProbing) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text('Probing video & audio streams...', style: TextStyle(color: textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
                if (_mediaInfo != null && !_isProbing) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPill(Icons.timer_outlined, '${(_mediaInfo!.durationSeconds / 60).toStringAsFixed(1)} min'),
                      _buildPill(Icons.audiotrack_outlined, '${_mediaInfo!.audioTracks.length} Audio Track${_mediaInfo!.audioTracks.length > 1 ? "s" : ""}'),
                      _buildPill(Icons.folder_outlined, '${(_mediaInfo!.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'),
                      if (_currentProgress?.extractedAudioSizeBytes != null)
                        _buildPill(Icons.graphic_eq_rounded, 'Audio: ${_currentProgress!.audioSizeFormatted}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryViolet.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accentCyan),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentCyan)),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String title,
    required String subtitle,
    required TranscriptionProviderType type,
    required String badge,
    required IconData icon,
    required Color iconColor,
    required bool hasKey,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
  }) {
    final isSelected = _selectedProvider == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF1B2438) : const Color(0xFFEEF2FF))
            : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryViolet : borderCol,
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedProvider = type),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.accentCyan),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasKey
                        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                        : (isDark ? const Color(0xFF7C2D12) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasKey ? 'Key Ready' : 'No Key',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasKey
                          ? (isDark ? Colors.greenAccent : const Color(0xFF15803D))
                          : (isDark ? Colors.orangeAccent : const Color(0xFFB45309)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncompleteJobBanner(Color cardBg, Color textPrimary, Color textSecondary) {
    final job = _incompleteJob!;
    final total = job.totalChunks > 0 ? job.totalChunks : 1;
    final done = job.currentChunkIndex.clamp(0, total);
    final percent = ((done / total) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Incomplete Run Found: $done of $total chunks ($percent%) saved!',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                ),
              ),
            ],
          ),
          if (job.errorMessage != null && job.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Stopped at: ${job.errorMessage}',
              style: const TextStyle(fontSize: 11, color: Colors.amber, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _startProcessing(resumeJobId: job.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text('Resume from Chunk ${done + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await db.deleteJobAndData(job.id);
                  if (mounted) setState(() => _incompleteJob = null);
                },
                child: const Text('Start Over', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Color cardBg, Color textPrimary, Color textSecondary) {
    final progress = _currentProgress!;
    final targetPercent = progress.progressPercent.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stage status + smooth percentage counter
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: targetPercent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, animVal, _) {
              final percentInt = (animVal * 100).toInt().clamp(0, 100);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentCyan,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentCyan,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            progress.status.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$percentInt%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Animated gradient progress bar with glowing leading edge
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 10,
                          color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                        ),
                        FractionallySizedBox(
                          widthFactor: animVal.clamp(0.02, 1.0),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryViolet, AppTheme.accentCyan],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentCyan.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Live status message with active spinner
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.statusMessage,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Pipeline Step Pills (Extract -> Chunk -> Transcribe -> Translate -> Format)
          _buildPipelineSteps(progress.status),
          const SizedBox(height: 14),
          // Live Clock Stats: Elapsed (ticks every second uninterrupted!) • Dynamic ETA • Extracted Audio Size
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live Elapsed Time (seconds tick continuously)
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 15, color: AppTheme.accentCyan),
                    const SizedBox(width: 5),
                    Text(
                      'Elapsed: $_formattedLiveElapsed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                // Live Dynamic ETA (recalculates every second based on elapsed time and progress)
                Row(
                  children: [
                    const Icon(Icons.hourglass_bottom_rounded, size: 15, color: Colors.amberAccent),
                    const SizedBox(width: 5),
                    Text(
                      'ETA: ${_calculateLiveEta(targetPercent)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.amberAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                // Extracted Audio Size
                if (progress.audioSizeFormatted.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.graphic_eq_rounded, size: 15, color: Colors.greenAccent),
                      const SizedBox(width: 5),
                      Text(
                        progress.audioSizeFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineSteps(JobStatus currentStatus) {
    const steps = [
      (JobStatus.extractingAudio, 'Audio', Icons.audiotrack_rounded),
      (JobStatus.chunking, 'VAD', Icons.content_cut_rounded),
      (JobStatus.transcribing, 'Transcribe', Icons.mic_rounded),
      (JobStatus.translating, 'Translate', Icons.translate_rounded),
      (JobStatus.formatting, 'SRT/VTT', Icons.subtitles_rounded),
    ];

    final currentIdx = steps.indexWhere((s) => s.$1 == currentStatus);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isCompleted = currentIdx > idx || currentStatus == JobStatus.completed;
          final isActive = currentIdx == idx && currentStatus != JobStatus.completed;

          Color badgeBg;
          Color badgeBorder;
          Color textColor;
          Widget icon;

          if (isCompleted) {
            badgeBg = Colors.green.withValues(alpha: 0.15);
            badgeBorder = Colors.greenAccent.withValues(alpha: 0.4);
            textColor = Colors.greenAccent;
            icon = const Icon(Icons.check_rounded, size: 12, color: Colors.greenAccent);
          } else if (isActive) {
            badgeBg = AppTheme.accentCyan.withValues(alpha: 0.15);
            badgeBorder = AppTheme.accentCyan;
            textColor = AppTheme.accentCyan;
            icon = const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppTheme.accentCyan),
            );
          } else {
            badgeBg = Colors.white.withValues(alpha: 0.04);
            badgeBorder = Colors.white.withValues(alpha: 0.08);
            textColor = Colors.white38;
            icon = Icon(step.$3, size: 12, color: Colors.white38);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 5),
                  Text(
                    step.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Searchable Language Modal with Auto-Detect as #1 option and Major Languages at Top
class _SearchableLanguageModal extends StatefulWidget {
  final SourceLanguage selected;
  final ValueChanged<SourceLanguage> onSelected;

  const _SearchableLanguageModal({
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_SearchableLanguageModal> createState() => _SearchableLanguageModalState();
}

class _SearchableLanguageModalState extends State<_SearchableLanguageModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF151C2C) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? Colors.white60 : AppTheme.lightTextSecondary;

    final q = _searchQuery.trim().toLowerCase();
    const all = SourceLanguage.values;

    final filtered = q.isEmpty
        ? all
        : all.where((lang) {
            final name = lang.displayName.toLowerCase();
            final code = lang.bcp47.toLowerCase();
            return name.contains(q) || code.contains(q);
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.language_rounded, color: AppTheme.accentCyan, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Select Spoken Language',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search input bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search language (e.g. English, Chinese, Hindi)...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => Divider(
                height: 1,
                color: isDark ? AppTheme.borderSubtle : AppTheme.lightBorderSubtle,
              ),
              itemBuilder: (ctx, i) {
                final lang = filtered[i];
                final isSelected = lang == widget.selected;
                final isAuto = lang == SourceLanguage.auto;
                final isMajor = SourceLanguage.majorLanguages.contains(lang);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isAuto
                          ? AppTheme.accentCyan.withValues(alpha: 0.15)
                          : AppTheme.primaryViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isAuto ? Icons.auto_awesome_rounded : Icons.translate_rounded,
                      color: isAuto ? AppTheme.accentCyan : AppTheme.primaryViolet,
                      size: 18,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lang.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppTheme.accentCyan : textPrimary,
                          ),
                        ),
                      ),
                      if (isAuto)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                          ),
                        )
                      else if (isMajor && _searchQuery.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                          ),
                        ),
                    ],
                  ),
                  subtitle: lang.bcp47.isNotEmpty
                      ? Text('Code: ${lang.bcp47}', style: TextStyle(color: textSecondary, fontSize: 11))
                      : null,
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.accentCyan, size: 22)
                      : null,
                  onTap: () => widget.onSelected(lang),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
