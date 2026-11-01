import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/services/audio_cache_manager.dart';
import '../../core/storage/database.dart';
import '../audio_processing/vad_chunk_calculator.dart';
import '../media/media_engine.dart';
import '../providers/deepgram_provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/groq_whisper_provider.dart';
import '../providers/transcription_provider.dart';
import '../subtitles/subtitle_cue.dart';
import '../subtitles/subtitle_line_breaker.dart';
import '../subtitles/subtitle_serializer.dart';
import '../translation/translation_service.dart';

class PipelineProgress {
  final String jobId;
  final JobStatus status;
  final int currentChunk;
  final int totalChunks;
  final double progressPercent;
  final String statusMessage;
  final Duration? elapsedTime;
  final Duration? estimatedRemainingTime;
  final int? extractedAudioSizeBytes;

  const PipelineProgress({
    required this.jobId,
    required this.status,
    required this.currentChunk,
    required this.totalChunks,
    required this.progressPercent,
    required this.statusMessage,
    this.elapsedTime,
    this.estimatedRemainingTime,
    this.extractedAudioSizeBytes,
  });

  String get elapsedFormatted {
    if (elapsedTime == null) return '00:00';
    final m = elapsedTime!.inMinutes.toString().padLeft(2, '0');
    final s = (elapsedTime!.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get etaFormatted {
    if (estimatedRemainingTime == null || estimatedRemainingTime!.inSeconds <= 0) {
      return 'calculating...';
    }
    final sec = estimatedRemainingTime!.inSeconds;
    if (sec < 60) return '~${sec}s remaining';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '~${m}m ${s}s remaining';
  }

  String get audioSizeFormatted {
    if (extractedAudioSizeBytes == null || extractedAudioSizeBytes! <= 0) return '';
    final mb = extractedAudioSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB (MP3)';
  }
}

class PipelineCoordinator {
  final AppDatabase db;
  final MediaEngine mediaEngine;
  final SecureStorageService secureStorage;
  final TranslationService translationService;
  final AudioCacheManager audioCacheManager;

  final GroqWhisperProvider groqProvider = GroqWhisperProvider();
  final GeminiProvider geminiProvider = GeminiProvider();
  final DeepgramNovaProvider deepgramProvider = DeepgramNovaProvider();

  PipelineCoordinator({
    required this.db,
    required this.mediaEngine,
    required this.secureStorage,
    required this.translationService,
    AudioCacheManager? audioCacheManager,
  }) : audioCacheManager = audioCacheManager ?? AudioCacheManager();

  /// Starts processing a video file with resilient checkpointing & audio caching
  Stream<PipelineProgress> processVideo({
    required String videoPath,
    String? originalFilename,
    required int audioStreamIndex,
    required SourceLanguage sourceLang,
    required TranscriptionProviderType providerType,
    required TranslationModelType translationModel,
    required String tempWorkDir,
    required String outputDir,
    bool exportVtt = true,
    String? resumeJobId,
  }) async* {
    final stopwatch = Stopwatch()..start();
    final videoFile = File(videoPath);
    final filename = (originalFilename != null && originalFilename.trim().isNotEmpty)
        ? originalFilename.trim()
        : p.basename(videoPath);
    final fileSizeBytes = await videoFile.length();
    final now = DateTime.now().millisecondsSinceEpoch;

    Duration? computeEta(double progress) {
      if (progress <= 0.08) return null;
      final elapsed = stopwatch.elapsed;
      final totalEst = elapsed.inMilliseconds * (1.0 / progress);
      final remainingMs = (totalEst - elapsed.inMilliseconds).round();
      if (remainingMs <= 0) return Duration.zero;
      return Duration(milliseconds: remainingMs);
    }

    // Retrieve BYOK API Key
    String? apiKey;
    switch (providerType) {
      case TranscriptionProviderType.groqWhisperLargeV3:
        apiKey = await secureStorage.getGroqKey();
        break;
      case TranscriptionProviderType.gemini25Transcribe:
        apiKey = await secureStorage.getGeminiKey();
        break;
      case TranscriptionProviderType.deepgramNova3:
        apiKey = await secureStorage.getDeepgramKey();
        break;
    }

    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Missing API key for provider ${providerType.displayName}. Please add it in Settings.');
    }

    // Retrieve Translation API Key (if translating)
    String? translationApiKey;
    if (translationModel == TranslationModelType.gemini25Flash) {
      translationApiKey = await secureStorage.getGeminiKey();
    } else if (translationModel == TranslationModelType.groqLlama3370b) {
      translationApiKey = await secureStorage.getGroqKey();
    }

    // 1. Initial State: Determine or Resume Job
    String jobId = resumeJobId ?? '';
    JobEntry? existingJob;

    if (jobId.isNotEmpty) {
      existingJob = await db.getJob(jobId);
    } else {
      existingJob = await db.findIncompleteJobForFile(filename, fileSizeBytes);
      if (existingJob != null) {
        jobId = existingJob.id;
      }
    }

    if (jobId.isEmpty) {
      jobId = const Uuid().v4();
      await db.insertJob(JobsCompanion.insert(
        id: jobId,
        videoFilePath: videoPath,
        originalFilename: filename,
        fileSizeBytes: BigInt.from(fileSizeBytes),
        durationSeconds: const Value(0.0),
        audioStreamIndex: Value(audioStreamIndex),
        sourceLanguage: sourceLang.bcp47,
        targetLanguage: const Value('en'),
        provider: providerType.name,
        translationModel: translationModel.name,
        status: JobStatus.pending.name,
        createdAt: BigInt.from(now),
        updatedAt: BigInt.from(now),
      ));
    } else {
      await db.updateJob(JobsCompanion(
        id: Value(jobId),
        status: Value(JobStatus.pending.name),
        provider: Value(providerType.name),
        translationModel: Value(translationModel.name),
        sourceLanguage: Value(sourceLang.bcp47),
        updatedAt: Value(BigInt.from(now)),
      ));
    }

    yield PipelineProgress(
      jobId: jobId,
      status: JobStatus.pending,
      currentChunk: 0,
      totalChunks: 0,
      progressPercent: 0.05,
      statusMessage: 'Probing media tracks & audio cache...',
      elapsedTime: stopwatch.elapsed,
      estimatedRemainingTime: null,
    );

    // 2. EXTRACTING AUDIO OR REUSING CACHED AUDIO
    await _updateJobStatus(jobId, JobStatus.extractingAudio);

    final cacheKey = audioCacheManager.generateCacheKey(
      filename: filename,
      fileSizeBytes: fileSizeBytes,
      audioStreamIndex: audioStreamIndex,
    );
    final targetCachedAudioPath = await audioCacheManager.getTargetFilePath(cacheKey);
    final validCachedAudio = await audioCacheManager.getValidCachedAudio(cacheKey);

    String fullAudioPath;
    int extractedAudioBytes;
    double videoDurationSeconds = existingJob?.durationSeconds ?? 0.0;

    if (validCachedAudio != null) {
      fullAudioPath = validCachedAudio.path;
      extractedAudioBytes = await validCachedAudio.length();

      await db.updateJob(JobsCompanion(
        id: Value(jobId),
        cachedAudioPath: Value(fullAudioPath),
        updatedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
      ));

      yield PipelineProgress(
        jobId: jobId,
        status: JobStatus.extractingAudio,
        currentChunk: 0,
        totalChunks: 0,
        progressPercent: 0.18,
        statusMessage: 'Reusing cached audio (${(extractedAudioBytes / (1024 * 1024)).toStringAsFixed(1)} MB) — 0s extraction!',
        elapsedTime: stopwatch.elapsed,
        estimatedRemainingTime: computeEta(0.18),
        extractedAudioSizeBytes: extractedAudioBytes,
      );
    } else {
      yield PipelineProgress(
        jobId: jobId,
        status: JobStatus.extractingAudio,
        currentChunk: 0,
        totalChunks: 0,
        progressPercent: 0.12,
        statusMessage: 'Extracting clean audio track (16kHz mono, MP3)...',
        elapsedTime: stopwatch.elapsed,
        estimatedRemainingTime: computeEta(0.12),
      );

      final extractionResult = await mediaEngine.extractAudio(
        inputPath: videoPath,
        outputPath: targetCachedAudioPath,
        audioStreamIndex: audioStreamIndex,
        config: const AudioExtractionConfig(),
      );

      fullAudioPath = targetCachedAudioPath;
      extractedAudioBytes = extractionResult.fileSizeBytes;
      videoDurationSeconds = extractionResult.durationSeconds;

      await db.updateJob(JobsCompanion(
        id: Value(jobId),
        cachedAudioPath: Value(targetCachedAudioPath),
        durationSeconds: Value(videoDurationSeconds),
        updatedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
      ));

      yield PipelineProgress(
        jobId: jobId,
        status: JobStatus.extractingAudio,
        currentChunk: 0,
        totalChunks: 0,
        progressPercent: 0.18,
        statusMessage: 'Audio extracted (${(extractedAudioBytes / (1024 * 1024)).toStringAsFixed(1)} MB). Analyzing speech...',
        elapsedTime: stopwatch.elapsed,
        estimatedRemainingTime: computeEta(0.18),
        extractedAudioSizeBytes: extractedAudioBytes,
      );
    }

    // 3. CHUNKING with Silence-Aware VAD (or reuse existing chunks)
    final jobTempDir = Directory(p.join(tempWorkDir, jobId));
    await jobTempDir.create(recursive: true);

    await _updateJobStatus(jobId, JobStatus.chunking);

    final existingChunkRecords = await db.getChunksForJob(jobId);
    List<String> chunkPaths = [];
    int totalChunks = 0;

    if (existingChunkRecords.isNotEmpty) {
      bool allFilesPresent = true;
      for (final c in existingChunkRecords) {
        if (c.status != 'COMPLETED' && !await File(c.audioFilePath).exists()) {
          allFilesPresent = false;
          break;
        }
      }

      if (allFilesPresent) {
        chunkPaths = existingChunkRecords.map((c) => c.audioFilePath).toList();
        totalChunks = existingChunkRecords.length;
        yield PipelineProgress(
          jobId: jobId,
          status: JobStatus.chunking,
          currentChunk: 0,
          totalChunks: totalChunks,
          progressPercent: 0.25,
          statusMessage: 'Reusing $totalChunks existing chunks — VAD chunking skipped!',
          elapsedTime: stopwatch.elapsed,
          estimatedRemainingTime: computeEta(0.25),
          extractedAudioSizeBytes: extractedAudioBytes,
        );
      }
    }

    if (chunkPaths.isEmpty) {
      yield PipelineProgress(
        jobId: jobId,
        status: JobStatus.chunking,
        currentChunk: 0,
        totalChunks: 0,
        progressPercent: 0.22,
        statusMessage: 'Detecting speech silence intervals...',
        elapsedTime: stopwatch.elapsed,
        estimatedRemainingTime: computeEta(0.22),
        extractedAudioSizeBytes: extractedAudioBytes,
      );

      final silenceStderr = await mediaEngine.detectSilence(audioPath: fullAudioPath);
      final silenceIntervals = VadChunkCalculator.parseSilenceOutput(silenceStderr);
      final splitPoints = VadChunkCalculator.calculateSplitPoints(
        totalDurationSeconds: videoDurationSeconds > 0 ? videoDurationSeconds : 120.0,
        silenceIntervals: silenceIntervals,
      );

      chunkPaths = await mediaEngine.splitAudioAtTimestamps(
        inputPath: fullAudioPath,
        splitPointsSeconds: splitPoints,
        outputDir: jobTempDir.path,
        prefix: jobId,
      );

      totalChunks = chunkPaths.length;
      await db.updateJob(JobsCompanion(
        id: Value(jobId),
        totalChunks: Value(totalChunks),
        updatedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
      ));

      double currentOffset = 0.0;
      for (int i = 0; i < totalChunks; i++) {
        final chunkFile = File(chunkPaths[i]);
        final size = await chunkFile.length();
        final endOffset = (i < splitPoints.length) ? splitPoints[i] : (videoDurationSeconds > 0 ? videoDurationSeconds : (currentOffset + 120.0));
        final chunkDur = endOffset - currentOffset;

        await db.insertChunk(ChunksCompanion.insert(
          id: '${jobId}_chunk_$i',
          jobId: jobId,
          chunkIndex: i,
          startSeconds: currentOffset,
          endSeconds: endOffset,
          durationSeconds: chunkDur,
          audioFilePath: chunkPaths[i],
          fileSizeBytes: BigInt.from(size),
          status: 'PENDING',
          createdAt: BigInt.from(DateTime.now().millisecondsSinceEpoch),
        ));

        currentOffset = endOffset;
      }
    }

    // 4. TRANSCRIBING Chunks Sequentially with Immediate Segment Persistence
    await _updateJobStatus(jobId, JobStatus.transcribing);

    const double transcriptionStartProgress = 0.28;
    const double transcriptionEndProgress = 0.82;
    const double transcriptionSpan = transcriptionEndProgress - transcriptionStartProgress;

    final existingSegments = await db.getSegmentsForJob(jobId);
    int globalSegmentIndex = existingSegments.length;

    for (int i = 0; i < totalChunks; i++) {
      final chunkId = '${jobId}_chunk_$i';
      final chunkPath = chunkPaths[i];
      final currentChunkProgress = transcriptionStartProgress + (transcriptionSpan * (i / totalChunks));

      final allChunks = await db.getChunksForJob(jobId);
      final chunkRecord = allChunks.firstWhere((c) => c.id == chunkId);

      // Checkpoint: skip already completed chunk!
      if (chunkRecord.status == 'COMPLETED') {
        yield PipelineProgress(
          jobId: jobId,
          status: JobStatus.transcribing,
          currentChunk: i + 1,
          totalChunks: totalChunks,
          progressPercent: currentChunkProgress,
          statusMessage: 'Chunk ${i + 1}/$totalChunks already completed (cached) — skipping...',
          elapsedTime: stopwatch.elapsed,
          estimatedRemainingTime: computeEta(currentChunkProgress),
          extractedAudioSizeBytes: extractedAudioBytes,
        );
        continue;
      }

      yield PipelineProgress(
        jobId: jobId,
        status: JobStatus.transcribing,
        currentChunk: i + 1,
        totalChunks: totalChunks,
        progressPercent: currentChunkProgress,
        statusMessage: 'Transcribing chunk ${i + 1} of $totalChunks with ${providerType.displayName}...',
        elapsedTime: stopwatch.elapsed,
        estimatedRemainingTime: computeEta(currentChunkProgress),
        extractedAudioSizeBytes: extractedAudioBytes,
      );

      final offset = chunkRecord.startSeconds;
      TranscriptionResult result;

      try {
        switch (providerType) {
          case TranscriptionProviderType.groqWhisperLargeV3:
            result = await groqProvider.transcribeChunk(
              audioChunkPath: chunkPath,
              apiKey: apiKey,
              sourceLanguage: sourceLang.bcp47,
            );
            break;
          case TranscriptionProviderType.gemini25Transcribe:
            result = await geminiProvider.transcribeChunk(
              audioChunkPath: chunkPath,
              apiKey: apiKey,
              sourceLanguage: sourceLang.bcp47,
            );
            break;
          case TranscriptionProviderType.deepgramNova3:
            result = await deepgramProvider.transcribeChunk(
              audioChunkPath: chunkPath,
              apiKey: apiKey,
              sourceLanguage: sourceLang.bcp47,
            );
            break;
        }

        // Insert segments into SQLite IMMEDIATELY per chunk!
        final chunkSegments = <TranscriptSegmentsCompanion>[];
        for (final seg in result.segments) {
          final adjusted = seg.copyWithOffset(offset, globalSegmentIndex++);
          chunkSegments.add(TranscriptSegmentsCompanion.insert(
            jobId: jobId,
            chunkId: chunkId,
            segmentIndex: adjusted.index,
            startSeconds: adjusted.startSeconds,
            endSeconds: adjusted.endSeconds,
            sourceText: adjusted.text,
            speakerTag: Value(adjusted.speakerTag),
          ));
        }

        if (chunkSegments.isNotEmpty) {
          await db.insertSegments(chunkSegments);
        }

        await db.updateChunk(ChunksCompanion(
          id: Value(chunkId),
          status: const Value('COMPLETED'),
          completedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
        ));

        // Clean up individual chunk audio file immediately after transcribing
        try {
          final chunkFile = File(chunkPath);
          if (await chunkFile.exists()) {
            await chunkFile.delete();
          }
        } catch (_) {}

        final afterChunkProgress = transcriptionStartProgress + (transcriptionSpan * ((i + 1) / totalChunks));
        yield PipelineProgress(
          jobId: jobId,
          status: JobStatus.transcribing,
          currentChunk: i + 1,
          totalChunks: totalChunks,
          progressPercent: afterChunkProgress,
          statusMessage: 'Processed chunk ${i + 1} of $totalChunks (${result.segments.length} cues detected)',
          elapsedTime: stopwatch.elapsed,
          estimatedRemainingTime: computeEta(afterChunkProgress),
          extractedAudioSizeBytes: extractedAudioBytes,
        );
      } catch (err) {
        final failTime = DateTime.now().millisecondsSinceEpoch;
        await db.updateChunk(ChunksCompanion(
          id: Value(chunkId),
          status: const Value('FAILED'),
          errorMessage: Value(err.toString()),
        ));
        await db.updateJob(JobsCompanion(
          id: Value(jobId),
          status: Value(JobStatus.failed.name),
          failedStage: const Value('transcribing'),
          currentChunkIndex: Value(i),
          errorMessage: Value('Chunk ${i + 1}/$totalChunks failed: $err'),
          interruptedAt: Value(BigInt.from(failTime)),
          updatedAt: Value(BigInt.from(failTime)),
        ));
        rethrow;
      }
    }

    // 5. TRANSLATING (Stage 2)
    final allJobSegments = await db.getSegmentsForJob(jobId);

    if (translationModel != TranslationModelType.none && translationApiKey != null) {
      await _updateJobStatus(jobId, JobStatus.translating);
      yield PipelineProgress(
        jobId: jobId,
        status: JobStatus.translating,
        currentChunk: totalChunks,
        totalChunks: totalChunks,
        progressPercent: 0.85,
        statusMessage: 'Translating subtitles to English with ${translationModel.displayName}...',
        elapsedTime: stopwatch.elapsed,
        estimatedRemainingTime: computeEta(0.85),
        extractedAudioSizeBytes: extractedAudioBytes,
      );

      final unTranslated = allJobSegments.where((s) => !s.isTranslated).toList();

      if (unTranslated.isNotEmpty) {
        final inputs = unTranslated
            .map((s) => TranslationSegmentInput(id: s.id, source: s.sourceText))
            .toList();

        try {
          final outputs = await translationService.translateSegments(
            segments: inputs,
            modelType: translationModel,
            apiKey: translationApiKey,
          );

          for (final out in outputs) {
            await db.updateSegmentTranslation(out.id, out.translation);
          }
        } catch (err) {
          final failTime = DateTime.now().millisecondsSinceEpoch;
          await db.updateJob(JobsCompanion(
            id: Value(jobId),
            status: Value(JobStatus.failed.name),
            failedStage: const Value('translating'),
            errorMessage: Value('Translation failed: $err'),
            interruptedAt: Value(BigInt.from(failTime)),
            updatedAt: Value(BigInt.from(failTime)),
          ));
          rethrow;
        }
      }
    }

    // 6. FORMATTING Subtitles (SRT & VTT) with smart paragraph breaker
    await _updateJobStatus(jobId, JobStatus.formatting);
    yield PipelineProgress(
      jobId: jobId,
      status: JobStatus.formatting,
      currentChunk: totalChunks,
      totalChunks: totalChunks,
      progressPercent: 0.92,
      statusMessage: 'Balancing cues & formatting SRT/VTT lines...',
      elapsedTime: stopwatch.elapsed,
      estimatedRemainingTime: computeEta(0.92),
      extractedAudioSizeBytes: extractedAudioBytes,
    );

    final finalSegments = await db.getSegmentsForJob(jobId);
    final List<SubtitleCue> cues = [];
    int cueIndex = 1;

    for (final seg in finalSegments) {
      final rawText = seg.translatedText?.isNotEmpty == true ? seg.translatedText! : seg.sourceText;
      final subCues = SubtitleLineBreaker.breakLongSegment(
        startSeconds: seg.startSeconds,
        endSeconds: seg.endSeconds,
        text: rawText,
        startingIndex: cueIndex,
      );
      cues.addAll(subCues);
      cueIndex += subCues.length;
    }

    final srtContent = SubtitleSerializer.toSrt(cues);
    final baseTitle = p.basenameWithoutExtension(filename);
    final srtFile = File(p.join(outputDir, '$baseTitle.srt'));
    await srtFile.writeAsString(srtContent);

    String? vttPath;
    if (exportVtt) {
      final vttContent = SubtitleSerializer.toVtt(cues, title: baseTitle);
      final vttFile = File(p.join(outputDir, '$baseTitle.vtt'));
      await vttFile.writeAsString(vttContent);
      vttPath = vttFile.path;
    }

    // 7. Insert Subtitle record into local SQLite
    final subtitleId = const Uuid().v4();
    final srtSizeBytes = await srtFile.length();

    await db.insertSubtitle(SubtitlesCompanion.insert(
      id: subtitleId,
      jobId: Value(jobId),
      title: baseTitle,
      originalFilename: filename,
      sourceLanguage: sourceLang.bcp47,
      durationSeconds: videoDurationSeconds,
      providerUsed: providerType.displayName,
      translationModel: Value(translationModel.displayName),
      cueCount: cues.length,
      fileSizeBytes: BigInt.from(srtSizeBytes),
      localSrtPath: srtFile.path,
      localVttPath: Value(vttPath),
      createdAt: BigInt.from(now),
      updatedAt: BigInt.from(DateTime.now().millisecondsSinceEpoch),
    ));

    // 8. Mark Job as COMPLETED
    await _updateJobStatus(jobId, JobStatus.completed);

    // 9. CLEAN UP INTERMEDIATE AUDIO & CHUNKS ON SUCCESS
    await audioCacheManager.deleteCachedAudio(fullAudioPath);
    try {
      if (await jobTempDir.exists()) {
        await jobTempDir.delete(recursive: true);
      }
    } catch (_) {}

    yield PipelineProgress(
      jobId: jobId,
      status: JobStatus.completed,
      currentChunk: totalChunks,
      totalChunks: totalChunks,
      progressPercent: 1.0,
      statusMessage: 'Completed in ${stopwatch.elapsed.inSeconds}s! Subtitles saved to ${srtFile.path}',
      elapsedTime: stopwatch.elapsed,
      estimatedRemainingTime: Duration.zero,
      extractedAudioSizeBytes: extractedAudioBytes,
    );
  }

  Future<void> _updateJobStatus(String jobId, JobStatus status) async {
    await db.updateJob(JobsCompanion(
      id: Value(jobId),
      status: Value(status.name),
      updatedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
    ));
  }
}
