# 🏗️ Architecture & End-to-End Pipeline

SubtitleGen AI uses an **Edge-Cloud Hybrid** architecture: all heavy media probing, audio extraction, filtering, silence detection (VAD), chunk splitting, checkpointing, and subtitle formatting happen **locally on-device**, while only compact 16 kHz mono MP3 chunks and JSON dialogue arrays are sent to your chosen **BYOK** cloud AI provider.

---

## 1. Navigation & App Shell (`lib/main.dart`)

The Flutter UI is hosted inside `MainNavigationShell` using an `IndexedStack` across four persistent tabs so background pipeline streams stay alive even when switching tabs:

1. **Generate (`HomeScreen`)** — Media picker, audio track selector, spoken & output language pickers, speech profile, processing strategy, provider selection, and live pipeline progress card.
2. **Library (`LibraryScreen`)** — Searchable local library of completed `.srt` / `.vtt` subtitles backed by Drift SQLite.
3. **Runs (`RunsScreen`)** — Tracks incomplete/interrupted jobs (`status` not in `['completed', 'cancelled']`), shows chunk completion progress, exports partial `.srt` files, or resumes jobs from their last checkpoint.
4. **Settings (`SettingsScreen`)** — Hardware-backed BYOK API key management (Gemini, Groq, Deepgram) with live key validation, theme toggle, and GitHub Release update checker (`UpdateCheckerService`).

---

## 2. Pipeline Orchestration (`PipelineCoordinator`)

The entire subtitle generation lifecycle is orchestrated by `PipelineCoordinator.processVideo(...)` in [`lib/features/transcription/pipeline_coordinator.dart`](../lib/features/transcription/pipeline_coordinator.dart), which yields a `Stream<PipelineProgress>` with real-time stage updates, percentages, elapsed time, and ETA.

```
[1. Probe] ──▶ [2. Extract Audio] ──▶ [3. VAD & Split] ──▶ [4. Parallel ASR] ──▶ [5. Translate] ──▶ [6. Format & Save]
```

### Stage-by-Stage Execution

1. **Media Probing (`0% – 3%`)**:
   - Calls `MediaEngine.probe(videoPath)` (`ffprobe`) to read exact duration, file size, and available audio streams (`AudioTrackInfo`).
   - Looks up or creates a `Jobs` row in Drift SQLite (`JobStatus.pending`).

2. **Audio Extraction (`5% – 15%`)**:
   - Extracts the selected audio stream (`0:<audioStreamIndex>`) into a 16 kHz mono MP3 using the active `SpeechProfile` filters.
   - **Checkpoint optimization**: On resume (`resumeJobId`), if `cachedAudioPath` still exists on disk, extraction is skipped completely.

3. **VAD Silence Detection & Chunking (`15% – 20%`)**:
   - Runs FFmpeg `silencedetect` on the extracted MP3 using the profile's `noiseDb` and `minSilenceDurationSeconds`.
   - `VadChunkCalculator` computes optimal split timestamps around natural speech pauses based on the provider and `ProcessingStrategy`.
   - Splits the MP3 into chunk files and records each chunk (`PENDING`) in the `Chunks` table.
   - On resume, existing `Chunks` rows are loaded directly from SQLite.

4. **Parallel Cloud ASR (`20% – 85%`)**:
   - Filters for `PENDING` or `FAILED` chunks (skipping `COMPLETED` chunks on resume).
   - Spawns `concurrency` async workers (`2` workers in `Parallel Chunking`, `1` in `Sequential` / `Large Chunk`).
   - Each worker picks the next pending chunk, retries transient network errors up to `4` times (`attempt * 2s` backoff), and clamps returned timestamps strictly within `[0.0, chunkDuration + 0.5s]` before adding the chunk's `startSeconds` offset.
   - Segments are persisted immediately to `TranscriptSegments`, the chunk is marked `COMPLETED`, `jobs.currentChunkIndex` is updated in SQLite, and the temporary chunk `.mp3` is deleted.

5. **Batched Translation (`85% – 95%`)**:
   - **Zero-Token Bypass**: If `sourceLang` matches `targetLang` (same base BCP-47 tag), translation is skipped completely.
   - Otherwise, waits a brief `2s` cooldown (to let free-tier RPM windows clear after parallel ASR) and translates only segments where `isTranslated == false` via `TranslationService`.
   - Saves each translated line into `TranscriptSegments.translatedText`.

6. **Subtitle Formatting & Export (`95% – 100%`)**:
   - Runs `SubtitleSerializer.segmentsToSrt(...)` (using `SubtitleLineBreaker` for BBC/Netflix compliance) and `SubtitleSerializer.toVtt(...)`.
   - Writes `<title>.srt` and `<title>.vtt` to the output directory (`/storage/emulated/0/Download` on Android).
   - Inserts a `Subtitles` library record, marks the job `completed`, and cleans up cached audio.
