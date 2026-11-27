# 💾 Local Storage, BYOK Security & Subtitle Formatting

---

## 1. Drift SQLite Persistence (`lib/core/storage/database.dart`)

SubtitleGen AI uses **Drift** (SQLite) with four tables (`schemaVersion = 2`) for full offline durability and resume-from-checkpoint support:

| Table | Purpose | Key Columns |
| :--- | :--- | :--- |
| **`Jobs`** | Tracks each video run & resume state | `id`, `videoFilePath`, `originalFilename`, `fileSizeBytes`, `durationSeconds`, `sourceLanguage`, `targetLanguage`, `provider`, `translationModel`, `status`, `currentChunkIndex`, `totalChunks`, `cachedAudioPath`, `failedStage`, `errorMessage`, `interruptedAt` |
| **`Chunks`** | Per-chunk audio paths & completion state | `id` (`<jobId>_chunk_<idx>`), `jobId`, `chunkIndex`, `startSeconds`, `endSeconds`, `durationSeconds`, `audioFilePath`, `fileSizeBytes`, `status` (`PENDING` / `COMPLETED` / `FAILED`), `completedAt` |
| **`TranscriptSegments`** | Transcribed & translated cues | `id`, `jobId`, `chunkId`, `segmentIndex`, `startSeconds`, `endSeconds`, `sourceText`, `translatedText`, `speakerTag`, `isTranslated` |
| **`Subtitles`** | Completed library entries | `id`, `jobId`, `title`, `cueCount`, `localSrtPath`, `localVttPath`, `isDeleted` (soft delete) |

When a job is deleted (`deleteJobAndData`), all associated `TranscriptSegments`, `Chunks`, and `Jobs` rows are cleaned up atomically.

---

## 2. Audio Cache & BYOK Credential Security

- **Audio Cache (`AudioCacheManager` in [`lib/core/services/audio_cache_manager.dart`](../lib/core/services/audio_cache_manager.dart))**:
  - Stores extracted audio under a per-job temporary working directory during processing, allowing interrupted jobs to resume without re-extracting audio from the video, and cleans up once a job completes.
- **Hardware-Backed Secure Storage (`FlutterSecureStorageService` in [`lib/core/security/flutter_secure_storage_service.dart`](../lib/core/security/flutter_secure_storage_service.dart))**:
  - API keys for Gemini, Groq, and Deepgram are stored using `flutter_secure_storage` (`Android Keystore` / `EncryptedSharedPreferences` on Android, `libsecret` on Linux) and sent **directly** from your device to the chosen provider's HTTPS endpoint.
  - Settings includes a **Purge All Credentials from Keystore** action.

---

## 3. Broadcast Subtitle Formatting (`lib/features/subtitles/`)

### `SubtitleLineBreaker` ([`subtitle_line_breaker.dart`](../lib/features/subtitles/subtitle_line_breaker.dart))
Formats raw segments to **BBC & Netflix Subtitle Guidelines**:
- **Max line length**: `42` characters (Western/Latin) or `18` characters (CJK).
- **Max lines per cue**: `2` lines.
- **Max cue duration**: `6.0` seconds; **max cue length**: `75` chars (Western) / `28` chars (CJK).
- **Balanced 2-line wrapping (`formatCueText`)**: Scores every word/punctuation boundary by distance from the text midpoint, applying a `-12` priority bonus after `,`, `.`, `?`, `!`, `:`, `;` so lines break at natural breath pauses.
- **Long-paragraph splitting (`breakLongSegment`)**: Splits multi-sentence or overly long utterances into multiple timed cues and interpolates timestamps proportionally by character count (`_interpolateCues`).

### `SubtitleSerializer` ([`subtitle_serializer.dart`](../lib/features/subtitles/subtitle_serializer.dart))
- `segmentsToSrt(...)` — Converts `TranscriptSegmentEntry` rows through `SubtitleLineBreaker.breakLongSegment` into UTF-8 `.srt` format (`HH:MM:SS,mmm --> HH:MM:SS,mmm`).
- `toVtt(...)` — Outputs standard `WEBVTT` (`.vtt`) with `HH:MM:SS.mmm` period-separated timecodes.
- `parseSrt(...)` — Parses `.srt` files back into `SubtitleCue` lists for the built-in cue editor.
