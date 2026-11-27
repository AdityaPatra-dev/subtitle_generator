# 🎧 Edge Audio DSP & Silence-Aware VAD Chunking

SubtitleGen AI never uploads raw video files (which can be 200 MB – 4 GB+). Instead, it extracts and normalizes a lightweight speech-optimized MP3 locally on-device before slicing it at natural pauses.

---

## 1. Cross-Platform `MediaEngine` Abstraction

Defined in [`lib/features/media/media_engine.dart`](../lib/features/media/media_engine.dart) with two platform implementations:

| Implementation | Platforms | How FFmpeg Runs |
| :--- | :--- | :--- |
| `FFmpegKitMediaEngine` | Android, iOS | In-process native `ffmpeg-kit-flutter` bindings (`FFmpegKit` / `FFprobeKit`). |
| `ProcessMediaEngine` | Linux, macOS, Windows, Docker CLI | Spawns system `ffmpeg` and `ffprobe` subprocesses (`Process.run`). |

---

## 2. Speech & Audio Profiles (`SpeechProfile`)

Defined in [`lib/core/constants/enums.dart`](../lib/core/constants/enums.dart), each profile configures both the **FFmpeg audio filter chain** and the **VAD silence detector**:

| Profile | Noise Floor (`noiseDb`) | Min Silence (`minSilenceDurationSeconds`) | MP3 Bitrate | Bandpass Filter | Dynamic Normalization (`dynaudnorm`) | Best For |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Action & Loud Audio** | `-20.0 dB` | `0.20s` | `48 kbps` | `40 Hz – 12,000 Hz` | **Enabled** (`f=150:g=15`) | Anime, donghua, action films with explosions & BGM |
| **Standard (Balanced)** | `-30.0 dB` | `0.35s` | `36 kbps` | `80 Hz – 8,000 Hz` | Disabled | Movies, TV series, general online videos |
| **Clear Speech / Dialogue** | `-38.0 dB` | `0.50s` | `32 kbps` | `100 Hz – 7,500 Hz` | Disabled | Podcasts, interviews, audiobooks, lectures |

Every extraction converts audio to **16 kHz mono** (`-ac 1 -ar 16000`) encoded with `libmp3lame`, reducing a 450 MB video down to ~1.4 MB of audio (~0.7 MB per 2-minute chunk).

---

## 3. Silence-Aware VAD Splitting (`VadChunkCalculator`)

Implemented in [`lib/features/audio_processing/vad_chunk_calculator.dart`](../lib/features/audio_processing/vad_chunk_calculator.dart):

1. **Detecting Silences**:
   - FFmpeg runs `-af silencedetect=noise=<noiseDb>dB:d=<minSilence>` with `-f null -`.
   - `VadChunkCalculator.parseSilenceOutput(stderr)` parses `silence_start` and `silence_end` pairs into `SilenceInterval` objects (with `midpoint = start + duration / 2`).

2. **Choosing Split Points (`calculateSplitPoints`)**:
   - **Short-video fast path**: If `totalDurationSeconds <= minChunkDurationSeconds * 1.5`, no splitting occurs (`[]`) — the entire audio is sent as 1 chunk.
   - Otherwise, for each window `[currentWindowStart + minChunk, currentWindowStart + maxChunk]`:
     - Filters `silenceIntervals` whose `midpoint` falls inside the window **and** leaves at least `minChunkDurationSeconds` of remaining audio at the end (preventing tiny trailing fragments).
     - Picks the silence midpoint **closest to `currentWindowStart + targetChunkDurationSeconds`**.
     - Falls back to exact `targetChunkDurationSeconds` if no silence exists in the window.

3. **Provider-Aware Chunk Sizing (`getChunkConfig`)**:

| Provider | Strategy | Target Duration | Min / Max | Concurrency | Why |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Google Gemini Flash** | `parallel` / `sequential` | `120s` (2m) | `60s – 150s` | `2` workers | Fits 15 RPM free tier (~2–4 RPM actual) & avoids drift |
| **Google Gemini Flash** | `largeChunk` | `300s` (5m) | `240s – 360s` | `1` worker | Fewer seams for calm dialogue |
| **Groq Whisper Large-v3** | `parallel` / `sequential` | `180s` (3m) | `150s – 210s` | `2` / `1` | Whisper 30s window; 3.5m cap prevents drift & fits 25 MB limit |
| **Deepgram Nova-3** | `parallel` / `sequential` | `300s` (5m) | `240s – 360s` | `2` / `1` | Frame-level CTC alignment has zero drift |
| **Deepgram Nova-3** | `largeChunk` | `720s` (12m) | `600s – 900s` | `1` worker | Long continuous context |

4. **20 MB Hard Cap Failsafe**:
   - `VadChunkCalculator.exceedsHardCap(fileSizeBytes)` enforces a strict `20 MB` ceiling (`20 * 1024 * 1024`) to stay safely below cloud payload limits.
