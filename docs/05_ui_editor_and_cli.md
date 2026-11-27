# 📱 UI Screens, Cue Editor, Docker CLI & CI/CD

---

## 1. Presentation Layer (`lib/presentation/screens/`)

1. **`HomeScreen` (`home_screen.dart`)**:
   - Video picker (`file_picker`), media metadata card (duration, audio tracks, file size) with inline title rename.
   - Searchable Spoken Language & Output Subtitle Language modals (70+ languages in `TargetLanguage`).
   - Transcription Model cards showing live `Key Ready` / `No Key` status.
   - Speech & Audio Profile selector (`Action`, `Balanced`, `Clear`).
   - Chunking Strategy selector (`Parallel Chunking`, `Sequential Chunking`, `Large Chunking`).
   - Incomplete-run auto-detection banner (`Resume from Chunk X` or `Start Over`).
   - Live progress card with stage pills (`Audio`, `VAD`, `Transcribe`, `Translate`, `Format`), elapsed timer, ETA, and `Cancel / Stop Run`.

2. **`LibraryScreen` (`library_screen.dart`)**:
   - Searchable list of generated subtitles with duration, cue count, file size, target language badge, and provider used.
   - Quick actions: copy `.srt` path/content, open in Cue Editor, or delete.

3. **`RunsScreen` (`runs_screen.dart`)**:
   - Lists all incomplete/paused/failed jobs with chunk completion bars (`Chunks: X of Y completed`), audio size, cues ready, **Partial SRT** export, delete, and one-tap **Resume**.

4. **`EditorScreen` (`editor_screen.dart`)**:
   - Interactive per-cue subtitle editor supporting:
     - Inline text editing
     - Millisecond timing nudges (`Start -100ms`, `Start +100ms`, `End -100ms`, `End +100ms`)
     - `Split Line`, `Merge Next`, `+ Add Line`, and cue deletion
     - Saves updated `.srt` & `.vtt` files directly back to disk.

5. **`SettingsScreen` (`settings_screen.dart`)**:
   - BYOK configuration for Groq, Google Gemini, and Deepgram with live **Test & Save** validation.
   - Light/Dark theme toggle, **Purge All Credentials**, and in-app GitHub Release update checker (`UpdateCheckerService`).

---

## 2. Headless CLI & Docker (`bin/cli.dart`, `Dockerfile`)

The headless Dart CLI (`bin/cli.dart`) shares the exact same `PipelineCoordinator`, `ProcessMediaEngine`, `VadChunkCalculator`, `TranslationService`, and `SubtitleSerializer` core as the Flutter mobile/desktop app:
- Reads API keys from environment variables (`GEMINI_API_KEY`, `GROQ_API_KEY`, `DEEPGRAM_API_KEY`).
- Supports `-i` (input media), `-o` (output dir), `-s` (source language), `-t` (target language), `-p` (speech profile: `action` / `balanced` / `clear`), and provider flags.
- Packaged as a multi-arch Docker image (`adityapatra/subtitle-generator`) with `ffmpeg` pre-installed.

---

## 3. Automated CI/CD (`.github/workflows/`)

- **`ci.yml` (`Fast Test & Quality Gate`)**:
  - Runs on every push/PR to `main`.
  - Executes `flutter analyze --no-fatal-infos lib/` and `flutter test test/unit test/widget_test.dart`.
- **`release.yml` (`Build & Release Multi-Platform`)**:
  - Triggered by pushing a `v*` tag (e.g. `v1.0.11`) or `workflow_dispatch`.
  - Builds release artifacts in parallel across **Android APK**, **Linux Desktop**, **Windows Desktop**, and **macOS / iOS**, then publishes them to GitHub Releases.
