# Cross-Platform AI Video Subtitle Generator (Smart Edge-Cloud Hybrid)

A cross-platform Flutter application (Android, iOS, Windows, macOS, Linux) that generates professional, broadcast-quality English subtitles (`.srt` / `.vtt`) from long videos in Japanese, Chinese, Korean, and other languages.

## Key Architecture Highlights

- **Smart Edge-Cloud Hybrid**:
  - **Local Device (Edge)**: Performs audio extraction (demuxing), speech filtering (high-pass, loudness normalization, voice bandpass), and silence-aware VAD chunking. No gigabyte video uploads, no battery drain.
  - **User Cloud (BYOK)**: Performs heavy Speech-to-Text inference (Groq Whisper Large-v3, Deepgram Nova-3, Google Gemini) and LLM translation using the user's personal API credentials.
- **Firebase Cross-Device Subtitle Library**:
  - User signs in with Google (Firebase Auth).
  - Every generated `.srt` / `.vtt` file is automatically synced to the developer's Firebase under `users/{userId}/subtitles/`.
  - Because SRT files are tiny text documents (2–150 KB), users can log into any device (phone, laptop, desktop) and instantly browse, preview, edit, or download all their generated subtitles with practically zero storage/cost burden for the developer.
  - **Videos and raw audio are strictly kept local and NEVER uploaded to Firebase.**
- **Long Video Support**: Gracefully handles 3+ hour videos with resumable chunk processing, SQLite caching, and zero timestamp drift.
- **Language-Aware Subtitle Engine**: Proper CJK tokenization (Japanese, Chinese, Korean) avoiding awkward line wraps and false spaces, adhering strictly to Netflix/BBC broadcast subtitle guidelines.

For the full detailed engineering specification, see [ChatGPT-Build Subtitle Generator-20261030-1630.md](file:///home/adityapatra/Documents/GitHub/subtitle_generator/ChatGPT-Build%20Subtitle%20Generator-20261030-1630.md).
