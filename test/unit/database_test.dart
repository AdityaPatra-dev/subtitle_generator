import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/core/constants/enums.dart';
import 'package:subtitle_generator/core/storage/database.dart';
import 'package:drift/drift.dart' hide isNotNull;

void main() {
  late AppDatabase db;

  setUp(() {
    setupSqliteOnLinux();
    // In-memory sqlite database for unit testing
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Jobs and Chunks persistence lifecycle', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const jobId = 'job-test-uuid-001';

    await db.insertJob(JobsCompanion.insert(
      id: jobId,
      videoFilePath: '/path/to/video.mp4',
      originalFilename: 'video.mp4',
      fileSizeBytes: BigInt.from(1024 * 1024 * 50),
      durationSeconds: const Value(1800.0),
      sourceLanguage: 'ja',
      provider: TranscriptionProviderType.groqWhisperLargeV3.name,
      translationModel: TranslationModelType.gemini25Flash.name,
      status: JobStatus.pending.name,
      createdAt: BigInt.from(now),
      updatedAt: BigInt.from(now),
    ));

    final fetched = await db.getJob(jobId);
    expect(fetched, isNotNull);
    expect(fetched!.originalFilename, 'video.mp4');
    expect(fetched.status, 'pending');

    // Insert Chunks
    await db.insertChunk(ChunksCompanion.insert(
      id: '${jobId}_chunk_0',
      jobId: jobId,
      chunkIndex: 0,
      startSeconds: 0.0,
      endSeconds: 720.0,
      durationSeconds: 720.0,
      audioFilePath: '/tmp/chunk_0.mp3',
      fileSizeBytes: BigInt.from(3500000),
      status: 'COMPLETED',
      createdAt: BigInt.from(now),
    ));

    final chunks = await db.getChunksForJob(jobId);
    expect(chunks.length, 1);
    expect(chunks.first.durationSeconds, 720.0);

    // Insert Subtitle
    const subId = 'sub-uuid-001';
    await db.insertSubtitle(SubtitlesCompanion.insert(
      id: subId,
      jobId: const Value(jobId),
      title: 'video',
      originalFilename: 'video.mp4',
      sourceLanguage: 'ja',
      durationSeconds: 1800.0,
      providerUsed: 'groqWhisperLargeV3',
      cueCount: 250,
      fileSizeBytes: BigInt.from(45000),
      localSrtPath: '/path/to/video.srt',
      createdAt: BigInt.from(now),
      updatedAt: BigInt.from(now),
    ));

    final sub = await db.getSubtitle(subId);
    expect(sub, isNotNull);
    expect(sub!.title, 'video');
    expect(sub.isDeleted, false);

    // Test soft delete
    await db.softDeleteSubtitle(subId);
    final deletedSub = await db.getSubtitle(subId);
    expect(deletedSub!.isDeleted, true);
  });

  test('Incomplete jobs tracking and clean deletion', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const jobId = 'job-failed-001';

    // Insert a failed job
    await db.insertJob(JobsCompanion.insert(
      id: jobId,
      videoFilePath: '/videos/movie.mp4',
      originalFilename: 'movie.mp4',
      fileSizeBytes: BigInt.from(100 * 1024 * 1024),
      durationSeconds: const Value(3600.0),
      sourceLanguage: 'en',
      provider: TranscriptionProviderType.deepgramNova3.name,
      translationModel: TranslationModelType.gemini25Flash.name,
      status: JobStatus.failed.name,
      failedStage: const Value('transcription'),
      cachedAudioPath: const Value('/cache/movie.mp3'),
      createdAt: BigInt.from(now),
      updatedAt: BigInt.from(now),
    ));

    // Also insert a segment for this job
    await db.insertSegments([
      TranscriptSegmentsCompanion.insert(
        jobId: jobId,
        chunkId: 'chunk-0',
        segmentIndex: 0,
        startSeconds: 0.0,
        endSeconds: 5.0,
        sourceText: 'Hello world',
      ),
    ]);

    // Check incomplete jobs query
    final incomplete = await db.getIncompleteJobs();
    expect(incomplete.length, 1);
    expect(incomplete.first.id, jobId);
    expect(incomplete.first.failedStage, 'transcription');

    // Find by file path
    final match = await db.findIncompleteJobForFile('/videos/movie.mp4', 100 * 1024 * 1024);
    expect(match, isNotNull);
    expect(match!.id, jobId);

    // Delete job and all associated data
    await db.deleteJobAndData(jobId);

    final afterDelete = await db.getIncompleteJobs();
    expect(afterDelete.isEmpty, true);

    final segsAfter = await db.getSegmentsForJob(jobId);
    expect(segsAfter.isEmpty, true);
  });
}
