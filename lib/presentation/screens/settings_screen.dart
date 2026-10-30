import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../core/services/update_checker_service.dart';
import '../../features/providers/deepgram_provider.dart';
import '../../features/providers/gemini_provider.dart';
import '../../features/providers/groq_whisper_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _groqController = TextEditingController();
  final _geminiController = TextEditingController();
  final _deepgramController = TextEditingController();

  final _updateChecker = UpdateCheckerService();
  bool _isCheckingUpdate = false;
  String _currentAppVersion = '1.0.0+1';

  bool _obscureGroq = true;
  bool _obscureGemini = true;
  bool _obscureDeepgram = true;

  bool _testingGroq = false;
  bool _testingGemini = false;
  bool _testingDeepgram = false;

  @override
  void initState() {
    super.initState();
    final keys = ref.read(apiKeysProvider);
    _groqController.text = keys.groqKey ?? '';
    _geminiController.text = keys.geminiKey ?? '';
    _deepgramController.text = keys.deepgramKey ?? '';
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentAppVersion = '${info.version}+${info.buildNumber}';
        });
      }
    } catch (_) {}
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final updateInfo = await _updateChecker.checkForUpdates();
      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);

      if (!updateInfo.isUpdateAvailable) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
            title: const Text('Application Up to Date'),
            content: Text(
              'You are running the latest version of SubtitleGen AI (${updateInfo.currentVersion}).',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      } else {
        _showUpdateAvailableDialog(updateInfo);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check for updates: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showUpdateAvailableDialog(AppUpdateInfo updateInfo) {
    double downloadProgress = 0.0;
    bool isDownloading = false;
    String downloadStatus = '';

    showDialog(
      context: context,
      barrierDismissible: !isDownloading,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.system_update_rounded, color: Colors.cyanAccent, size: 48),
          title: Text('New Version: ${updateInfo.latestVersion}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Version: ${updateInfo.currentVersion}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  updateInfo.releaseName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    updateInfo.releaseNotes,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                if (updateInfo.apkSizeBytes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Download Size: ${(updateInfo.apkSizeBytes! / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                if (isDownloading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: downloadProgress > 0 ? downloadProgress : null),
                  const SizedBox(height: 8),
                  Text(
                    downloadStatus,
                    style: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!isDownloading) ...[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(updateInfo.releaseUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser, size: 16),
                label: const Text('View on GitHub'),
              ),
              ElevatedButton.icon(
                onPressed: (updateInfo.apkDownloadUrl == null && !Platform.isLinux)
                    ? null
                    : () async {
                        setDialogState(() {
                          isDownloading = true;
                          downloadStatus = 'Starting download...';
                        });

                        final targetDownloadUrl = updateInfo.apkDownloadUrl ?? updateInfo.releaseUrl;
                        final fileName = 'subtitle_generator_${updateInfo.latestVersion}.apk';

                        try {
                          await _updateChecker.downloadAndInstallUpdate(
                            downloadUrl: targetDownloadUrl,
                            fileName: fileName,
                            onProgress: (received, total) {
                              setDialogState(() {
                                if (total > 0) {
                                  downloadProgress = received / total;
                                  downloadStatus =
                                      'Downloading update: ${(downloadProgress * 100).toStringAsFixed(0)}% (${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB)';
                                } else {
                                  downloadStatus = 'Downloading update (${(received / 1024 / 1024).toStringAsFixed(1)} MB)...';
                                }
                              });
                            },
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          setDialogState(() {
                            isDownloading = false;
                            downloadStatus = 'Download failed: $e';
                          });
                        }
                      },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Update Now'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groqController.dispose();
    _geminiController.dispose();
    _deepgramController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveGroq() async {
    setState(() => _testingGroq = true);
    final provider = GroqWhisperProvider();
    final result = await provider.validateApiKey(_groqController.text);
    setState(() => _testingGroq = false);

    if (result.isValid) {
      await ref.read(apiKeysProvider.notifier).setGroqKey(_groqController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Groq API Key validated and saved securely!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Groq validation failed: ${result.errorMessage}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testAndSaveGemini() async {
    setState(() => _testingGemini = true);
    final provider = GeminiProvider();
    final result = await provider.validateApiKey(_geminiController.text);
    setState(() => _testingGemini = false);

    if (result.isValid) {
      await ref.read(apiKeysProvider.notifier).setGeminiKey(_geminiController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemini API Key validated and saved securely!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gemini validation failed: ${result.errorMessage}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testAndSaveDeepgram() async {
    setState(() => _testingDeepgram = true);
    final provider = DeepgramNovaProvider();
    final result = await provider.validateApiKey(_deepgramController.text);
    setState(() => _testingDeepgram = false);

    if (result.isValid) {
      await ref.read(apiKeysProvider.notifier).setDeepgramKey(_deepgramController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deepgram API Key validated and saved securely!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deepgram validation failed: ${result.errorMessage}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Providers (BYOK) & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Bring Your Own Key (BYOK)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your credentials are encrypted using hardware-backed secure storage and never leave your device. You are billed directly by the providers at their native rates.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // --- Groq ---
          _buildProviderCard(
            title: 'Groq (Whisper Large-v3)',
            description: 'Ultra-fast speech transcription. Highly recommended.',
            dashboardUrl: 'https://console.groq.com/keys',
            controller: _groqController,
            obscure: _obscureGroq,
            isTesting: _testingGroq,
            onToggleObscure: () => setState(() => _obscureGroq = !_obscureGroq),
            onSave: _testAndSaveGroq,
          ),
          const SizedBox(height: 16),

          // --- Gemini ---
          _buildProviderCard(
            title: 'Google Gemini (2.5 Flash / Transcribe)',
            description: 'Context-rich transcription and world-class English translation.',
            dashboardUrl: 'https://aistudio.google.com/api-keys',
            controller: _geminiController,
            obscure: _obscureGemini,
            isTesting: _testingGemini,
            onToggleObscure: () => setState(() => _obscureGemini = !_obscureGemini),
            onSave: _testAndSaveGemini,
          ),
          const SizedBox(height: 16),

          // --- Deepgram ---
          _buildProviderCard(
            title: 'Deepgram (Nova-3 Multilingual)',
            description: 'High-accuracy audio transcription with speaker diarization.',
            dashboardUrl: 'https://console.deepgram.com/',
            controller: _deepgramController,
            obscure: _obscureDeepgram,
            isTesting: _testingDeepgram,
            onToggleObscure: () => setState(() => _obscureDeepgram = !_obscureDeepgram),
            onSave: _testAndSaveDeepgram,
          ),
          const SizedBox(height: 24),

          // --- Application Updates ---
          _buildUpdateCard(),
          const SizedBox(height: 24),

          // --- Purge Credentials ---
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Purge All Credentials?'),
                  content: const Text('This will delete all stored API keys from your hardware keystore.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Purge'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(secureStorageProvider).purgeAllCredentials();
                _groqController.clear();
                _geminiController.clear();
                _deepgramController.clear();
                await ref.read(apiKeysProvider.notifier).loadKeys();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All credentials deleted.')),
                );
              }
            },
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            label: const Text('Purge All Credentials from Device', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String title,
    required String description,
    required String dashboardUrl,
    required TextEditingController controller,
    required bool obscure,
    required bool isTesting,
    required VoidCallback onToggleObscure,
    required VoidCallback onSave,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text(dashboardUrl, style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: 'Enter API Key',
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: onToggleObscure,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isTesting ? null : onSave,
                icon: isTesting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Test & Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update_alt, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                const Text('Software Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    'v$_currentAppVersion',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Check for the latest features, engine updates, and bug fixes directly from GitHub Releases. Updates install in-place without removing your existing settings.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                icon: _isCheckingUpdate
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                label: Text(_isCheckingUpdate ? 'Checking GitHub...' : 'Check for Updates'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
