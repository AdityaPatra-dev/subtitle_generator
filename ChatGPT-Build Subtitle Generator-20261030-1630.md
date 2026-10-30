# Project Specification: Cross-Platform AI Video Subtitle Generator
*(Smart Edge-Cloud Hybrid Architecture — BYOK Edition with Firebase Cross-Device Sync)*

---

## Executive Summary

This document specifies the complete production architecture, engineering requirements, and user experience for a cross-platform application (Android, iOS, Windows, macOS, Linux) built with **Flutter**. The application empowers users to select long video files (up to 3+ hours) and generate broadcast-quality English subtitles in standard SubRip (`.srt`) and WebVTT (`.vtt`) formats from spoken audio in Japanese, Chinese, Korean, and other world languages.

### Technical Companion Documents (Single Source of Truth)
To ensure maximum token efficiency and eliminate development ambiguity during coding, consult the companion technical documents:
- [SCHEMA.md](file:///home/adityapatra/Documents/GitHub/subtitle_generator/SCHEMA.md): Complete Drift SQLite tables, SQLite FTS5 definitions, Firestore schemas, and Dart DTOs.
- [IMPLEMENTATION_GUIDE.md](file:///home/adityapatra/Documents/GitHub/subtitle_generator/IMPLEMENTATION_GUIDE.md): Verified `pubspec.yaml`, VAD parsing algorithms, Stage 2 Translation prompts, CJK line-breaking rules, and agent guidelines.

### Core Philosophy: The Pragmatic Edge-Cloud Split with Lightweight Firebase Sync
Previous approaches either prohibited local processing (causing severe upload bandwidth bottlenecks and hitting provider file-size ceilings) or tried to run heavy neural networks on consumer phones (causing overheating, crashes, and slow execution). 

This application establishes an optimal **Smart Edge-Cloud Hybrid** model with **Firebase Cross-Device Cloud Sync**:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                CLIENT DEVICE (EDGE)                             │
│                  (Smartphones, Tablets, Laptops, Desktop Workstations)          │
│                                                                                 │
│  [Video File] ──► [Multi-Track Probe] ──► [Native Audio Demux & DSP Filters]   │
│                            │                               │                    │
│                            ▼                               ▼                    │
│                    (ffprobe / AVAsset)           (16kHz Mono, EBU R128 Norm,    │
│                                                   High-Pass Voice Filter)       │
│                                                            │                    │
│                                                            ▼                    │
│  [Local Disk SRT/VTT] ◄── [Deterministic Subtitle] ◄── [Silence-Aware VAD]      │
│   & In-App Editor           Engine & CJK Rules          (Chunking + Hard-Cap)   │
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
│   │ 2. Batched Context-Aware Neural Translation:                            │   │
│   │    • Google Gemini 2.5 Flash / Groq LLM (Llama 3.3 70B)                 │   │
│   │    • Strict 1:1 segment-count validation & timestamp preservation       │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────┬────────────────────────────────────────────┘
                                     │ Finished Lightweight SRT (~20-150 KB)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                       DEVELOPER'S FIREBASE CLOUD SYNC                           │
│                      (Cross-Device Subtitle Library & Sync)                     │
│                                                                                 │
│   • Google Sign-In (Firebase Auth) gives users cross-device sync (or Guest)     │
│   • Metadata stored in Firestore; raw .srt/.vtt files in Cloud Storage          │
│   • Concurrency device locking & optimistic updatedAt conflict resolution       │
│   • Zero media storage burden: Videos and audio NEVER touch Firebase            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

- **Local Device (Edge)**: Performs lightweight media processing that everyday devices handle in seconds: demuxing audio tracks from video containers, applying audio speech enhancement filters, detecting speech pauses via Voice Activity Detection (VAD), slicing chunks at silence with hard-cap limits, formatting subtitles deterministically, and storing API keys securely.
- **User Cloud APIs (BYOK)**: Performs heavy neural network inference requiring server-grade GPUs: Whisper Large-v3 Speech-to-Text and contextual Large Language Model translation using the user's personal API keys.
- **Developer's Firebase Backend (Sync Only)**: Houses optional user authentication (Google Sign-In) and a synchronized cloud repository of generated `.srt`/`.vtt` files and job history. Because subtitle text files are tiny (2 KB to 200 KB), thousands of users can synchronize their library across devices without incurring meaningful storage or bandwidth costs for the developer.

---

## 1. Work Distribution: Edge, BYOK Cloud & Firebase

| Processing Stage | Where It Runs | Technology / Service | Why This Location Is Optimal |
|---|---|---|---|
| **Video File Selection & Validation** | Local Edge | Flutter File Picker / Native OS Dialogs | Zero bandwidth; instant file inspection. |
| **Multi-Audio Track Probe** | Local Edge | `ffprobe` / `AVAssetTrack` inspection | Identifies languages and codecs; lets user pick commentary vs main audio. |
| **Audio Demuxing & Extraction** | Local Edge | Native OS Media Engine / Lightweight FFmpeg | Takes 5–20 seconds for a 3-hour video. Avoids uploading multi-gigabyte video files. |
| **Speech Audio Filtering** | Local Edge | FFmpeg Audio Filters / Native DSP | High-pass filter (removes rumble), loudness normalization, noise-floor reduction. |
| **Silence-Aware Chunking (VAD)** | Local Edge | Silero VAD / FFmpeg `silencedetect` + Hard Cap | Slices audio only during natural pauses (>400ms), eliminating cut-off words. |
| **Speech-to-Text (STT) Transcription** | User Cloud (BYOK) | Groq Whisper Large-v3 / Gemini / Deepgram Nova-3 | Heavy AI model requiring high-end data-center GPUs. Fast and accurate. |
| **Language & Punctuation Cleanup** | Local Edge | Deterministic Dart CJK Engine | Instant regex & rule-based normalization for Japanese, Chinese, and Korean. |
| **Batched English Translation** | User Cloud (BYOK) | Gemini 2.5 Flash / Groq LLM | Preserves exact segment timestamps while providing natural, idiom-aware English. |
| **Subtitle Cue Generation & Wrapping** | Local Edge | Deterministic Dart Engine | Applies strict BBC / Netflix subtitle rules (reading speed, lines, character count). |
| **Local SRT / VTT Save & Editor** | Local Edge | Flutter UI + Local File System | Immediate offline playback, editing, and file saving beside the original video. |
| **Cross-Device Subtitle Cloud Sync** | Developer Firebase | Firebase Auth + Firestore / Cloud Storage | Syncs lightweight SRT files (`2–150 KB`) across all user devices by `userId`. |
| **Credential & Key Management** | Local Edge | Platform Hardware Keyring (Keystore/Keychain/DPAPI) | 100% private. Credentials never leave the user's physical hardware. |

---

## 2. Bring Your Own Key (BYOK) Architecture & Zero-Backend Invariant

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

### 2.2 Supported Providers & Onboarding Experience
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

### 3.1 Authentication & Guest Mode

#### 3.1.1 Google Sign-In (Optional — Cloud Sync Mode)
Users may optionally sign in with Google via Firebase Authentication.
- On sign-in, the user receives a permanent, stable `uid`.
- Cloud sync is enabled only when signed in.
- If a user generates subtitles on Android and later logs into the same Google account on Windows or iPad, their full subtitle library is immediately available on the new device.

#### 3.1.2 Guest / Offline-Only Mode (Always Available)
**Firebase sign-in is NEVER a requirement to use the application.**
A user who declines sign-in, is in a region where Google services are blocked (e.g., mainland China), or whose Firebase auth fails transiently must still be able to:
- Configure BYOK provider credentials.
- Select video files and extract audio.
- Run the full transcription + translation pipeline.
- Export and save `.srt` / `.vtt` files locally.
- View and search their local history (SQLite only).

Cloud sync features (cross-device library, background upload) are cleanly paused in guest mode. The UI displays an unobtrusive banner:
> "Sign in with Google to sync your subtitles across all your devices."

**State transitions:**
- **Guest → Signed-in**: The client automatically enqueues all locally-stored, unsynced subtitles and synchronizes them to Firebase in the background.
- **Signed-in → Sign-out**: Cloud sync is paused. Local data is preserved. API keys in the hardware keyring are NOT deleted on sign-out (they are device-local credentials, not account credentials). The user is prompted:
  > "Signing out will pause cloud sync. Your local subtitles and API keys will remain on this device. Do you also want to clear your local subtitle history?" `[Clear History]` `[Keep History]` `[Cancel]`

#### 3.1.3 External Revocation Handling
If the user revokes Google Sign-In permissions externally (via myaccount.google.com), the Firebase SDK returns `user-token-revoked` or `user-disabled`. The client must:
1. Catch `FirebaseAuthException`.
2. Transition smoothly to Guest / Offline-Only Mode.
3. Show a non-blocking snackbar: *"Your Google session has expired. Sign in again to re-enable cloud sync."*
4. All local subtitle files and local SQLite records remain completely intact.

---

### 3.2 Firestore Data Schema

#### 3.2.1 Collection Path
```text
/users/{userId}/subtitles/{subtitleId}
```
All records are sandboxed strictly under the authenticated user's `uid`. No cross-user access is permitted.

#### 3.2.2 Subtitle Metadata Document (Firestore)
**CANONICAL ARCHITECTURAL RULE:** The raw subtitle file content (`.srt` / `.vtt`) is **ALWAYS stored in Firebase Cloud Storage**. The Firestore document stores **ONLY metadata and Storage reference paths**. There is no inline `srtContent` field. This eliminates the split-brain state and race conditions entirely.

```json
{
  "id": "c8a4128f-79bc-4321-9e20-7b2434fa0912",
  "userId": "firebase_auth_uid_12345",
  "title": "Tokyo_Vlog_Episode_01",
  "originalFilename": "Tokyo_Vlog_Episode_01.mp4",
  "sourceLanguage": "ja",
  "targetLanguage": "en",
  "durationSeconds": 1420.5,
  "providerUsed": "groq_whisper_large_v3",
  "translationModel": "gemini_2_5_flash",
  "cueCount": 438,
  "fileSizeBytes": 45120,
  "storagePath": "users/firebase_auth_uid_12345/subtitles/c8a4128f.srt",
  "storagePathVtt": "users/firebase_auth_uid_12345/subtitles/c8a4128f.vtt",
  "jobStatus": "COMPLETED",
  "processingDeviceId": null,
  "isDirty": false,
  "isDeleted": false,
  "schemaVersion": 1,
  "createdAt": "2026-10-30T16:50:00Z",
  "updatedAt": "2026-10-30T16:52:00Z"
}
```

| Field | Type | Description |
|---|---|---|
| `id` | `string` | UUID v4 generated on creating device. Used as Firestore document ID and Storage filename stem. |
| `userId` | `string` | Firebase Auth UID. Must match authenticated user. |
| `title` | `string` | User-editable display name (defaults to video filename without extension). |
| `originalFilename` | `string` | Immutable original source video filename. |
| `sourceLanguage` | `string` | BCP-47 language tag (e.g., `ja`, `zh-Hans`, `ko`). |
| `targetLanguage` | `string` | BCP-47 language tag of output (defaults to `en`). |
| `durationSeconds` | `float` | Total audio duration processed in seconds. |
| `providerUsed` | `string` | Enum: `groq_whisper_large_v3`, `gemini_2_5_transcribe`, `deepgram_nova_3`. |
| `translationModel` | `string` | Enum: `gemini_2_5_flash`, `groq_llama_3_3_70b`. `null` if source was English. |
| `cueCount` | `int` | Total subtitle cues in final SRT. |
| `fileSizeBytes` | `int` | Size of `.srt` file in bytes. |
| `storagePath` | `string` | Cloud Storage path for `.srt` file. |
| `storagePathVtt` | `string` | Cloud Storage path for `.vtt` file (`null` if not exported). |
| `jobStatus` | `string` | See §10 Job State Machine. |
| `processingDeviceId` | `string` | Device UUID when actively processing; `null` when idle/completed. |
| `isDirty` | `bool` | `true` if local edits have not yet uploaded to Cloud Storage. |
| `isDeleted` | `bool` | Soft-delete flag. Query filters out `isDeleted == true`. |
| `schemaVersion` | `int` | Schema version counter for future client migrations. |
| `createdAt` | `timestamp` | ISO 8601 UTC. Set once on creation. |
| `updatedAt` | `timestamp` | ISO 8601 UTC. Updated on every write for optimistic concurrency control. |

---

### 3.3 Firebase Security Rules

#### 3.3.1 Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/subtitles/{subtitleId} {
      allow get, list: if request.auth != null
                       && request.auth.uid == userId
                       && resource.data.isDeleted == false;

      allow create: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.data.userId == userId
                    && request.resource.data.isDeleted == false;

      allow update: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.data.userId == userId
                    && request.resource.data.createdAt == resource.data.createdAt;

      allow delete: if false; // Hard deletes prohibited. Soft delete via isDeleted: true.
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

#### 3.3.2 Cloud Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/subtitles/{fileName} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      allow delete: if request.auth != null
                    && request.auth.uid == userId;
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

### 3.4 Cross-Device Sync Behavior

1. **Upload Sequence**:
   - Subtitle generation finishes; `.srt` and `.vtt` are saved to local filesystem and local SQLite.
   - If signed in and online:
     1. Upload `.srt` to `users/{uid}/subtitles/{id}.srt` in Cloud Storage.
     2. Upload `.vtt` to `users/{uid}/subtitles/{id}.vtt` in Cloud Storage (if enabled).
     3. Write metadata document to Firestore.
     4. Mark local SQLite record as `isDirty = false`.
   - If offline: Enqueue sync operation in local SQLite `sync_queue`. Sync triggers automatically when internet is detected.
2. **Download / On-Demand Access**:
   - When a user logs in on a new device, the app queries Firestore metadata only (lightweight, fast).
   - The full `.srt` file is fetched from Cloud Storage **on-demand** (lazy loaded) only when the user taps preview, edit, or download. Once downloaded, it caches in local SQLite.

---

### 3.5 Multi-Device Concurrency & Locking

**Problem:** User starts a 3-hour job on their phone, then opens their laptop, sees the job, and hits "Resume", causing duplicate API uploads and burning double quota.

**Solution: Firestore Optimistic Device Lock**
- When a device starts audio processing or transcription, it executes a Firestore transaction writing:
  `{ processingDeviceId: "<this_device_id>", jobStatus: "TRANSCRIBING" }`.
- If `processingDeviceId != null && processingDeviceId != this_device_id`, the job is locked.
- UI on conflict:
  > *"This job is already actively processing on another device (Device ID: ...abc). Processing simultaneously will burn duplicate quota. [Wait] [Force Take Over]"*
- On job finish, cancellation, or failure: `processingDeviceId` is cleared to `null`.

---

### 3.6 Edit Conflict Resolution (Optimistic Concurrency)

- When saving edits back to Cloud Storage, the client checks the remote Firestore document's `updatedAt`.
- If `remote.updatedAt > local.loadedAt` (another device edited the subtitle in the meantime), the UI displays:
  > *"This subtitle was modified on another device at [time]. [Keep Remote Version] [Overwrite with My Edits]"*
- Debounce: Local keystrokes update local SQLite instantly. Cloud Storage upload occurs only on explicit "Save to Cloud" or upon navigating away from the editor.

---

### 3.7 Deletion & Account Management

- **Soft Delete**: Deleting a subtitle sets `isDeleted = true` in Firestore and deletes the `.srt`/`.vtt` files from Cloud Storage. Real-time snapshot listeners immediately remove the item from all active devices.
- **Account Deletion (GDPR)**: Available in Settings → Account → "Delete My Account". On re-authentication, recursively deletes all user files in Cloud Storage, all Firestore documents under `/users/{uid}/**`, deletes the Firebase Auth record, and purges local SQLite and hardware keyrings.

---

### 3.8 Local Search Strategy (SQLite FTS5)

Firestore does not provide scalable, zero-cost full-text search. The application implements search locally:
- Full-text search over subtitle text cues runs via an SQLite `fts5` virtual table on locally cached subtitles.
- Searches execute in under 10ms with zero network requests.
- Cloud-only subtitles (metadata loaded, but SRT not yet downloaded) are searchable by title, language, and date. Tapping a cloud result downloads and indexes the cues locally.

---

## 4. Cross-Platform Media Engine

### 4.1 Platform Architecture & Abstract Media Engine

To resolve `ffmpeg_kit_flutter_full` abandonment on Apple platforms, the app defines a unified Dart abstraction (`MediaEngine`) implemented via platform-native backends:

```dart
abstract class MediaEngine {
  Future<MediaInfo> probe(String filePath);
  Future<AudioExtractionResult> extractAudio({
    required String inputPath,
    required String outputPath,
    required int audioStreamIndex,
    required AudioExtractionConfig config,
  });
  Future<List<String>> splitAudioAtTimestamps({
    required String inputPath,
    required List<double> splitPointsSeconds,
    required String outputDir,
  });
}
```

### 4.2 Platform-by-Platform Engine Implementations

| Platform | Primary Audio Extractor | Probe Tool | DSP Filterpass |
|---|---|---|---|
| **Android (API 24+)** | `ffmpeg_kit_flutter_full` (community fork) | `ffmpeg_kit` ffprobe | `ffmpeg_kit` filtergraph |
| **iOS (14.0+)** | Native `AVFoundation` via Platform Channel | Bundled minimal static `ffprobe` | Bundled minimal static `ffmpeg` |
| **macOS (11.0+)** | Native `AVFoundation` via Platform Channel | Bundled static `ffprobe` | Bundled static `ffmpeg` |
| **Windows (10/11)** | Bundled static `ffmpeg.exe` via `Process.run()` | Bundled static `ffmpeg.exe` | Bundled static `ffmpeg.exe` |
| **Linux (Ubuntu/Arch)**| System `ffmpeg` via `Process.run()` | System `ffprobe` | System `ffmpeg` |

#### Linux Startup Check:
On Linux, the app checks `which ffmpeg` and `which ffprobe` at launch. If missing, it displays a blocking dialog instructing the user to install them via their package manager (`sudo apt install ffmpeg` / `sudo pacman -S ffmpeg`).

---

### 4.3 Multi-Audio Track Probe & Selection

Many movie rips contain multiple audio tracks (e.g. Japanese 5.1, English dub, Director's Commentary). Relying on default FFmpeg stream selection often extracts the wrong track.

#### Probe Inspection:
```bash
ffprobe -v quiet -print_format json -show_streams -select_streams a "input_video.mkv"
```

#### Track Selection UI:
- **Single Track**: Auto-selected with an info pill: *"Audio: Japanese (AAC Stereo)"*.
- **Multiple Tracks**: Displays a track selector sheet showing language, codec, channel count, and bitrate.
- **Recommendation Logic**:
  - Matches track `tags.language` against user's chosen source language.
  - Defaults to highest bitrate track if multiple matches exist.
- **Explicit Extraction**: Every extraction command passes `-map 0:a:<selected_index>` to guarantee extraction of the correct track.

---

### 4.4 Temporary File Lifecycle & Storage Cleanup

A 3-hour video generates ~100–150 MB of temporary audio during processing.

#### Pre-Extraction Storage Check:
```dart
final requiredBytes = estimatedAudioSize * 2.2;
final availableBytes = await getAvailableDiskSpace();
if (availableBytes < requiredBytes) {
  throw InsufficientStorageException(requiredBytes, availableBytes);
}
```

#### Deletion Lifecycle:
1. **Immediate Chunk Cleanup**: As soon as Chunk $N$ STT response is validated and stored in SQLite, `{jobId}_chunk_N.mp3` is deleted immediately.
2. **Post-Transcription Cleanup**: Once all chunks are transcribed, the primary extracted audio file `{jobId}_full.mp3` is deleted.
3. **Cancellation / Error**: On user cancellation, all temporary files matching `{jobId}_*` are deleted instantly.
4. **App Launch Cleanup**: On every app start, the temp directory is scanned; any orphaned audio files older than 24 hours or not associated with an active SQLite job are purged.

---

## 5. Audio Conditioning & Silence-Aware VAD Chunking

### 5.1 Speech Audio Conditioning Pipeline
Before audio is submitted to any cloud model, it passes through a calibrated DSP filtergraph to maximize speech intelligibility:

```bash
ffmpeg -i input_video.mp4 -vn -map 0:a:0 \
  -af "highpass=f=80,lowpass=f=8000,loudnorm=I=-16:TP=-1.5:LRA=11,aformat=sample_rates=16000:channel_layouts=mono" \
  -c:a libmp3lame -b:a 48k output_audio.mp3
```

- **High-Pass (80 Hz)**: Removes HVAC hum, desk bumps, wind, and mic handling rumble.
- **Low-Pass (8000 Hz)**: Eliminates high-frequency hiss outside human vocal ranges.
- **Loudness Normalization (EBU R128)**: Normalizes volume to target -16 LUFS (True Peak -1.5 dB), ensuring whispers and loud shouts are transcribed with equal accuracy.
- **16 kHz Mono**: The exact native sampling rate of Whisper and Deepgram Nova models. Reduces file size by 50% vs stereo.

---

### 5.2 Silence-Aware VAD Chunking & Hard-Cap Failsafe

Arbitrary time cutting (e.g. slicing exactly at 15:00.000) slices words in half and causes hallucinations.

```
00:00                Target: 12m                   24m
  ├─── Speech ───[Pause: 600ms]─── Speech ──────────┤
                       ▲
                  Split Here!
```

1. **VAD Scan**: Scan audio using FFmpeg `silencedetect=noise=-30dB:d=0.4` or Silero VAD.
2. **Flexible Window**: Target chunk length is 12 minutes. The splitter searches for silence pauses (>400ms) between minute 10:00 and minute 14:00.
3. **No-Silence Fallback (Continuous Speech / Music)**:
   - If no silence period $\ge 400\text{ms}$ is found within the window (e.g. uninterrupted concert commentary or wall-to-wall music), the splitter falls back to cutting at the exact 12:00 mark with a 2-second overlap, logging a non-critical warning.
4. **20 MB Hard-Cap Failsafe**:
   - Regardless of VAD results, every generated chunk file is checked before upload:
     `if (chunkFile.lengthInBytes > 20 * 1024 * 1024) splitChunkInHalf(chunkFile);`
   - This ensures **zero risk** of ever exceeding Groq's strict 25 MB API limit.
5. **Timestamp Offset Tracking**:
   - Each chunk retains its global offset: $\text{GlobalTime} = \text{ChunkStartTime} + \text{LocalCueTime}$.

---

## 6. Two-Stage Decoupled Transcription & Translation Pipeline

### 6.1 Why Decoupling Is Mandatory
1. **Never Re-Transcribe to Fix Translation**: If a user wants to alter translation nuance (formal vs informal, British vs American English), they simply re-run Stage 2. The audio is never re-uploaded or re-transcribed.
2. **Zero Invented Timestamps**: Large Language Models must **never** invent timestamps. Timestamps come exclusively from acoustic models in Stage 1.

---

### 6.2 Translation Provider Selection & Fallback Logic

Users configure which translation model to use in Settings → Translation Engine:

| Transcription Provider Used | Default Translation Engine | Fallback Translation Option |
|---|---|---|
| **Google Gemini** | Gemini 2.5 Flash | Groq Llama 3.3 70B Versatile |
| **Groq Whisper** | Groq Llama 3.3 70B Versatile | Gemini 2.5 Flash |
| **Deepgram Nova-3** | Gemini 2.5 Flash *(requires Gemini key)* | Groq Llama 3.3 70B *(requires Groq key)* |

**Deepgram Edge Case Handled**: Deepgram Nova-3 is a dedicated transcription engine without built-in LLM translation. If a user connects only Deepgram and requests English translation, the UI prompts:
> *"Deepgram provides transcription only. To translate to English, please connect a free Gemini or Groq API key in Settings, or export original-language subtitles."*

---

### 6.3 Batched Translation & Segment-Count Validation

For a 3-hour video with ~2,500 segments, sending all cues in a single prompt causes token exhaustion and silent segment truncation.

1. **Batch Slicing**: Transcript segments are grouped into batches of **60 to 80 segments** (~1,500 tokens of input).
2. **Context Window**: Each batch includes the final 2 translated segments of the previous batch as read-only context to preserve narrative continuity.
3. **Structured Schema**:
```json
{
  "segments": [
    {"id": 101, "translation": "Good morning everyone."},
    {"id": 102, "translation": "Today we will explore Tokyo Tower."}
  ]
}
```
4. **Strict Segment-Count Validation**:
   - If the LLM returns 58 translations for 60 input segments, the client rejects the response, splits the batch into two smaller 30-segment sub-batches, and retries.
   - Timestamps are matched strictly by `id`: $\text{Cue}[i].\text{start}$ and $\text{Cue}[i].\text{end}$ are copied from Stage 1. The LLM only supplies the translated text.

---

## 7. Language-Specific Tokenization & Subtitle Standards

### 7.1 CJK Linguistic Formatting Rules

#### Japanese (日本語)
- Segment at natural particle boundaries (`は`, `が`, `を`, `に`, `で`, `と`, `へ`, `から`, `まで`) and punctuation (`、`, `。`).
- **Zero Injected Spaces**: Never insert western whitespace between Kanji and Kana characters.
- Honorifics (`-san`, `-kun`, `-chan`, `-sama`) remain attached to preceding names.

#### Chinese (中文)
- Segment by semantic breath-groups rather than individual characters.
- Full-width punctuation (`，`, `。`, `！`, `？`) marks natural cue boundaries.
- Four-character idioms (成语 / Chengyu) are never split across lines.

#### Korean (한국어)
- Eojeol (어절) whitespace spacing is preserved intact.
- Agglutinative particles (조사: `은/는`, `이/가`, `을/를`) remain glued to nouns.

---

### 7.2 Subtitle Format Specifications (SRT & WebVTT)

The engine formats subtitles to Netflix / BBC broadcast standards:
- **Max Characters per Line (CPL)**: 37 to 42 characters.
- **Max Lines per Cue**: 2 lines maximum.
- **Reading Speed (CPS)**: Target 15–17 characters per second (hard cap: 20 CPS).
- **Duration**: Minimum 1.0s, maximum 7.0s.
- **Inter-cue Gap**: 2 frames (~66–80 ms) to prevent visual flash fatigue.

#### SubRip (.srt) Example:
```srt
1
00:01:23,450 --> 00:01:26,200
Good morning everyone.
Welcome to Tokyo!
```

#### WebVTT (.vtt) Example:
```vtt
WEBVTT - Generated by SubtitleGenerator

1
00:01:23.450 --> 00:01:26.200
Good morning everyone.
Welcome to Tokyo!
```
*(WebVTT uses period decimal separators instead of commas, and includes the mandatory `WEBVTT` header).*

---

## 8. Provider Technical Specifications

### 8.1 Groq Whisper (`whisper-large-v3`)
- **Endpoint**: `POST https://api.groq.com/openai/v1/audio/transcriptions`
- **Headers**: `Authorization: Bearer <GROQ_API_KEY>`
- **Body**: `multipart/form-data`
  - `file`: audio chunk binary (`audio/mpeg`)
  - `model`: `whisper-large-v3`
  - `response_format`: `verbose_json`
  - `timestamp_granularities[]`: `segment`, `word`
  - `temperature`: `0.0`
- **Rate Limit Handling**: Exponential backoff on HTTP 429 (`delay = min(base * 2^attempt, 30s)`).

---

### 8.2 Google Gemini (`gemini-2.5-flash` / `gemini-3.5-transcribe`)
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=<GEMINI_KEY>`
- **Ingestion Threshold**:
  - Chunks $< 15\text{MB}$: Transmitted as inline base64 data in `inlineData` object (`mimeType: "audio/mp3"`).
  - Chunks $\ge 15\text{MB}$: Uploaded via Gemini Resumable File API:
    `POST https://generativelanguage.googleapis.com/upload/v1beta/files?key=<KEY>`
- **48-Hour File API Lifecycle**: Files uploaded to Gemini's File API automatically delete after 48 hours. The client explicitly calls `DELETE https://generativelanguage.googleapis.com/v1beta/files/<file_id>` immediately after transcription finishes.
- **Structured Schema Parameter**:
  ```json
  "generationConfig": {
    "responseMimeType": "application/json",
    "responseSchema": {
      "type": "ARRAY",
      "items": {
        "type": "OBJECT",
        "properties": {
          "start": {"type": "NUMBER"},
          "end": {"type": "NUMBER"},
          "text": {"type": "STRING"}
        },
        "required": ["start", "end", "text"]
      }
    }
  }
  ```

---

### 8.3 Deepgram Nova-3 (`nova-3` Multilingual)
- **Endpoint**: `POST https://api.deepgram.com/v1/listen`
- **Headers**:
  - `Authorization: Token <DEEPGRAM_KEY>`
  - `Content-Type: audio/mp3`
- **Query Parameters**:
  `model=nova-3&smart_format=true&utterances=true&punctuate=true&diarize=true`
- **Synchronous Execution Guarantee**:
  - To avoid requiring developer callback webhooks, all Deepgram calls run in **synchronous request mode**.
  - Chunk lengths are kept to $\le 15$ minutes, keeping HTTP response times within standard 60-second client timeouts.

---

### 8.4 Secure Credential Storage & Linux Secret Service Check

API keys are stored in hardware-backed platform vaults:
- **Android**: Android Keystore with `EncryptedSharedPreferences`.
- **iOS / macOS**: Apple Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- **Windows**: Windows Credential Manager / DPAPI.
- **Linux Check**:
  - `flutter_secure_storage` requires `libsecret` and a running DBus Secret Service daemon (e.g. `gnome-keyring`, `ksecretservice`).
  - At Linux startup, the app checks if Secret Service is available.
  - If unavailable (e.g. minimal WM or headless desktop), the app displays a security notice and offers an AES-GCM encrypted file store protected by a user-chosen master password.

---

## 9. Subtitle Editor & In-App Preview

The application includes a built-in interactive subtitle editor:

```
┌──────────────────────────────────────────────────────────┐
│  00:01:23,450 ──► 00:01:26,200                [Delete]   │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Good morning everyone. Welcome to Tokyo!           │  │
│  └────────────────────────────────────────────────────┘  │
│  [ -100ms ] [ +100ms ]      [ Split Cue ] [ Merge Next ] │
└──────────────────────────────────────────────────────────┘
```

- **In-Place Editing**: Tapping any cue allows text editing with instant CPL and reading speed warnings.
- **Timestamp Nudge**: One-tap `+100ms` / `-100ms` nudge buttons for start and end times.
- **Split & Merge**: Split a long subtitle at cursor position, or merge two adjacent cues.
- **Save Debounce**: Edits persist to local SQLite immediately. Cloud sync executes on explicit "Save to Cloud" or screen exit.

---

## 10. Formal Job State Machine & Resilience

```
[ PENDING ]
     │ User taps Start
     ▼
[ EXTRACTING_AUDIO ] ──► (Probe audio tracks, demux selected track, apply DSP filters)
     │
     ▼
[ CHUNKING ]         ──► (Silence-aware VAD scan + 20MB hard-cap enforcement)
     │
     ▼
[ TRANSCRIBING ]     ──► (Upload chunks to BYOK STT; retry failed chunks independently)
     │
     ▼
[ TRANSLATING ]      ──► (Batched LLM translation; 1:1 segment validation)
     │
     ▼
[ FORMATTING ]       ──► (CJK rules, CPL limits, generate .srt and .vtt)
     │
     ▼
[ SYNCING ]          ──► (Upload .srt/.vtt to Cloud Storage; write Firestore doc)
     │
     ▼
[ COMPLETED ]        ──► (All temporary audio files purged; ready for export)
```

- **Resumption**: If an interrupted job is reopened, SQLite state indicates completed chunks; the pipeline resumes at the exact unfinished chunk.
- **Cost Estimation Formula**:
  - Groq Whisper: $\text{Minutes} \times \$0.00185/\text{min}$ (or \$0 on free tier).
  - Deepgram Nova-3: $\text{Minutes} \times \$0.0043/\text{min}$.
  - Gemini 2.5 Flash Translation: $\text{EstimatedTokens} \times (\$0.075 / 1\text{M input tokens})$.

---

## 11. Operating System Background Execution

### 11.1 Android (Doze Mode & Foreground Service)
- Long jobs run inside an Android **Foreground Service** with a persistent ongoing notification:
  *"Generating subtitles: Transcribing chunk 4 of 12 (33%)..."*
- Permissions: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `WAKE_LOCK`.

### 11.2 iOS (Background Tasks & Lifecycle)
- Registers a `BGProcessingTask` with identifier `com.subtitlegenerator.process`.
- The UI shows an informational badge: *"For fastest processing on long videos, keep the app open or connected to power."*
- If iOS suspends the app, `applicationWillResignActive` cleanly pauses the active chunk upload, saves the state to SQLite, and resumes upon reactivation.

---

## 12. Testing & Acceptance Matrix

| Test Case | Scenario | Acceptance Criteria |
|---|---|---|
| **Test 1: Japanese Anime (5m)** | High-speed dialogue, BGM, SFX | Correct particle segmentation (`は`, `が`); no spurious spaces; valid timestamps. |
| **Test 2: Chinese Lecture (30m)** | Technical terminology, mixed English | Correct simplified/traditional characters; Chengyu idioms preserved on single lines. |
| **Test 3: Korean Drama (45m)** | Soft speech, rapid dialogue | Accurate eojeol spacing; correct sentence ending punctuation; no cut phonemes. |
| **Test 4: 3-Hour Feature Movie** | 180 min, multiple scene changes | Audio extracted in <40s; all chunks $\le 20\text{MB}$; zero timestamp drift; SRT output. |
| **Test 5: Cross-Device Firebase Sync**| Generate on phone; open on PC | Subtitle metadata appears in PC library in <2s; on-demand SRT download works cleanly. |
| **Test 6: Offline / Guest Mode** | No Google Sign-In, airplane mode | Full transcription, translation, local SRT export, and SQLite search work 100% offline. |
| **Test 7: Multi-Track Video** | Video with Japanese 5.1 + English dub| Probed correctly; track picker displays; user can select Japanese track explicitly. |
