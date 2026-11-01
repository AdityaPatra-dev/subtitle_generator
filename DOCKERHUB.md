# AI Subtitle Generator 🎬

[![Docker Image Version](https://img.shields.io/badge/docker-adityapatra%2Fsubtitle--generator-blue.svg?logo=docker)](https://hub.docker.com/r/adityapatra/subtitle-generator)
[![Version](https://img.shields.io/badge/version-1.0.6-emerald.svg)](https://github.com/adityapatra/subtitle_generator)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Autonomous, multi-engine AI Subtitle Generator CLI container powered by **Google Gemini 2.5 Flash**, **Groq Whisper Large v3 Turbo**, and **Deepgram Nova-3**. Automatically extracts audio, detects speech boundaries with silence-based VAD, transcribes dialogue, translates into 70+ target languages, and generates production-ready `.srt` and `.vtt` subtitle files.

---

## ✨ Features

- 🎯 **Smart Speech & Audio Profiles**:
  - `action`: **Action & Loud Audio Mode** equipped with dynamic audio normalization (`dynaudnorm`) and aggressive -20dB VAD threshold. Captures rapid dialogue, altered/synthetic voices, and shouting over explosive sound effects and loud background music.
  - `standard`: **Balanced Mode** (-28dB VAD) for general movies, TV shows, and anime.
  - `podcast`: **Clear Dialogue Mode** (-35dB VAD) with vocal isolation bandpass filter for interviews, courses, and podcasts.
- 🌍 **70+ Target Languages**:
  - Output subtitles in English, Spanish, Hindi, Japanese, Simplified/Traditional Chinese, French, German, Arabic, Korean, and dozens more.
  - Instant zero-token auto-bypass when source matches target.
- ⚡ **Multi-Engine Edge-Cloud Transcription**:
  - **Google Gemini 2.5 Flash**: Context-aware multilingual transcription with audio understanding.
  - **Groq Whisper Large v3 Turbo**: Blazing-fast inference for rapid subtitle generation.
  - **Deepgram Nova-3**: Enterprise-grade speech-to-text accuracy.
- 🔄 **Chunk-Level Checkpoint & Resume**:
  - Automatically caches extracted audio and tracks chunk progress in an embedded SQLite database. If a job is stopped or interrupted, re-running the same command resumes immediately where it left off.
- 📦 **Battery-Included Container**:
  - Includes FFmpeg and SQLite3 out of the box with zero host dependencies.

---

## 🚀 Quick Start

### 1. Pull the Image
```bash
docker pull adityapatra/subtitle-generator:latest
```

### 2. Generate Subtitles
Mount your video directory to `/media/input` and destination to `/media/output`:

```bash
docker run --rm \
  -v $(pwd)/videos:/media/input \
  -v $(pwd)/subtitles:/media/output \
  -e GEMINI_API_KEY="your_gemini_api_key_here" \
  adityapatra/subtitle-generator:latest \
  -i /media/input/movie.mp4 \
  -o /media/output \
  -s auto \
  -t en \
  -p action
```

The container extracts the audio, transcribes the speech, translates if needed, and writes:
- `/media/output/movie.srt`
- `/media/output/movie.vtt`

---

## 🛠️ CLI Options

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--input` | `-i` | *required* | Path to input video or audio file (`.mp4`, `.mkv`, `.webm`, `.avi`, `.mov`, `.mp3`, `.wav`, etc.) |
| `--output-dir` | `-o` | `./output` | Destination folder for `.srt` and `.vtt` subtitles |
| `--source-lang` | `-s` | `auto` | Spoken audio language (`auto`, `zh`, `ja`, `en`, `ko`, `es`, `hi`, etc.) |
| `--target-lang` | `-t` | `en` | Target subtitle language (`en`, `es`, `hi`, `zh-Hans`, `ja`, `fr`, `de`, `ar`, etc.) |
| `--profile` | `-p` | `action` | Audio & VAD profile: `action` (loud audio/BGM), `standard` (balanced), `podcast` (clear dialogue) |
| `--provider` | | `gemini` | Transcription engine: `gemini`, `groq`, `deepgram` |
| `--translation` | | `gemini` | Translation engine: `gemini`, `groq`, `none` |
| `--gemini-key` | | | Google Gemini API Key (or set `GEMINI_API_KEY` env var) |
| `--groq-key` | | | Groq API Key (or set `GROQ_API_KEY` env var) |
| `--deepgram-key` | | | Deepgram API Key (or set `DEEPGRAM_API_KEY` env var) |
| `--help` | `-h` | | Show usage help |

---

## 🔐 Environment Variables

| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | Google Gemini API key (recommended) |
| `GROQ_API_KEY` | Groq API key |
| `DEEPGRAM_API_KEY` | Deepgram API key |

---

## 🐳 Docker Compose Example

Create a `docker-compose.yml`:

```yaml
services:
  subtitles:
    image: adityapatra/subtitle-generator:latest
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    volumes:
      - ./media:/media/input:ro
      - ./subs:/media/output:rw
    command: >
      -i /media/input/episode1.mkv
      -o /media/output
      -s auto
      -t en
      -p action
```

Run with:
```bash
docker compose run --rm subtitles
```

---

## 📱 Mobile App (Android)

Looking for the native Android App with rich UI, background audio processing, progress indicators, runs manager, and live subtitle preview? Check out the GitHub repository and grab the pre-built APK from [Releases](https://github.com/adityapatra/subtitle_generator/releases).

---

## 📄 License

Distributed under the MIT License. See [LICENSE](https://github.com/adityapatra/subtitle_generator/blob/main/LICENSE) for more details.

