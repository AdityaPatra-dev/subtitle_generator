# Cross-Platform AI Video Subtitle Generator (Smart Edge-Cloud Hybrid)

A production-grade, cross-platform Flutter application (Android, iOS, Windows, macOS, Linux) that generates broadcast-quality English subtitles (`.srt` / `.vtt`) from long videos in Japanese, Chinese, Korean, and other languages.

## Architecture Documentation & Guides

This repository includes a comprehensive, modular documentation suite designed to eliminate ambiguity and maximize development token efficiency:

1. **[Master Technical Specification](file:///home/adityapatra/Documents/GitHub/subtitle_generator/ChatGPT-Build%20Subtitle%20Generator-20261030-1630.md)**: Full architecture, platform media engine selection, BYOK integrations, state machine, and resilience patterns.
2. **[Database & Data Model Schema (SCHEMA.md)](file:///home/adityapatra/Documents/GitHub/subtitle_generator/SCHEMA.md)**: Exact Drift SQLite table definitions, FTS5 virtual tables, Firestore schemas, and Dart DTOs.
3. **[Implementation Guide (IMPLEMENTATION_GUIDE.md)](file:///home/adityapatra/Documents/GitHub/subtitle_generator/IMPLEMENTATION_GUIDE.md)**: Locked `pubspec.yaml` dependency manifest, VAD silence parsing algorithms, Stage 2 translation prompts with validation interceptors, and deterministic CJK line breaking rules.

## Core Architectural Pillars

- **Smart Edge-Cloud Hybrid**:
  - **Local Device (Edge)**: Performs multi-track audio probing (`ffprobe`/`AVAsset`), speech DSP filtering (high-pass 80Hz, loudness normalization EBU R128, 16kHz mono), and silence-aware VAD chunking with a 20MB hard-cap failsafe.
  - **User Cloud (BYOK)**: Performs heavy Speech-to-Text inference (Groq Whisper Large-v3, Deepgram Nova-3, Google Gemini) and batched LLM translation using the user's personal API credentials.
- **Firebase Cross-Device Subtitle Library**:
  - Optional Google Sign-In (Firebase Auth) with complete Guest/Offline Mode support.
  - Subtitle metadata stored in Firestore; raw `.srt` / `.vtt` text files stored in Firebase Cloud Storage.
  - Optimistic multi-device locking (`processingDeviceId`) and conflict resolution (`updatedAt`).
  - Zero media burden: **Videos and raw audio are strictly kept local and NEVER uploaded to Firebase.**
- **Long Video Support (3+ Hours)**:
  - Resumable chunk processing, SQLite caching, and zero timestamp drift.
  - Android Foreground Service and iOS background task coordination.
- **Language-Aware Subtitle Engine**:
  - Proper CJK tokenization (Japanese particle boundaries, Chinese semantic breath-groups, Korean eojeol spacing).
  - Adheres strictly to Netflix/BBC broadcast subtitle guidelines (max 42 CPL, 2 lines max, 15-17 CPS).
