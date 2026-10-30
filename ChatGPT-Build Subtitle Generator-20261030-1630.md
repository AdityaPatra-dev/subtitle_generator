# Project Specification: Cross-Platform AI Video Subtitle Generator
*(Smart Edge-Cloud Hybrid Architecture — BYOK Edition with Firebase Cross-Device Sync)*

---

## Executive Summary

This document specifies the complete architecture, engineering requirements, and user experience for a cross-platform application (Android, iOS, Windows, macOS, Linux) built with **Flutter**. The application empowers users to select long video files (up to 3+ hours) and produce broadcast-quality English subtitles in standard `.srt` and `.vtt` formats from spoken audio in Japanese, Chinese, Korean, and other world languages.

### Core Philosophy: The Pragmatic Edge-Cloud Split with Lightweight Firebase Sync
Previous specifications suffered from an impractical tension: they prohibited any local media processing while simultaneously demanding direct cloud API integration. Because cloud STT providers impose strict file-size limits (e.g., Groq's 25 MB cap) and uploading multi-gigabyte raw video files over consumer internet is slow, bandwidth-expensive, and prone to timeouts, this specification establishes an optimal **Smart Edge-Cloud Hybrid** model with **Firebase Cross-Device Cloud Sync**:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                CLIENT DEVICE (EDGE)                             │
│                  (Smartphones, Tablets, Laptops, Desktop Workstations)          │
│                                                                                 │
│  [Video File] ──► [Fast Audio Extraction] ──► [Audio Conditioning Filters]      │
│                            │                               │                    │
│                            ▼                               ▼                    │
│                  (Stream Demuxing / Lossless)    (16kHz Mono, EBU R128 Norm,    │
│                                                   High-Pass Voice Filter)       │
│                                                            │                    │
│                                                            ▼                    │
│  [Local Disk SRT] ◄── [Deterministic Subtitle] ◄── [VAD Silence Chunking]       │
│   & In-App Editor       Formatter & CJK Engine       (No Mid-Sentence Cuts)     │
└────────────────────────────┬────────────────────────────────────────────────────┘
                             │ Small Voice Chunks (3-8 MB each)
                             ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        USER'S OWN CLOUD ACCOUNTS (BYOK)                         │
│                    (Heavy Artificial Intelligence Lifting)                      │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │ 1. Speech-to-Text Inference:                                            │   │
│   │    • Groq (Whisper Large-v3) — Ultra-fast inference (<10s / chunk)       │   │
│   │    • Google Gemini (Gemini 2.5 / 3.5 Transcribe) — Multimodal context   │   │
│   │    • Deepgram (Nova-3 Multilingual) — Word-level timestamps & diarization│   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                    │                                            │
│                                    ▼ (Raw Timestamped Segments)                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │ 2. Context-Aware Neural Translation:                                    │   │
│   │    • Google Gemini / Groq LLM / DeepL API                               │   │
│   │    • Strict timestamp preservation & segment-id matching                │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────┬────────────────────────────────────────────┘
                                     │ Finished Lightweight SRT (~20-150 KB)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                       DEVELOPER'S FIREBASE CLOUD SYNC                           │
│                      (Cross-Device Subtitle Library & Sync)                     │
│                                                                                 │
│   • Google Sign-In (Firebase Auth) identifies the user across devices           │
│   • Generated SRT/VTT files & metadata stored under users/{userId}/subtitles    │
│   • User can view, search, preview & download their subtitles on ANY device     │
│   • Zero media storage burden: Videos and audio NEVER touch Firebase            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

- **Local Device (Edge)**: Performs lightweight media processing that everyday devices handle in seconds: demuxing audio tracks from video containers, applying audio speech enhancement filters, detecting speech pauses via Voice Activity Detection (VAD), slicing chunks at silence, formatting subtitles deterministically, and storing API keys securely.
- **User Cloud APIs (BYOK)**: Performs heavy neural network inference requiring server-grade GPUs: Whisper Large-v3 Speech-to-Text and contextual Large Language Model translation using the user's personal API keys.
- **Developer's Firebase Backend (Sync Only)**: Houses user authentication (Google Sign-In) and a synchronized cloud repository of generated `.srt`/`.vtt` files and job history. Because subtitle text files are tiny (2 KB to 200 KB), thousands of users can synchronize their library across devices without incurring meaningful storage or bandwidth costs for the developer.

---

## 1. Work Distribution: Edge, BYOK Cloud & Firebase

| Processing Stage | Where It Runs | Technology / Service | Why This Location Is Optimal |
|---|---|---|---|
| **Video File Selection & Validation** | Local Edge | Flutter File Picker / Native OS Dialogs | Zero bandwidth; instant file inspection. |
| **Audio Demuxing & Extraction** | Local Edge | Native OS Media Engine / Lightweight FFmpeg / Libav | Takes 5–20 seconds for a 3-hour video. Avoids uploading multi-gigabyte video files. |
| **Speech Audio Filtering** | Local Edge | FFmpeg Audio Filters / Native DSP | High-pass filter (removes rumble), loudness normalization, noise-floor reduction. |
| **Silence-Aware Chunking (VAD)** | Local Edge | Silero VAD / FFmpeg `silencedetect` | Slices audio only during natural pauses (>400ms), eliminating cut-off words and split phonemes. |
| **Speech-to-Text (STT) Transcription** | User Cloud (BYOK) | Groq Whisper Large-v3 / Gemini / Deepgram Nova-3 | Heavy AI model requiring high-end data-center GPUs. Fast and accurate. |
| **Language & Punctuation Cleanup** | Local Edge | Deterministic Dart CJK Engine | Instant regex & rule-based normalization for Japanese, Chinese, and Korean. |
| **Timestamped English Translation** | User Cloud (BYOK) | Gemini 2.5 Flash / Groq LLM | Preserves exact segment timestamps while providing natural, idiom-aware English. |
| **Subtitle Cue Generation & Wrapping** | Local Edge | Deterministic Dart Engine | Applies strict BBC / Netflix subtitle rules (reading speed, lines, character count). |
| **Local SRT / VTT Save & Editor** | Local Edge | Flutter UI + Local File System | Immediate offline playback, editing, and file saving beside the original video. |
| **Cross-Device Subtitle Cloud Sync** | Developer Firebase | Firebase Auth + Firestore / Cloud Storage | Syncs lightweight SRT files (`2–150 KB`) across all user devices by `userId`. |
| **Credential & Key Management** | Local Edge | Platform Hardware Keyring (Keystore/Keychain/DPAPI) | 100% private. Credentials never leave the user's physical hardware. |

---

## 2. Bring Your Own Key (BYOK) Architecture & Firebase Sync Model

### 2.1 The Two Operational Halves
1. **AI Processing Quota (BYOK - 100% User Owned)**:
   - Users provide their own API keys for Groq, Gemini, and Deepgram.
   - The developer never pays for AI transcription or translation tokens.
   - API keys are stored solely in platform-native secure vaults on the user's local hardware (Keystore, Keychain, DPAPI, Secret Service). They are **never** synced to Firebase.
2. **Subtitle Cloud Library (Developer Firebase - Lightweight Sync)**:
   - The developer provides the Firebase project configuration (`google-services.json` / `GoogleService-Info.plist` / web configuration).
   - Used exclusively for:
     1. User Authentication (Google Sign-In via Firebase Auth).
     2. Subtitle file storage & history (`.srt` / `.vtt` text files).
   - **Crucial Rule**: Videos, raw audio tracks, and user API keys **NEVER** get uploaded to Firebase. Only the resulting tiny subtitle text files and job metadata are synchronized.

### 2.2 Why Firebase Subtitle Sync Is Extremely Efficient for the Developer
- A 3-hour movie subtitle file contains roughly 1,500 to 2,500 subtitle cues, which takes only **~80 KB to 180 KB** of UTF-8 plain text.
- Firebase's free Spark plan includes:
  - **1 GB** of Cloud Storage (~10,000+ full-length subtitle files).
  - **1 GB** of Firestore database storage.
  - **50,000** document reads and **20,000** document writes per day.
- Storing users' generated subtitles provides immense user delight (multi-device access) at virtually **$0 cost** to the developer.

### 2.3 Supported Providers & Onboarding Experience
Users configure one, two, or all three providers via an intuitive in-app onboarding wizard with direct dashboard links, step-by-step screenshots, and one-tap test validation:

| Provider | Supported Model | Best For | Typical Free Tier / Cost |
|---|---|---|---|
| **Groq** | `whisper-large-v3` & `whisper-large-v3-turbo` | Lightning-fast transcription (~10x real-time speed) | Generous free tier with daily rate limits |
| **Google Gemini** | `gemini-2.5-flash` / `gemini-3.5-transcribe` | Rich context, direct translation, multimodal understanding | Free tier available via Google AI Studio |
| **Deepgram** | `nova-3` (Multilingual) | Accurate word timestamps, background noise resistance, diarization | \$200 free credit on signup |

#### In-App Key Validation Flow:
Before saving any key to secure storage, the application makes a minimal, non-metered validation request:
- **Groq**: `GET https://api.groq.com/openai/v1/models` with header `Authorization: Bearer <KEY>`.
- **Gemini**: `GET https://generativelanguage.googleapis.com/v1beta/models?key=<KEY>`.
- **Deepgram**: `GET https://api.deepgram.com/v1/projects` with header `Authorization: Token <KEY>`.

---

## 3. Firebase Architecture: Cross-Device Subtitle Library

### 3.1 Authentication
- Users sign in using **Google Sign-In** backed by **Firebase Authentication**.
- Every user is assigned a permanent, unique `uid`.
- If a user opens the app on an Android phone, transcribes a video, and later logs into the app on their Windows laptop or iPad with the same Google account, all their previously generated subtitles immediately appear in their **Cloud Subtitle Library**.

### 3.2 Firestore Data Schema
All records are sandboxed strictly under the user's `uid`:

```text
/users/{userId}/subtitles/{subtitleId}
```

#### Document Fields:
```json
{
  "id": "c8a4128f-79bc-4321-9e20-7b2434fa0912",
  "userId": "firebase_auth_uid_12345",
  "title": "Tokyo_Vlog_Episode_01.mp4",
  "sourceLanguage": "ja",
  "targetLanguage": "en",
  "durationSeconds": 1420.5,
  "providerUsed": "groq_whisper_large_v3",
  "cueCount": 438,
  "fileSizeBytes": 45120,
  "srtContent": "1\n00:00:02,100 --> 00:00:04,500\nHello and welcome to Tokyo!\n...",
  "storageDownloadUrl": "https://firebasestorage.googleapis.com/v0/b/.../subtitles/c8a4128f.srt",
  "createdAt": "2026-10-30T16:50:00Z",
  "updatedAt": "2026-10-30T16:50:00Z"
}
```
*(For subtitles under 800 KB, `srtContent` can be stored directly in Firestore for instant query retrieval. For larger files, the raw file is saved in Firebase Cloud Storage at `users/{userId}/subtitles/{subtitleId}.srt` and linked via `storageDownloadUrl`).*

### 3.3 Firebase Security Rules
To ensure total privacy and isolation, users can read and write only their own records:

#### Firestore Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/subtitles/{subtitleId} {
      allow read, write, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### Cloud Storage Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/subtitles/{fileName} {
      allow read, write, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3.4 Multi-Device User Experience
1. **Automatic Background Sync**: Once an SRT is generated and saved locally, the app asynchronously pushes the subtitle document to Firebase.
2. **Offline-First Synchronization**: If the user is offline or has spotty internet when generation finishes, the SRT is saved in the local SQLite database (`drift`). As soon as an internet connection is re-established, the sync worker pushes it to Firebase.
3. **Cross-Device Actions**:
   - Preview full subtitles with timestamps in-app.
   - One-tap "Download SRT / VTT" to the local device storage.
   - One-tap "Copy to Clipboard".
   - Search across past subtitles by video title, keywords, or date.
   - Delete from cloud and all synced devices.

---

## 4. Client-Side Audio Extraction & Pre-Processing Pipeline

### 4.1 Why Client-Side Audio Extraction Is Essential
A 3-hour 1080p/4K video typically weighs between **2 GB and 15 GB**. Attempting to upload this video directly to cloud transcription APIs causes:
- Immediate rejection by Groq (hard limit: 25 MB per request).
- Extreme mobile data consumption and battery drain.
- Severe risk of network timeouts and connection drops.

By extracting the audio stream locally and transcoding it to an optimized voice format, a 3-hour video is reduced to just **~35 MB to 45 MB** of pristine, speech-optimized audio. This extraction takes **under 30 seconds** on modern smartphones and laptops because the video frames are completely ignored and only the audio stream is processed.

### 4.2 Audio Conditioning & Voice Enhancement Filters
Raw video audio often contains background hiss, air conditioning rumble, mic bumps, or inconsistent volume levels. The local pre-processor applies a tailored digital signal processing (DSP) filtergraph:

```
[Raw Audio Track]
       │
       ▼
 [High-Pass Filter (80 Hz)]   ──► Removes low-frequency wind, handling noise, HVAC hum
       │
       ▼
 [Voice Bandpass / EQ]       ──► Gently enhances human vocal frequencies (300 Hz - 3400 Hz)
       │
       ▼
 [EBU R128 Loudness Norm]    ──► Normalizes speech volume (target -16 LUFS, true peak -1.5 dB)
       │
       ▼
 [Resample to 16 kHz Mono]   ──► Perfect sampling rate for Whisper and Nova models
       │
       ▼
 [Export: 32 kbps Opus/AAC]  ──► Ultra-compact, studio-clarity voice track
```

#### Standard FFmpeg Audio Filter Command:
```bash
ffmpeg -i input_video.mp4 -vn \
  -af "highpass=f=80,lowpass=f=8000,loudnorm=I=-16:TP=-1.5:LRA=11,aformat=sample_rates=16000:channel_layouts=mono" \
  -c:a libopus -b:a 32k -application voip \
  output_audio.opus
```
*(On systems where Opus is not supported by a specific provider endpoint, fallback to `-c:a libmp3lame -b:a 48k output_audio.mp3` or 16-bit PCM WAV for individual short chunks).*

### 4.3 Silence-Aware VAD Smart Chunking
Previous implementations failed by cutting audio at arbitrary time boundaries (e.g., exactly at 20:00.000), slicing words in half, corrupting phonemes, and causing hallucinated repetitions at chunk borders.

This application uses **Local Voice Activity Detection (VAD) / Silence Detection**:
1. Scan for natural silence intervals (`silencedetect=noise=-30dB:d=0.5`).
2. Target chunk duration: **10 to 15 minutes** (safely under 6 MB per chunk, well below all provider limits).
3. Chunk split points are snapped to the closest natural pause within a flexible window (e.g., between minute 10:00 and minute 12:00).
4. **Zero word clipping**: Audio is cut only when nobody is speaking.
5. **Exact global offset tracking**: Each chunk stores its precise `global_start_time_seconds`.

---

## 5. Two-Stage Decoupled Transcription & Translation Pipeline

To guarantee that subtitle timings are 100% authentic and that users never waste API quota, the workflow is strictly divided into two decoupled stages:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   STAGE 1: ORIGINAL-LANGUAGE TRANSCRIPTION             │
│                                                                        │
│   Pre-Processed Audio Chunks ──► Cloud STT Provider (Groq/Deepgram)     │
│                                                │                       │
│                                                ▼                       │
│                         High-Fidelity Original Transcript              │
│                       (Original Japanese / Chinese / Korean)           │
│                             + Ground-Truth Timestamps                  │
│                                                │                       │
│                                                ▼                       │
│                       Persisted Locally in SQLite Database             │
└────────────────────────────────────────────────┬───────────────────────┘
                                                 │
                                                 ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   STAGE 2: CONTEXT-AWARE NEURAL TRANSLATION            │
│                                                                        │
│   Original Transcript Segments ──► LLM Translation Engine (Gemini/Groq)│
│                                                │                       │
│                                                ▼                       │
│                          English Translation Text                      │
│                    (Strict 1:1 Preservation of Segment IDs)            │
│                                                │                       │
│                                                ▼                       │
│                      Deterministic Subtitle Cues (SRT/VTT)             │
│                                                │                       │
│                                                ▼                       │
│                  Local Disk Export + Firebase Cross-Device Sync        │
└────────────────────────────────────────────────────────────────────────┘
```

### 5.1 Why Decoupling Is Mandatory
1. **Never Re-Transcribe to Fix a Translation**: If the user wants a different translation style (e.g., formal vs. colloquial, or anime-specific honorifics), they simply re-run Stage 2. The audio never needs to be re-uploaded or re-transcribed.
2. **No Invented Timestamps**: Large Language Models (LLMs) must **never** be asked to invent or guess timestamps. Timestamps come exclusively from the acoustic speech model in Stage 1.
3. **Structured JSON Interchange**:
```json
[
  {
    "id": 104,
    "start": 142.350,
    "end": 145.820,
    "source_text": "東京タワーの近くにあるカフェに行きましょう。",
    "target_text": "Let's go to that cafe near Tokyo Tower."
  }
]
```

---

## 6. Language-Specific Tokenization & CJK Formatting

Previous projects produced broken subtitles for East Asian languages because naive spaces were inserted or characters were split indiscriminately. The subtitle engine implements dedicated linguistic rules:

### 6.1 Japanese (日本語)
- **Natural Boundary Recognition**: Japanese does not use whitespace. The engine segments along grammatical particle boundaries (`は`, `が`, `を`, `に`, `で`, `と`, `へ`, `から`, `まで`) and punctuation marks (`、`, `。`, `！`, `？`).
- **No Injected Spaces**: Never inject western spaces between Kanji and Kana characters.
- **Honorifics and Idioms**: Honorific suffixes (`-san`, `-kun`, `-chan`, `-sama`, `-sensei`) and compound nouns are never split across line breaks.

### 6.2 Chinese (中文 - Simplified & Traditional)
- **Semantic Chunking**: Group text by meaning phrases rather than splitting per character.
- **Punctuation Rules**: Full-width Chinese punctuation (`，`, `。`, `！`, `？`, `：`) dictates natural pause points.
- **Four-Character Idioms (成语 / Chengyu)**: Must always be preserved on a single line.

### 6.3 Korean (한국어)
- **Eojeol (어절) Preservation**: Korean uses spaces between grammatical word blocks (eojeol). Preserve original spacing intact.
- **Particle Attachment**: Josa (particles such as `은/는`, `이/가`, `을/를`) must stay attached to their preceding noun.

### 6.4 English Subtitle Formatting Standards (Netflix / BBC Compliant)
The final English subtitle renderer enforces standard broadcast readability criteria:
- **Maximum characters per line (CPL)**: 37 to 42 characters.
- **Maximum lines per cue**: 2 lines maximum (never 3+ lines or paragraphs).
- **Reading speed (CPS)**: Target 15–17 characters per second; hard cap at 20 CPS.
- **Minimum cue duration**: 1.0 second (to prevent flicker).
- **Maximum cue duration**: 7.0 seconds.
- **Inter-cue gap**: 2 frames (approx. 66–80 ms) to allow eye resting between subtitles.
- **Smart line breaking**: Breaks occur after punctuation, before conjunctions (`and`, `but`, `because`), or between major syntactic clauses.

---

## 7. Technical Specifications: Provider by Provider

### 7.1 Groq Whisper (`whisper-large-v3`)
- **API Endpoint**: `POST https://api.groq.com/openai/v1/audio/transcriptions`
- **Supported Formats**: `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, `webm`
- **File Size Limit**: 25 MB per request *(effortlessly satisfied by 10-15 min audio chunks)*
- **Parameters Required**:
  - `model`: `whisper-large-v3`
  - `response_format`: `verbose_json`
  - `timestamp_granularities[]`: `word` and `segment`
  - `language`: `ja`, `zh`, `ko`, or empty for auto-detection
- **Translation Strategy**: Use Groq for Stage 1 (STT). For Stage 2, either pass the structured transcript to `llama-3.3-70b-versatile` on Groq or use Gemini 2.5 Flash for nuanced translation.

### 7.2 Google Gemini (`gemini-2.5-flash` / `gemini-3.5-transcribe`)
- **API Endpoint**: Gemini REST API v1beta / Google GenAI SDK
- **Ingestion Mode**:
  - Short audio chunks: Inline base64 audio data.
  - Large audio: Direct upload via Google AI Studio File API (`POST https://generativelanguage.googleapis.com/upload/v1beta/files`).
- **Capabilities**: Exceptional multilingual comprehension, cultural nuance, context-aware idiom translation, and direct JSON schema structured output.

### 7.3 Deepgram Nova-3 (`nova-3` Multilingual)
- **API Endpoint**: `POST https://api.deepgram.com/v1/listen`
- **Ingestion Mode**: Direct binary audio streaming with header `Content-Type: audio/opus` (or `audio/mp3`).
- **Parameters Required**:
  - `model=nova-3`
  - `smart_format=true`
  - `diarize=true` *(optional speaker labeling)*
  - `utterances=true`
  - `words=true`
- **Response**: Ultra-high precision word-level timestamps, speaker indices, and confidence scores.

---

## 8. Application Architecture & Tech Stack

### 8.1 Cross-Platform Stack
- **Framework**: Flutter 3.x (Dart 3.x)
- **Supported Targets**: Android (API 24+), iOS (14.0+), Windows (10/11), macOS (11.0+), Linux (Ubuntu 20.04+, Fedora, Arch)
- **State Management**: `flutter_riverpod` (v2.x) with code generation for immutable, observable state
- **Authentication**: `firebase_auth` + `google_sign_in`
- **Cloud Subtitle Sync**: `cloud_firestore` + `firebase_storage`
- **Media Engine**: Native OS Media framework + `ffmpeg_kit_flutter_full` / desktop FFmpeg binaries
- **Secure Key Storage**: `flutter_secure_storage` with platform hardware security modules
- **Local Database**: `drift` (SQLite) for job queues, transcripts, cache, and history
- **Networking**: `dio` with custom retry interceptors, upload progress streams, and rate-limit backoff

### 8.2 Directory Structure
```text
lib/
├── core/
│   ├── constants/             # API routes, default subtitle parameters
│   ├── network/               # Dio client, retry policies, error mapping
│   ├── security/              # Secure key store, hardware token management
│   ├── storage/               # Drift SQLite database, local file manager
│   └── utils/                 # Timecode formatting, string sanitization
│
├── features/
│   ├── auth/                  # Google Sign-In & Firebase Auth state
│   ├── cloud_sync/            # Firebase Firestore & Storage sync coordinator
│   ├── media/                 # File picker, video demuxer, audio extractor
│   ├── audio_processing/      # DSP filters, VAD silence detector, audio chunker
│   ├── providers/             # Provider implementations
│   │   ├── base_provider.dart
│   │   ├── groq_whisper_provider.dart
│   │   ├── gemini_provider.dart
│   │   └── deepgram_provider.dart
│   ├── transcription/         # Stage 1 coordinator, chunk offset mapper
│   ├── translation/           # Stage 2 LLM translation engine
│   ├── subtitles/             # CJK tokenizer, Netflix/BBC rule engine, SRT/VTT serializer
│   ├── editor/                # In-app subtitle editor and preview player
│   └── settings/              # BYOK key configuration, cost estimator, preferences
│
└── presentation/
    ├── screens/               # Home, File Pick, Progress, Cloud Library, Editor, Settings
    ├── widgets/               # Chunk progress bar, waveform, provider status cards
    └── theme/                 # Modern Material 3 dark/light adaptive theme
```

---

## 9. Resilience, Recovery & Error Handling

### 9.1 Chunk-Level Fault Tolerance
- **Independent Chunk Retries**: If chunk 4 fails due to a network glitch or temporary 429 rate limit, only chunk 4 is retried with exponential backoff (`delay = min(base * 2^attempt, 30s)`). Completed chunks (1, 2, 3) are safely cached in SQLite and never repeated.
- **Process Resumption**: If the user closes the app or the OS terminates it during a 3-hour job, reopening the app instantly detects the partial job and prompts: *"Resume processing from chunk 5 of 12?"*
- **Offline Safe**: Once transcripts are downloaded, all formatting, editing, and exporting functions work 100% offline. Local changes sync to Firebase automatically once reconnected.

### 9.2 Quota & Cost Transparency
- Before processing begins, the app calculates total audio duration and displays an honest estimate:
  > *"Estimated audio duration: 2 hrs 45 mins (11 chunks of ~15 min).*  
  > *Selected Provider: Groq (Whisper Large-v3).*  
  > *Estimated API cost: \$0.00 (within free tier) or approx. \$0.18 at standard rates."*
- If a provider returns a `429 Too Many Requests` or `insufficient_quota` error, the app displays the exact provider error code along with actionable guidance (e.g. wait time or link to billing console). The app **never** silently swaps providers or spends a different quota without explicit user consent.

---

## 10. Comprehensive Testing & Acceptance Criteria

To be declared production-ready, the implementation must pass the following benchmark test suite:

| Test Case | Scenario | Acceptance Criteria |
|---|---|---|
| **Test 1: 5-Minute Anime Clip (Japanese)** | High-speed dialogue, background music, sound effects | Clean particle segmentation (`は`, `が`), no character spacing errors, zero invented timestamps. |
| **Test 2: 30-Minute Tech Lecture (Mandarin)** | Technical terminology, mixed English/Chinese terms | Accurate traditional/simplified characters, Chengyu preserved, natural sentence wrapping. |
| **Test 3: 45-Minute Drama Episode (Korean)** | Emotional speech, soft whispering, overlapping lines | Accurate eojeol spacing, correct sentence endings, speaker tags preserved if enabled. |
| **Test 4: Full 3-Hour Movie / Stream** | 180 minutes, multiple scene changes, varied volume | Audio extracted in <45s locally; all chunks processed; zero drift between 00:05:00 and 02:55:00; correct SRT output. |
| **Test 5: Cross-Device Firebase Sync** | Generate SRT on Android; log in on Windows PC | Windows app displays the newly created subtitle within 2 seconds; can preview and download .srt locally. |
| **Test 6: Offline & Resumption** | Wi-Fi toggled off mid-job; app swiped away during chunk 6 | App recovers seamlessly; resumes chunk 6 without re-transcribing chunks 1–5; syncs to Firebase once online. |

---

## 11. Summary of Architectural Advantages

By shifting audio extraction, voice enhancement filters, and silence detection to the local device while keeping heavy speech-to-text inference in the cloud and syncing subtitles to Firebase:
1. **Network Payload Reduced by 99%**: A 4 GB video upload becomes an ultra-compact ~35 MB audio upload.
2. **Groq 25 MB Limit Conquered**: Every chunk is guaranteed to be under 6 MB, making Groq's high-speed Whisper Large-v3 completely reliable.
3. **Seamless Multi-Device Experience**: Generated SRT files are automatically backed up to Firebase under the user's ID, allowing users to access their subtitle library from any phone, laptop, or desktop.
4. **Negligible Developer Cost**: Heavy video/audio is never uploaded to Firebase; only lightweight text SRT files (2–150 KB) are synced, easily staying well within Firebase's free tier.
5. **Full Security & Privacy**: User API keys stay securely locked in local hardware keyrings and are never transmitted to Firebase.
