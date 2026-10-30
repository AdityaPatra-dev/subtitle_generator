import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/security/secure_storage_service.dart';
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

  const PipelineProgress({
    required this.jobId,
    required this.status,
    required this.currentChunk,
    required this.totalChunks,
    required this.progressPercent,
    required this.statusMessage,
  });
}

class PipelineCoordinator {
  final AppDatabase db;
  final MediaEngine mediaEngine;
  final SecureStorageService secureStorage;
  final TranslationService translationService;

  final GroqWhisperProvider groqProvider = GroqWhisperProvider();
  final GeminiProvider geminiProvider = GeminiProvider();
  final DeepgramNovaProvider deepgramProvider = DeepgramNovaProvider();

  PipelineCoordinator({
    required this.db,
    required this.mediaEngine,
    required this.secureStorage,
    required this.translationService,
  });

  /// Starts processing a long video file through the full Edge-Cloud hybrid pipeline
  Stream<PipelineProgress> processVideo({
    required String videoPath,
    required int audioStreamIndex,
    required SourceLanguage sourceLang,
    required TranscriptionProviderType providerType,
    required TranslationModelType translationModel,
    required String tempWorkDir,
    required String outputDir,
    bool exportVtt = true,
  }) async* {
    final jobId = const Uuid().v4();
    final videoFile = File(videoPath);
    final filename = p.basename(videoPath);
    final fileSizeBytes = await videoFile.length();
    final now = DateTime.now().millisecondsSinceEpoch;

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

    // 1. Initial State: PENDING
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

    yield PipelineProgress(
      jobId: jobId,
      status: JobStatus.pending,
      currentChunk: 0,
      totalChunks: 0,
      progressPercent: 0.05,
      statusMessage: 'Probing media tracks...',
    );

    // 2. EXTRACTING AUDIO
    await _updateJobStatus(jobId, JobStatus.extractingAudio);
    yield PipelineProgress(
      jobId: jobId,
      status: JobStatus.extractingAudio,
      currentChunk: 0,
      totalChunks: 0,
      progressPercent: 0.10,
      statusMessage: 'Extracting & filtering audio (16kHz mono, EBU R128)...',
    );

    final jobTempDir = Directory(p.join(tempWorkDir, jobId));
    await jobTempDir.create(recursive: true);
    final fullAudioPath = p.join(jobTempDir.path, '${jobId}_full.mp3');

    final extractionResult = await mediaEngine.extractAudio(
      inputPath: videoPath,
      outputPath: fullAudioPath,
      audioStreamIndex: audioStreamIndex,
      config: const AudioExtractionConfig(),
    );

    await db.updateJob(JobsCompanion(
      id: Value(jobId),
      durationSeconds: Value(extractionResult.durationSeconds),
      updatedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
    ));

    // 3. CHUNKING with Silence-Aware VAD
    await _updateJobStatus(jobId, JobStatus.chunking);
    yield PipelineProgress(
      jobId: jobId,
      status: JobStatus.chunking,
      currentChunk: 0,
      totalChunks: 0,
      progressPercent: 0.20,
      statusMessage: 'Detecting speech silence intervals...',
    );

    final silenceStderr = await mediaEngine.detectSilence(audioPath: fullAudioPath);
    final silenceIntervals = VadChunkCalculator.parseSilenceOutput(silenceStderr);
    final splitPoints = VadChunkCalculator.calculateSplitPoints(
      totalDurationSeconds: extractionResult.durationSeconds,
      silenceIntervals: silenceIntervals,
    );

    final chunkPaths = await mediaEngine.splitAudioAtTimestamps(
      inputPath: fullAudioPath,
      splitPointsSeconds: splitPoints,
      outputDir: jobTempDir.path,
      prefix: jobId,
    );

    final totalChunks = chunkPaths.length;
    await db.updateJob(JobsCompanion(
      id: Value(jobId),
      totalChunks: Value(totalChunks),
      updatedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
    ));

    // Insert Chunks into DB
    double currentOffset = 0.0;
    for (int i = 0; i < totalChunks; i++) {
      final chunkFile = File(chunkPaths[i]);
      final size = await chunkFile.length();
      final endOffset = (i < splitPoints.length) ? splitPoints[i] : extractionResult.durationSeconds;
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

    // 4. TRANSCRIBING Chunks Sequentially
    await _updateJobStatus(jobId, JobStatus.transcribing);

    final List<TranscriptSegmentsCompanion> allSegmentsToInsert = [];
    int globalSegmentIndex = 0;

    for (int i = 0; i < totalChunks; i++) {
      final chunkId = '${jobId}_chunk_$i';
      final chunkPath = chunkPaths[i];

      yield PipelineProgress(
        jobId: jobId,
        status: JobStatus.transcribing,
        currentChunk: i + 1,
        totalChunks: totalChunks,
        progressPercent: 0.25 + (0.45 * (i / totalChunks)),
        statusMessage: 'Transcribing chunk ${i + 1} of $totalChunks with ${providerType.displayName}...',
      );

      final chunkRecord = (await db.getChunksForJob(jobId)).firstWhere((c) => c.id == chunkId);
      final offset = chunkRecord.startSeconds;

      TranscriptionResult result;
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

      for (final seg in result.segments) {
        final adjusted = seg.copyWithOffset(offset, globalSegmentIndex++);
        allSegmentsToInsert.add(TranscriptSegmentsCompanion.insert(
          jobId: jobId,
          chunkId: chunkId,
          segmentIndex: adjusted.index,
          startSeconds: adjusted.startSeconds,
          endSeconds: adjusted.endSeconds,
          sourceText: adjusted.text,
          speakerTag: Value(adjusted.speakerTag),
        ));
      }

      await db.updateChunk(ChunksCompanion(
        id: Value(chunkId),
        status: const Value('COMPLETED'),
        completedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
      ));

      // Clean up chunk audio immediately after transcribing
      try {
        final chunkFile = File(chunkPath);
        if (await chunkFile.exists()) {
          await chunkFile.delete();
        }
      } catch (_) {}
    }

    // Persist all segments
    await db.insertSegments(allSegmentsToInsert);

    // Delete full audio file
    try {
      final fullAudioFile = File(fullAudioPath);
      if (await fullAudioFile.exists()) {
        await fullAudioFile.delete();
      }
    } catch (_) {}

    // 5. TRANSLATING (Stage 2)
    final segmentsFromDb = await db.getSegmentsForJob(jobId);

    if (translationModel != TranslationModelType.none && translationApiKey != null) {
      await _updateJobStatus(jobId, JobStatus.translating);
      yield PipelineProgress(
        jobId: jobId,
        status: JobStatus.translating,
        currentChunk: totalChunks,
        totalChunks: totalChunks,
        progressPercent: 0.75,
        statusMessage: 'Translating subtitles to English with ${translationModel.displayName}...',
      );

      final inputs = segmentsFromDb
          .map((s) => TranslationSegmentInput(id: s.id, source: s.sourceText))
          .toList();

      final outputs = await translationService.translateSegments(
        segments: inputs,
        modelType: translationModel,
        apiKey: translationApiKey,
      );

      for (final out in outputs) {
        await db.updateSegmentTranslation(out.id, out.translation);
      }
    }

    // 6. FORMATTING Subtitles (SRT & VTT)
    await _updateJobStatus(jobId, JobStatus.formatting);
    yield PipelineProgress(
      jobId: jobId,
      status: JobStatus.formatting,
      currentChunk: totalChunks,
      totalChunks: totalChunks,
      progressPercent: 0.90,
      statusMessage: 'Applying Netflix/BBC formatting rules & generating files...',
    );

    final finalSegments = await db.getSegmentsForJob(jobId);
    final List<SubtitleCue> cues = [];

    for (int i = 0; i < finalSegments.length; i++) {
      final seg = finalSegments[i];
      final rawText = seg.translatedText?.isNotEmpty == true ? seg.translatedText! : seg.sourceText;
      final formattedText = SubtitleLineBreaker.formatCueText(rawText);

      cues.add(SubtitleCue(
        index: i + 1,
        startSeconds: seg.startSeconds,
        endSeconds: seg.endSeconds,
        text: formattedText,
      ));
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
      durationSeconds: extractionResult.durationSeconds,
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

    yield PipelineProgress(
      jobId: jobId,
      status: JobStatus.completed,
      currentChunk: totalChunks,
      totalChunks: totalChunks,
      progressPercent: 1.0,
      statusMessage: 'Completed! Subtitles saved to ${srtFile.path}',
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

