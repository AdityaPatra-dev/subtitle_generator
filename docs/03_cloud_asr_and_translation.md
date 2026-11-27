# ☁️ Cloud ASR & Context-Aware Translation

SubtitleGen AI separates **Stage 1 (Speech-to-Text)** and **Stage 2 (Translation)** behind clean provider interfaces so you can mix and match engines based on speed, cost, and noisy-audio accuracy.

---

## 1. Stage 1: Transcription Providers (`lib/features/providers/`)

All providers implement `BaseTranscriptionProvider` (`validateApiKey` and `transcribeChunk`).

### Google Gemini (`GeminiProvider`)
- **File**: [`lib/features/providers/gemini_provider.dart`](../lib/features/providers/gemini_provider.dart)
- **Payload**: Sends base64-encoded `audio/mp3` inline to `v1beta/models/<model>:generateContent` with `temperature: 0.1` and a strict JSON `responseSchema` (`ARRAY` of `{start, end, text}`).
- **Thinking Kept Enabled**: Stage 1 intentionally keeps Gemini's default thinking enabled so the model can reason through loud combat SFX, explosions, and overlapping background music in anime/donghua.
- **Verified Free-Tier Model Cascade**:
  1. `gemini-2.5-flash` (primary — best noisy-audio accuracy)
  2. `gemini-3-flash-preview` (independent serving pool fallback)
  3. `gemini-flash-lite-latest` (ultra-fast fallback)
- **Resilience & Mobile Timeouts**:
  - `Dio` timeouts: `15s` connect, `65s` receive, `60s` send.
  - On `HTTP 503` (Google demand spike), `receiveTimeout`, `sendTimeout`, `404`, `400`, or `500`, it switches **immediately** to the next free-tier model without waiting.
  - On `HTTP 429` (15 RPM free-tier limit), it waits `8s` once to let the rolling quota window recover, retries, and then falls back if needed.
- **Timestamp Clumping Repair (`_repairClumpedTimestamps`)**:
  - Detects LLM timestamp pile-up artifacts (e.g. multiple lines stamped identically at the chunk end) and proportionally redistributes cues across the affected span.

### Groq Whisper Large-v3 (`GroqWhisperProvider`)
- **File**: [`lib/features/providers/groq_whisper_provider.dart`](../lib/features/providers/groq_whisper_provider.dart)
- **Payload**: Multipart upload to `https://api.groq.com/openai/v1/audio/transcriptions` using `whisper-large-v3` with `response_format=verbose_json` and `timestamp_granularities[]=segment`.
- **Anti-Hallucination & Clean Prompting**: Never passes LLM instruction text into Whisper's `prompt` field (which causes Whisper to echo instructions) and filters known silent-hallucination artifacts.

### Deepgram Nova-3 (`DeepgramProvider`)
- **File**: [`lib/features/providers/deepgram_provider.dart`](../lib/features/providers/deepgram_provider.dart)
- **Payload**: Binary audio stream to Deepgram's `nova-3` endpoint with `smart_format=true`, `utterances=true`, and `diarize=true` for speaker-tagged, frame-accurate timestamps.

---

## 2. Stage 2: Batched Translation (`TranslationService`)

Implemented in [`lib/features/translation/translation_service.dart`](../lib/features/translation/translation_service.dart):

### Key Design Choices

1. **70+ Target Languages & Script-Aware Prompts (`buildSystemPrompt`)**:
   - Injects target-language rules into the system prompt, adapting line limits (`18–20` chars for CJK vs `40–42` chars for Latin/other scripts) and RTL punctuation guidance (`isRtl`).
   - Enforces **1:1 segment ID alignment** (`{"translations": [{"id": 1, "translation": "..."}]}`) so timestamps never drift during translation.

2. **Sliding-Window Context**:
   - Passes the last 2 translated lines from the previous batch as `dialogueContext` so pronouns, honorifics, and character names stay coherent across batches.

3. **Free-Tier Speed & Timeout Hardening**:
   - **Gemini**:
     - Batch size capped at **60 segments** (`effectiveBatchSize = 60`) so each JSON response completes in a few seconds.
     - Sets `thinkingConfig: {'thinkingBudget': 0}` for `gemini-2.5-flash` and `gemini-3-flash-preview` (skipped for `gemini-flash-lite-latest`, which rejects `thinkingConfig` with `HTTP 400`).
     - Uses the same free-tier model cascade (`gemini-2.5-flash` → `gemini-3-flash-preview` → `gemini-flash-lite-latest`) with `60s` `receiveTimeout` and immediate `503`/timeout failover.
   - **Groq (`llama-3.3-70b-versatile`)**:
     - Batch size capped at **25 segments** to stay safely inside Groq's free-tier 8,000 TPM limit.

4. **Recursive Half-Batch Splitting & Safe Fallback**:
   - In `_translateBatchWithRetry`, if validation fails or a batch errors after transient retries, it automatically splits the batch in half (`retryCount < 2`) and translates each half sequentially.
   - If retries are exhausted, it preserves the original `sourceText` rather than crashing the entire job and losing earlier work.
