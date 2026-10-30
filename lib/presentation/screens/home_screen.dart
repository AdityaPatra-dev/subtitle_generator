import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/enums.dart';
import '../../core/providers.dart';
import '../../features/media/media_engine.dart';
import '../../features/transcription/pipeline_coordinator.dart';

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
  TranscriptionProviderType _selectedProvider = TranscriptionProviderType.groqWhisperLargeV3;
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
            SnackBar(content: Text('Failed to probe video: $e'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Subtitles generated successfully! Check library or output directory.')),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Processing Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
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
      appBar: AppBar(
        title: const Text('AI Subtitle Generator'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Select Video Box ---
          InkWell(
            onTap: _isProcessing ? null : _pickVideo,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155), width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedVideoPath == null ? Icons.video_file_outlined : Icons.check_circle,
                    size: 48,
                    color: _selectedVideoPath == null ? Colors.cyanAccent : Colors.greenAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedVideoPath == null
                        ? 'Tap to Select a Video File'
                        : File(_selectedVideoPath!).uri.pathSegments.last,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_mediaInfo != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Duration: ${(_mediaInfo!.durationSeconds / 60).toStringAsFixed(1)} min · Tracks: ${_mediaInfo!.audioTracks.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                  if (_isProbing) ...[
                    const SizedBox(height: 8),
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Audio Track Selector (if multiple tracks) ---
          if (_mediaInfo != null && _mediaInfo!.audioTracks.length > 1) ...[
            const Text('Select Audio Stream', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedAudioStreamIndex,
                  isExpanded: true,
                  items: _mediaInfo!.audioTracks.map((t) {
                    return DropdownMenuItem<int>(
                      value: t.streamIndex,
                      child: Text(t.displayName),
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

          // --- Language Selection ---
          const Text('Spoken Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SourceLanguage>(
                value: _selectedLanguage,
                isExpanded: true,
                items: SourceLanguage.values.map((l) {
                  return DropdownMenuItem<SourceLanguage>(
                    value: l,
                    child: Text(l.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Provider Selection ---
          const Text('Transcription Provider (BYOK)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          _buildProviderOption(
            title: 'Groq Whisper Large-v3',
            subtitle: 'Ultra-fast speech-to-text (<10s/chunk)',
            type: TranscriptionProviderType.groqWhisperLargeV3,
            hasKey: keysState.groqKey?.isNotEmpty == true,
          ),
          _buildProviderOption(
            title: 'Google Gemini 2.5 Flash',
            subtitle: 'Rich multimodal contextual understanding',
            type: TranscriptionProviderType.gemini25Transcribe,
            hasKey: keysState.geminiKey?.isNotEmpty == true,
          ),
          _buildProviderOption(
            title: 'Deepgram Nova-3 Multilingual',
            subtitle: 'Accurate word timestamps & diarization',
            type: TranscriptionProviderType.deepgramNova3,
            hasKey: keysState.deepgramKey?.isNotEmpty == true,
          ),
          const SizedBox(height: 20),

          // --- Translation Model ---
          const Text('Translation Engine (Stage 2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TranslationModelType>(
                value: _selectedTranslationModel,
                isExpanded: true,
                items: TranslationModelType.values.map((m) {
                  return DropdownMenuItem<TranslationModelType>(
                    value: m,
                    child: Text(m.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTranslationModel = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 30),

          // --- Progress Indicator (if active) ---
          if (_isProcessing && _currentProgress != null) ...[
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentProgress!.status.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                        ),
                        Text(
                          '${(_currentProgress!.progressPercent * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _currentProgress!.progressPercent,
                      backgroundColor: const Color(0xFF334155),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentProgress!.statusMessage,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // --- Generate Action Button ---
          ElevatedButton.icon(
            onPressed: (_isProcessing || _selectedVideoPath == null) ? null : _startProcessing,
            icon: const Icon(Icons.subtitles),
            label: const Text('Generate Subtitles (SRT & VTT)'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderOption({
    required String title,
    required String subtitle,
    required TranscriptionProviderType type,
    required bool hasKey,
  }) {
    final isSelected = _selectedProvider == type;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? const Color(0xFF2E3A52) : const Color(0xFF1E293B),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white54,
        ),
        onTap: () => setState(() => _selectedProvider = type),
        trailing: hasKey
            ? const Chip(
                label: Text('Key Ready', style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
                backgroundColor: Color(0xFF14532D),
                visualDensity: VisualDensity.compact,
              )
            : const Chip(
                label: Text('No Key', style: TextStyle(fontSize: 11, color: Colors.orangeAccent)),
                backgroundColor: Color(0xFF7C2D12),
                visualDensity: VisualDensity.compact,
              ),
      ),
    );
  }
}
