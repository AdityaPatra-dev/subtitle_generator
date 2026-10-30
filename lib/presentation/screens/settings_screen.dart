import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
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
}
