# Database & Data Model Specifications (Drift SQLite & Firestore)

This document defines the exact database schema, tables, foreign keys, enums, and data transfer objects (DTOs) for the Subtitle Generator application. Both the local SQLite database (`drift`) and remote Firestore collections must adhere strictly to these models.

---

## 1. Enums & Constant Types

```dart
enum JobStatus {
  pending,
  extractingAudio,
  chunking,
  transcribing,
  translating,
  formatting,
  syncing,
  completed,
  failed,
  cancelled,
}

enum TranscriptionProviderType {
  groqWhisperLargeV3,
  gemini25Transcribe,
  deepgramNova3,
}

enum TranslationModelType {
  gemini25Flash,
  groqLlama3370b,
  none, // If audio was already in English
}

enum SourceLanguage {
  ja('Japanese', 'ja'),
  zhHans('Chinese (Simplified)', 'zh-Hans'),
  zhHant('Chinese (Traditional)', 'zh-Hant'),
  ko('Korean', 'ko'),
  auto('Auto Detect', '');

  final String displayName;
  final String bcp47;
  const SourceLanguage(this.displayName, this.bcp47);
}
```

---

## 2. Local Database Schema (Drift / SQLite)

### 2.1 Table: `jobs`
Tracks overall processing jobs on the local device.

```sql
CREATE TABLE jobs (
  id TEXT PRIMARY KEY NOT NULL,                -- UUID v4
  video_file_path TEXT NOT NULL,               -- Absolute path to source video
  original_filename TEXT NOT NULL,             -- e.g. "Tokyo_Walk.mp4"
  file_size_bytes INTEGER NOT NULL,            -- Video size in bytes
  duration_seconds REAL NOT NULL DEFAULT 0.0,  -- Total video/audio duration
  audio_stream_index INTEGER NOT NULL DEFAULT 0, -- Selected audio stream from ffprobe
  
  source_language TEXT NOT NULL,               -- e.g. "ja", "ko", "zh-Hans"
  target_language TEXT NOT NULL DEFAULT 'en',  -- Target output language
  
  provider TEXT NOT NULL,                      -- e.g. "groqWhisperLargeV3"
  translation_model TEXT NOT NULL,             -- e.g. "gemini25Flash"
  
  status TEXT NOT NULL,                        -- Enum JobStatus as string
  current_chunk_index INTEGER NOT NULL DEFAULT 0,
  total_chunks INTEGER NOT NULL DEFAULT 0,
  
  error_message TEXT,                          -- Populated on failure
  created_at INTEGER NOT NULL,                 -- Unix timestamp (milliseconds)
  updated_at INTEGER NOT NULL                  -- Unix timestamp (milliseconds)
);

CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_at ON jobs(created_at);
```

### 2.2 Table: `chunks`
Maintains individual chunk state for resilient, resumable chunk-level execution.

```sql
CREATE TABLE chunks (
  id TEXT PRIMARY KEY NOT NULL,                -- "${job_id}_chunk_${chunk_index}"
  job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  chunk_index INTEGER NOT NULL,
  
  start_seconds REAL NOT NULL,                 -- Global offset in seconds (e.g. 720.0)
  end_seconds REAL NOT NULL,                   -- Global end in seconds (e.g. 1440.0)
  duration_seconds REAL NOT NULL,
  
  audio_file_path TEXT NOT NULL,               -- Path to temporary chunk MP3
  file_size_bytes INTEGER NOT NULL,
  
  status TEXT NOT NULL,                        -- "PENDING", "UPLOADING", "COMPLETED", "FAILED"
  attempts INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  
  created_at INTEGER NOT NULL,
  completed_at INTEGER
);

CREATE INDEX idx_chunks_job ON chunks(job_id, chunk_index);
```

### 2.3 Table: `transcript_segments`
Stores ground-truth Stage 1 transcription cues and Stage 2 translations.

```sql
CREATE TABLE transcript_segments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  chunk_id TEXT NOT NULL REFERENCES chunks(id) ON DELETE CASCADE,
  
  segment_index INTEGER NOT NULL,              -- Order within the job
  start_seconds REAL NOT NULL,                 -- Ground-truth start time (global)
  end_seconds REAL NOT NULL,                   -- Ground-truth end time (global)
  
  source_text TEXT NOT NULL,                   -- Original spoken text (Japanese, etc.)
  translated_text TEXT,                        -- Stage 2 English translation
  speaker_tag TEXT,                            -- Diarization speaker label (e.g. "spk_0")
  
  is_translated INTEGER NOT NULL DEFAULT 0     -- 0 = False, 1 = True
);

CREATE INDEX idx_segments_job ON transcript_segments(job_id, segment_index);
```

### 2.4 Table: `subtitles`
Local cache of exported subtitles, mirroring Cloud Storage and Firestore metadata.

```sql
CREATE TABLE subtitles (
  id TEXT PRIMARY KEY NOT NULL,                -- UUID v4
  job_id TEXT REFERENCES jobs(id) ON DELETE SET NULL,
  user_id TEXT,                                -- Firebase Auth UID (if signed in)
  
  title TEXT NOT NULL,
  original_filename TEXT NOT NULL,
  source_language TEXT NOT NULL,
  target_language TEXT NOT NULL DEFAULT 'en',
  duration_seconds REAL NOT NULL,
  
  provider_used TEXT NOT NULL,
  translation_model TEXT,
  cue_count INTEGER NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  
  local_srt_path TEXT NOT NULL,                -- Local disk path
  local_vtt_path TEXT,                         -- Local disk path (optional)
  storage_path TEXT,                           -- Firebase Storage path: "users/{uid}/subtitles/{id}.srt"
  storage_path_vtt TEXT,                       -- Firebase Storage path: "users/{uid}/subtitles/{id}.vtt"
  
  is_dirty INTEGER NOT NULL DEFAULT 0,         -- 1 = Local edits not yet synced to cloud
  is_deleted INTEGER NOT NULL DEFAULT 0,       -- 1 = Soft-deleted
  cloud_synced_at INTEGER,                     -- Timestamp of last successful cloud sync
  
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_subtitles_user ON subtitles(user_id);
CREATE INDEX idx_subtitles_created ON subtitles(created_at);
```

### 2.5 Table: `subtitle_cues_fts` (SQLite FTS5 Full-Text Search)
Enables instant (<10ms) full-text search across all downloaded subtitles without network requests.

```sql
CREATE VIRTUAL TABLE subtitle_cues_fts USING fts5(
  subtitle_id UNINDEXED,
  cue_index UNINDEXED,
  start_timestamp UNINDEXED,
  end_timestamp UNINDEXED,
  content
);
```

### 2.6 Table: `sync_queue`
Manages offline sync operations for reliable background synchronization.

```sql
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  subtitle_id TEXT NOT NULL REFERENCES subtitles(id) ON DELETE CASCADE,
  operation TEXT NOT NULL,                     -- "CREATE", "UPDATE", "DELETE"
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  enqueued_at INTEGER NOT NULL
);
```

---

## 3. Remote Database Schema (Firebase Firestore)

### Collection: `/users/{userId}/subtitles/{subtitleId}`

```typescript
interface FirestoreSubtitleDocument {
  id: string;                    // UUID v4 (matches subtitleId and storage filename stem)
  userId: string;                // Firebase Auth UID
  title: string;                 // User-editable display name
  originalFilename: string;      // Immutable original filename
  sourceLanguage: string;        // e.g. "ja", "ko", "zh-Hans"
  targetLanguage: string;        // "en"
  durationSeconds: number;       // e.g. 5420.5
  providerUsed: string;          // "groq_whisper_large_v3" | "gemini_2_5_transcribe" | "deepgram_nova_3"
  translationModel: string | null;// "gemini_2_5_flash" | "groq_llama_3_3_70b" | null
  cueCount: number;              // Total subtitle cues
  fileSizeBytes: number;         // Size of .srt file in bytes
  storagePath: string;           // "users/{userId}/subtitles/{subtitleId}.srt"
  storagePathVtt: string | null; // "users/{userId}/subtitles/{subtitleId}.vtt"
  jobStatus: string;             // "COMPLETED"
  processingDeviceId: string | null; // Lock field for active processing
  isDirty: boolean;              // false in cloud
  isDeleted: boolean;            // soft-delete flag
  schemaVersion: number;         // 1
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}
```

---

## 4. Dart Data Transfer Objects (DTOs)

```dart
class SubtitleCue {
  final int index;
  final double startSeconds;
  final double endSeconds;
  final String text;

  const SubtitleCue({
    required this.index,
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
  });

  String get srtTimecode {
    return '${_formatTime(startSeconds, ',')} --> ${_formatTime(endSeconds, ',')}';
  }

  String get vttTimecode {
    return '${_formatTime(startSeconds, '.')} --> ${_formatTime(endSeconds, '.')}';
  }

  static String _formatTime(double seconds, String decimalSeparator) {
    final int hrs = seconds ~/ 3600;
    final int mins = (seconds % 3600) ~/ 60;
    final int secs = seconds.toInt() % 60;
    final int ms = ((seconds - seconds.toInt()) * 1000).toInt();
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}$decimalSeparator${ms.toString().padLeft(3, '0')}';
  }
}
```

