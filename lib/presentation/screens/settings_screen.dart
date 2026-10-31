import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../core/services/update_checker_service.dart';
import '../../features/providers/deepgram_provider.dart';
import '../../features/providers/gemini_provider.dart';
import '../../features/providers/groq_whisper_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _groqController = TextEditingController();
  final _geminiController = TextEditingController();
  final _deepgramController = TextEditingController();

  final UpdateCheckerService _updateChecker = UpdateCheckerService();
  bool _isCheckingUpdate = false;
  String _currentAppVersion = '1.0.4+5';

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
            backgroundColor: AppTheme.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
            title: const Text('Application Up to Date'),
            content: Text(
              'You are running the latest version of SubtitleGen AI (${updateInfo.currentVersion}).',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
              ),
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
          behavior: SnackBarBehavior.floating,
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
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.system_update_rounded, color: AppTheme.accentCyan, size: 48),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    updateInfo.releaseNotes,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
                  ),
                ),
                if (updateInfo.apkSizeBytes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Download Size: ${(updateInfo.apkSizeBytes! / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.white38),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Updates preserve your settings and history.',
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: downloadProgress > 0 ? downloadProgress : null),
                  const SizedBox(height: 8),
                  Text(
                    downloadStatus,
                    style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!isDownloading) ...[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Later', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (updateInfo.apkDownloadUrl == null) {
                    final uri = Uri.parse(updateInfo.releaseUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    return;
                  }

                  setDialogState(() {
                    isDownloading = true;
                    downloadStatus = 'Downloading APK...';
                  });

                  try {
                    await _updateChecker.downloadAndInstallUpdate(
                      downloadUrl: updateInfo.apkDownloadUrl!,
                      fileName: 'subtitle_generator_update.apk',
                      onProgress: (received, total) {
                        if (total > 0) {
                          setDialogState(() {
                            downloadProgress = received / total;
                            downloadStatus = 'Downloading: ${(downloadProgress * 100).toStringAsFixed(0)}%';
                          });
                        }
                      },
                    );

                    setDialogState(() {
                      downloadStatus = 'Launching package installer...';
                    });
                  } catch (e) {
                    setDialogState(() {
                      isDownloading = false;
                      downloadStatus = '';
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Installation failed: $e'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                icon: const Icon(Icons.download_rounded, size: 18),
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
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.greenAccent, size: 18),
                SizedBox(width: 8),
                Text('Groq API Key validated and saved securely!'),
              ],
            ),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Groq validation failed: ${result.errorMessage}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
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
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.greenAccent, size: 18),
                SizedBox(width: 8),
                Text('Gemini API Key validated and saved securely!'),
              ],
            ),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gemini validation failed: ${result.errorMessage}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
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
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.greenAccent, size: 18),
                SizedBox(width: 8),
                Text('Deepgram API Key validated and saved securely!'),
              ],
            ),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deepgram validation failed: ${result.errorMessage}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? Colors.white54 : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.borderSubtle : AppTheme.lightBorderSubtle;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // --- Header ---
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: AppTheme.accentCyan, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Providers & BYOK',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: textPrimary,
                    ),
                  ),
                ),
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
            const SizedBox(height: 8),
            Text(
              'Your API keys are encrypted using hardware-backed keystores on this device and are sent directly to the AI models.',
              style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 22),

            // --- Groq ---
            _buildProviderCard(
              title: 'Groq Cloud (Whisper Large-v3)',
              description: 'Ultra-fast speech transcription. Highly recommended.',
              dashboardUrl: 'https://console.groq.com/keys',
              controller: _groqController,
              icon: Icons.bolt_rounded,
              iconColor: Colors.amberAccent,
              obscure: _obscureGroq,
              isTesting: _testingGroq,
              onToggleObscure: () => setState(() => _obscureGroq = !_obscureGroq),
              onSave: _testAndSaveGroq,
              cardBg: cardBg,
              borderCol: borderCol,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 16),

            // --- Gemini ---
            _buildProviderCard(
              title: 'Google Gemini (Flash / Transcribe)',
              description: 'Context-rich transcription and world-class English translation.',
              dashboardUrl: 'https://aistudio.google.com/api-keys',
              controller: _geminiController,
              icon: Icons.auto_awesome_rounded,
              iconColor: Colors.cyanAccent,
              obscure: _obscureGemini,
              isTesting: _testingGemini,
              onToggleObscure: () => setState(() => _obscureGemini = !_obscureGemini),
              onSave: _testAndSaveGemini,
              cardBg: cardBg,
              borderCol: borderCol,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 16),

            // --- Deepgram ---
            _buildProviderCard(
              title: 'Deepgram (Nova-3 Multilingual)',
              description: 'High-accuracy audio transcription with speaker diarization.',
              dashboardUrl: 'https://console.deepgram.com/',
              controller: _deepgramController,
              icon: Icons.mic_rounded,
              iconColor: Colors.purpleAccent,
              obscure: _obscureDeepgram,
              isTesting: _testingDeepgram,
              onToggleObscure: () => setState(() => _obscureDeepgram = !_obscureDeepgram),
              onSave: _testAndSaveDeepgram,
              cardBg: cardBg,
              borderCol: borderCol,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
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
                    backgroundColor: AppTheme.darkCard,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('Purge All Credentials?'),
                    content: const Text('This will delete all stored API keys from your hardware keystore.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        child: const Text('Purge All', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final storage = ref.read(secureStorageProvider);
                  await storage.deleteGroqKey();
                  await storage.deleteGeminiKey();
                  await storage.deleteDeepgramKey();
                  _groqController.clear();
                  _geminiController.clear();
                  _deepgramController.clear();
                  await ref.read(apiKeysProvider.notifier).loadKeys();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All credentials securely purged.'),
                        backgroundColor: Color(0xFF1E293B),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
              label: const Text('Purge All Credentials from Keystore', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard({
    required String title,
    required String description,
    required String dashboardUrl,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required bool obscure,
    required bool isTesting,
    required VoidCallback onToggleObscure,
    required VoidCallback onSave,
    required Color cardBg,
    required Color borderCol,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPrimary)),
                      const SizedBox(height: 2),
                      Text(description, style: TextStyle(color: textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(dashboardUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dashboardUrl, style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.accentCyan),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter API Key',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20, color: Colors.white54),
                  onPressed: onToggleObscure,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isTesting ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: isTesting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Test & Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update_alt_rounded, color: AppTheme.accentCyan, size: 22),
                const SizedBox(width: 10),
                const Text('Software Updates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    'v$_currentAppVersion',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentCyan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Check for the latest features, native engine updates, and bug fixes directly from GitHub Releases.',
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: _isCheckingUpdate
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(_isCheckingUpdate ? 'Checking GitHub...' : 'Check for Updates', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
