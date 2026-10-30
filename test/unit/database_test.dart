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
}
