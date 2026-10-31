import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/enums.dart';
import '../../core/providers.dart';
import '../../features/media/media_engine.dart';
import '../../features/transcription/pipeline_coordinator.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedVideoPath;
  MediaInfo? _mediaInfo;
  int _selectedAudioStreamIndex = 0;
  bool _isProbing = false;

  SourceLanguage _selectedLanguage = SourceLanguage.ja;
  TranscriptionProviderType _selectedProvider = TranscriptionProviderType.gemini25Transcribe;
  TranslationModelType _selectedTranslationModel = TranslationModelType.gemini25Flash;

  bool _isProcessing = false;
  PipelineProgress? _currentProgress;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _selectedVideoPath = path;
        _isProbing = true;
      });

      try {
        final engine = ref.read(mediaEngineProvider);
        final info = await engine.probe(path);
        setState(() {
          _mediaInfo = info;
          _selectedAudioStreamIndex = info.primaryAudioTrack?.streamIndex ?? 0;
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

  Future<void> _startProcessing() async {
    if (_selectedVideoPath == null) return;

    final coordinator = ref.read(pipelineCoordinatorProvider);
    final tempDir = await getTemporaryDirectory();
    final outDir = File(_selectedVideoPath!).parent.path;

    setState(() {
      _isProcessing = true;
    });

    try {
      final stream = coordinator.processVideo(
        videoPath: _selectedVideoPath!,
        audioStreamIndex: _selectedAudioStreamIndex,
        sourceLang: _selectedLanguage,
        providerType: _selectedProvider,
        translationModel: _selectedTranslationModel,
        tempWorkDir: tempDir.path,
        outputDir: outDir,
      );

      await for (final progress in stream) {
        if (!mounted) break;
        setState(() {
          _currentProgress = progress;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent),
                SizedBox(width: 8),
                Expanded(child: Text('Subtitles generated successfully! Check Library tab.')),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Processing Error'),
              ],
            ),
            content: Text(e.toString(), style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keysState = ref.watch(apiKeysProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // --- Modern Header Bar ---
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryViolet.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.subtitles_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Subtitle Generator',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Edge-Cloud Hybrid Video Transcription',
                      style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),

            // --- Hero Video Selection Card ---
            _buildVideoPickerCard(),
            const SizedBox(height: 20),

            // --- Audio Stream Selector (if multi-track) ---
            if (_mediaInfo != null && _mediaInfo!.audioTracks.length > 1) ...[
              _buildSectionTitle('Audio Track Selection', Icons.audiotrack_rounded),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedAudioStreamIndex,
                    dropdownColor: AppTheme.darkCard,
                    isExpanded: true,
                    items: _mediaInfo!.audioTracks.map((t) {
                      return DropdownMenuItem<int>(
                        value: t.streamIndex,
                        child: Text(t.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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

            // --- Spoken Language Selector ---
            _buildSectionTitle('Spoken Language', Icons.translate_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SourceLanguage>(
                  value: _selectedLanguage,
                  dropdownColor: AppTheme.darkCard,
                  isExpanded: true,
                  items: SourceLanguage.values.map((l) {
                    return DropdownMenuItem<SourceLanguage>(
                      value: l,
                      child: Text(l.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),

            // --- AI Transcription Engine ---
            _buildSectionTitle('Transcription Model (BYOK)', Icons.psychology_rounded),
            const SizedBox(height: 8),
            _buildProviderCard(
              title: 'Google Gemini Flash',
              subtitle: 'Multi-lingual contextual audio reasoning',
              type: TranscriptionProviderType.gemini25Transcribe,
              badge: 'Gemini 3',
              icon: Icons.auto_awesome_rounded,
              iconColor: Colors.cyanAccent,
              hasKey: keysState.geminiKey?.isNotEmpty == true,
            ),
            _buildProviderCard(
              title: 'Groq Whisper Large-v3',
              subtitle: 'Near-instant cloud STT (<8s per chunk)',
              type: TranscriptionProviderType.groqWhisperLargeV3,
              badge: 'Ultra-Fast',
              icon: Icons.bolt_rounded,
              iconColor: Colors.amberAccent,
              hasKey: keysState.groqKey?.isNotEmpty == true,
            ),
            _buildProviderCard(
              title: 'Deepgram Nova-3',
              subtitle: 'Word timestamps & speaker diarization',
              type: TranscriptionProviderType.deepgramNova3,
              badge: 'High Accuracy',
              icon: Icons.mic_rounded,
              iconColor: Colors.purpleAccent,
              hasKey: keysState.deepgramKey?.isNotEmpty == true,
            ),
            const SizedBox(height: 22),

            // --- Translation Target ---
            _buildSectionTitle('Translation Mode (Stage 2)', Icons.g_translate_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TranslationModelType>(
                  value: _selectedTranslationModel,
                  dropdownColor: AppTheme.darkCard,
                  isExpanded: true,
                  items: TranslationModelType.values.map((m) {
                    return DropdownMenuItem<TranslationModelType>(
                      value: m,
                      child: Text(m.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTranslationModel = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 26),

            // --- Live Processing HUD Card ---
            if (_isProcessing && _currentProgress != null) ...[
              _buildProgressCard(),
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
                      ? const Color(0xFF1E293B)
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.accentCyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.1, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildVideoPickerCard() {
    final hasVideo = _selectedVideoPath != null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasVideo ? AppTheme.primaryViolet : AppTheme.borderSubtle,
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
                        ? Colors.greenAccent.withValues(alpha: 0.12)
                        : AppTheme.primaryViolet.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasVideo ? Icons.check_circle_rounded : Icons.video_file_outlined,
                    size: 32,
                    color: hasVideo ? Colors.greenAccent : AppTheme.accentCyan,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  hasVideo
                      ? File(_selectedVideoPath!).uri.pathSegments.last
                      : 'Choose Video to Generate Subtitles',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  hasVideo ? 'Tap to change video' : 'Supports MP4, MKV, MOV, WEBM & AVI',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                if (_isProbing) ...[
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Probing video & audio streams...', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
        color: AppTheme.darkSurface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accentCyan),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
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
  }) {
    final isSelected = _selectedProvider == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1B2438) : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryViolet : AppTheme.borderSubtle,
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
                    color: iconColor.withValues(alpha: 0.12),
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
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
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
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasKey
                            ? const Color(0xFF064E3B).withValues(alpha: 0.7)
                            : const Color(0xFF7C2D12).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasKey ? 'Key Ready' : 'No Key',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: hasKey ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _currentProgress!;
    final percent = (progress.progressPercent * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentCyan),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    progress.status.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.accentCyan),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.progressPercent,
              minHeight: 8,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryViolet),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progress.statusMessage,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}
