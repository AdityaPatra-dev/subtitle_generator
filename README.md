<p align="center">
  <img src="assets/icons/app_icon.png" width="130" height="130" style="border-radius: 28px; box-shadow: 0 8px 24px rgba(0,0,0,0.4);" alt="Subtitle Generator App Icon" />
</p>

# <p align="center">🎬 SubtitleGen AI</p>

<p align="center">
  <strong>⚡ Ultra-Fast Cross-Platform AI Subtitle & Dubbing Engine (Edge-Cloud Hybrid)</strong>
</p>

<p align="center">
  <a href="https://github.com/adityapatra/subtitle_generator/releases"><img src="https://img.shields.io/badge/Release-v1.0.5-success?logo=github&style=flat-square" alt="Releases" /></a>
  <a href="https://hub.docker.com/r/adityapatra/subtitle-generator"><img src="https://img.shields.io/badge/Docker-adityapatra%2Fsubtitle--generator-2496ED?logo=docker&logoColor=white&style=flat-square" alt="Docker Hub" /></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.44.8-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter" /></a>
  <a href="https://github.com/adityapatra/subtitle_generator/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1000&color=6366F1&center=true&vCenter=true&width=650&lines=Action+Mode+%26+Loud+Audio+Normalisation+%E2%9A%A1;Silence-Aware+VAD+Audio+Chunking+%E2%9A%A1;Multi-Provider+ASR%3A+Gemini+%7C+Groq+%7C+Deepgram;70%2B+Target+Subtitle+Languages+with+Search;Production+Docker+CLI+%26+Mobile+App" alt="Typing SVG" />
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.44.8-02569B?logo=flutter&logoColor=white&style=for-the-badge" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart&logoColor=white&style=for-the-badge" alt="Dart" /></a>
  <a href="https://github.com/adityapatra/subtitle_generator/releases"><img src="https://img.shields.io/badge/Android-APK_v1.0.5-3DDC84?logo=android&logoColor=white&style=for-the-badge" alt="Android" /></a>
  <a href="https://hub.docker.com/r/adityapatra/subtitle-generator"><img src="https://img.shields.io/badge/Docker-CLI_Container-2496ED?logo=docker&logoColor=white&style=for-the-badge" alt="Docker" /></a>
  <a href="https://www.linux.org/"><img src="https://img.shields.io/badge/Linux-Desktop_Native-FCC624?logo=linux&logoColor=black&style=for-the-badge" alt="Linux" /></a>
  <a href="https://ai.google.dev"><img src="https://img.shields.io/badge/Google-Gemini_2.5_Flash-8E75C2?logo=google&logoColor=white&style=for-the-badge" alt="Gemini" /></a>
  <a href="https://groq.com"><img src="https://img.shields.io/badge/Groq-Whisper_Large_v3-F05A28?logo=fastapi&logoColor=white&style=for-the-badge" alt="Groq" /></a>
</p>

---

## 🌟 Overview

**SubtitleGen AI** is an autonomous, privacy-first cross-platform application (Android, Linux desktop, and Docker CLI) engineered to generate broadcast-quality subtitles (`.srt` / `.vtt`) from **long-form audio and video** (from short clips up to 3+ hour films). 

Featuring **70+ output subtitle languages**, **smart speech and audio profiles**, and a resilient **chunk-level checkpoint/resume architecture**, SubtitleGen AI combines deterministic Edge audio DSP (FFmpeg, dynamic normalization, silence-based VAD) with cloud intelligence using your personal API keys (**BYOK**).

---

## 🚀 Key Features

- 🎯 **Speech & Audio Profiles**:
  - **Action & Loud Audio Mode**: Features dynamic audio normalization (`dynaudnorm`) and aggressive -20dB VAD threshold. Captures rapid dialogue, shouting, and altered/synthetic voices even through heavy combat sound effects, explosions, and loud background music.
  - **Balanced Mode**: -28dB VAD threshold optimized for general movies, TV shows, and standard media.
  - **Clear Dialogue Mode**: -35dB VAD threshold with vocal bandpass filter for interviews, courses, and podcasts.
- 🌍 **70+ Output Subtitle Languages**:
  - Searchable picker covering Spanish, Hindi, Japanese, Chinese (Simplified/Traditional), French, German, Arabic, Korean, and dozens more.
  - Instant zero-token auto-bypass when source matches target language.
- 🎧 **Silence-Aware VAD Audio Slicing**: FFmpeg speech-silence detector splits long media around natural pauses without cutting sentences midway.
- 🔄 **Chunk-Level Checkpoint & Resume**:
  - Extracted audio is cached persistently; chunk progress is stored in local SQLite. Interruptions or app restarts resume right where they left off with zero wasted API calls.
- 📋 **Runs & Incomplete Tasks Management**: Dedicated tab to monitor active pipelines, inspect partial chunk status, retry failed runs, or resume interrupted tasks.
- 🎙️ **Multi-Engine ASR**: Switch dynamically between **Google Gemini 2.5 Flash**, **Groq Whisper Large-v3**, and **Deepgram Nova-3**.
- 🌐 **Context-Aware Translation**: Translates subtitle streams in sliding-window batches with 1:1 segment alignment.
- 📐 **Broadcast Standard Formatting**: Adheres strictly to **BBC & Netflix Subtitle Guidelines** ($\le 42$ characters/line, natural breath breaks, millisecond timecodes).
- 🐳 **Docker CLI & Multi-Platform**: Run headlessly anywhere via Docker or natively on Android and Linux desktop.
- 🔒 **BYOK Privacy & Security**: Keys stored in hardware-backed secure storage (`Android Keystore` / `Linux Secret Service`). Your video never leaves your device.

---

## 🏗️ Architecture & Workflow

```mermaid
flowchart TD
    A["🎬 Raw Video (MP4 / MKV / MOV)"] --> B["⚙️ Edge Media Engine (FFmpeg / AVAsset)"]
    B --> C["🎵 Loudness Normalization & Filtering\n(16kHz mono, EBU R128 loudnorm)"]
    C --> D["✂️ Silence-Aware VAD Chunking\n(Midpoint silence split, 20MB hard-cap)"]
    
    subgraph Cloud ASR ["Stage 1: Speech-to-Text (BYOK)"]
        E1["⚡ Deepgram Nova-3"]
        E2["⚡ Groq Whisper Large-v3"]
        E3["⚡ Google Gemini 2.5 Flash"]
    end
    
    D --> Cloud ASR
    Cloud ASR --> F["🧩 Chunk Stitcher & Time Offset Realignment"]
    
    subgraph Cloud Translation ["Stage 2: Batched LLM Translation"]
        G1["🧠 Groq LLaMA 3.3 / Qwen"]
        G2["🧠 Gemini 2.5 Flash"]
    end
    
    F --> Cloud Translation
    Cloud Translation --> H["📐 Subtitle Formatter & Line Balancer\n(BBC/Netflix ≤42 chars/line)"]
    H --> I["💾 Output .SRT & .VTT Subtitles"]
    H --> J["🗄️ Drift SQLite Local Library"]
```

---

## 📊 Live Verification & Benchmarks

Real-world test benchmarks evaluated on full episodes and trimmed production video samples:

| Video Title | Source Audio | Duration | Transcriber | Translator | Total Time | Output |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Soul Land 2 (Ep 177)** | Chinese (`zh`) | 14.9 min (894s) | Groq Whisper Large-v3 | Groq LLM | **196 sec** | [`.srt`](test_samples/output_full_episode/Soul%20Land%202%20The%20Peerless%20Tang%20Sect%20Episode%20177%20Multiple%20Subtitles_1280x720.srt) |
| **Battle Through The Heavens** | Chinese (`zh`) | 30s dialogue | Deepgram Nova-3 | Gemini 2.5 Flash | **4.2 sec** | [`.srt`](test_samples/chinese_btth_dialogue_30s.en.srt) |
| **HUNTC-432 (Film Sample)** | Japanese (`ja`) | 45s dialogue | Deepgram Nova-3 | Gemini 2.5 Flash | **5.1 sec** | [`.srt`](test_samples/japanese_huntc_45s.en.srt) |
| **Solo Leveling (Ep 1)** | Japanese (`ja`) | 45s dialogue | Deepgram Nova-3 | Groq LLM | **3.8 sec** | [`.srt`](test_samples/japanese_solo_leveling_45s.srt) |

### Sample Output Comparison
```srt
1
00:00:07,760 --> 00:00:10,800
Xiao Yan will restore
the Xiao clan's glory.

2
00:00:19,465 --> 00:00:22,025
My unfinished business back then.

3
00:00:22,185 --> 00:00:24,825
Perhaps you can truly finish it.
```

---

## 🛠️ Installation & Setup

### Prerequisites

- **Flutter SDK**: `^3.44.8` (Channel stable)
- **Dart SDK**: `^3.12.2`
- **FFmpeg**: `ffmpeg` and `ffprobe` installed and on system `$PATH`

#### On Linux (Fedora / RHEL / CentOS)
```bash
sudo dnf install -y ffmpeg libsecret-devel clang cmake ninja-build pkg-config
```

#### On Linux (Ubuntu / Debian)
```bash
sudo apt-get install -y ffmpeg libsecret-1-dev clang cmake ninja-build pkg-config
```

#### On macOS
```bash
brew install ffmpeg
```

---

## 🐳 Docker CLI Quick Start

Run headless anywhere using the official Docker image:

```bash
# Pull the latest Docker image
docker pull adityapatra/subtitle-generator:latest

# Run subtitle generation on a video file
docker run --rm \
  -v $(pwd)/videos:/media/input \
  -v $(pwd)/subtitles:/media/output \
  -e GEMINI_API_KEY="your_api_key_here" \
  adityapatra/subtitle-generator:latest \
  -i /media/input/video.mp4 \
  -o /media/output \
  -s auto \
  -t en \
  -p action
```

See [DOCKERHUB.md](DOCKERHUB.md) for detailed CLI parameters and Docker Compose instructions.

---

### 📦 Development & Local Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/AdityaPatra-dev/subtitle_generator.git
   cd subtitle_generator
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API Keys (Optional Development File)**:
   Create `.env.development` in project root:
   ```env
   DEEPGRAM_API_KEY=your_deepgram_key_here
   GROQ_API_KEY=your_groq_key_here
   GEMINI_API_KEY=your_gemini_key_here
   ```
   *(Note: API keys can also be configured interactively inside the application's Settings UI).*

4. **Launch the Native Linux Desktop App**:
   ```bash
   flutter run -d linux
   ```

5. **Build the Android Production APK**:
   ```bash
   flutter build apk --release
   ```
   The compiled APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Running Automated Tests

Run the complete test suite:
```bash
# Unit & Widget tests
flutter test test/unit test/widget_test.dart

# Live integration tests with real audio
flutter test test/integration/live_all_providers_test.dart
flutter test test/integration/live_full_episode_pipeline_test.dart
```

---

## 📂 Project Structure

```
subtitle_generator/
├── android/                 # Android Gradle and Native Manifest
├── linux/                   # Linux Desktop CMake & C++ Runner
├── lib/
│   ├── core/
│   │   ├── constants/       # Enums, Provider models, languages
│   │   ├── security/        # Hardware-backed SecureStorageService
│   │   ├── storage/         # Drift SQLite database & table definitions
│   │   └── theme/           # Material 3 Theme & dynamic typography
│   ├── features/
│   │   ├── audio_processing/# VadChunkCalculator & silence parser
│   │   ├── media/           # ProcessMediaEngine (FFmpeg extraction/probing)
│   │   ├── providers/       # Deepgram, Groq Whisper, and Gemini ASR
│   │   ├── subtitles/       # SubtitleLineBreaker, SubtitleCue, Serializer
│   │   ├── transcription/   # PipelineCoordinator (End-to-End Orchestrator)
│   │   └── translation/     # TranslationService (LLaMA/Gemini context-aware)
│   └── presentation/
│       ├── providers/       # Riverpod state notifiers & coordinators
│       ├── screens/         # Home, JobDetails, Settings, SubtitlePreview
│       └── widgets/         # Progress bars, drop zones, cue cards
└── test/
    ├── integration/         # Live multi-provider & full-episode tests
    ├── unit/                # VAD calculation, DB lifecycle, Line breaker tests
    └── widget_test.dart     # UI component tests
```

---

## 📜 Subtitle Formatting Compliance

SubtitleGen strictly adheres to international broadcast standards:
- **Maximum Line Length**: 42 characters per line (English / Latin).
- **Line Count**: Max 2 lines per subtitle cue.
- **Reading Speed**: Capped between 15–17 characters per second.
- **Punctuation Break Priority**: Deterministic line breaks at natural pause punctuation (`.` `,` `?` `!` `—` `;`).

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<p align="center">
  Crafted with ❤️ by <a href="https://github.com/AdityaPatra-dev">Aditya Patra</a>
</p>
