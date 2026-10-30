import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';

part 'database.g.dart';

void setupSqliteOnLinux() {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      try {
        return DynamicLibrary.open('libsqlite3.so');
      } catch (_) {
        return DynamicLibrary.open('libsqlite3.so.0');
      }
    });
  }
}

@DataClassName('JobEntry')
class Jobs extends Table {
  TextColumn get id => text()();
  TextColumn get videoFilePath => text()();
  TextColumn get originalFilename => text()();
  Int64Column get fileSizeBytes => int64()();
  RealColumn get durationSeconds => real().withDefault(const Constant(0.0))();
  IntColumn get audioStreamIndex => integer().withDefault(const Constant(0))();

  TextColumn get sourceLanguage => text()();
  TextColumn get targetLanguage => text().withDefault(const Constant('en'))();

  TextColumn get provider => text()();
  TextColumn get translationModel => text()();

  TextColumn get status => text()();
  IntColumn get currentChunkIndex => integer().withDefault(const Constant(0))();
  IntColumn get totalChunks => integer().withDefault(const Constant(0))();

  TextColumn get errorMessage => text().nullable()();
  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChunkEntry')
class Chunks extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text().references(Jobs, #id, onDelete: KeyAction.cascade)();
  IntColumn get chunkIndex => integer()();

  RealColumn get startSeconds => real()();
  RealColumn get endSeconds => real()();
  RealColumn get durationSeconds => real()();

  TextColumn get audioFilePath => text()();
  Int64Column get fileSizeBytes => int64()();

  TextColumn get status => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get completedAt => int64().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TranscriptSegmentEntry')
class TranscriptSegments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobId => text().references(Jobs, #id, onDelete: KeyAction.cascade)();
  TextColumn get chunkId => text().references(Chunks, #id, onDelete: KeyAction.cascade)();

  IntColumn get segmentIndex => integer()();
  RealColumn get startSeconds => real()();
  RealColumn get endSeconds => real()();

  TextColumn get sourceText => text()();
  TextColumn get translatedText => text().nullable()();
  TextColumn get speakerTag => text().nullable()();

  BoolColumn get isTranslated => boolean().withDefault(const Constant(false))();
}

@DataClassName('SubtitleEntry')
class Subtitles extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text().nullable().references(Jobs, #id, onDelete: KeyAction.setNull)();
  TextColumn get userId => text().nullable()();

  TextColumn get title => text()();
  TextColumn get originalFilename => text()();
  TextColumn get sourceLanguage => text()();
  TextColumn get targetLanguage => text().withDefault(const Constant('en'))();
  RealColumn get durationSeconds => real()();

  TextColumn get providerUsed => text()();
  TextColumn get translationModel => text().nullable()();
  IntColumn get cueCount => integer()();
  Int64Column get fileSizeBytes => int64()();

  TextColumn get localSrtPath => text()();
  TextColumn get localVttPath => text().nullable()();
  TextColumn get storagePath => text().nullable()();
  TextColumn get storagePathVtt => text().nullable()();

  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  Int64Column get cloudSyncedAt => int64().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subtitleId => text().references(Subtitles, #id, onDelete: KeyAction.cascade)();
  TextColumn get operation => text()(); // "CREATE", "UPDATE", "DELETE"
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  Int64Column get enqueuedAt => int64()();
}

@DriftDatabase(tables: [Jobs, Chunks, TranscriptSegments, Subtitles, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      setupSqliteOnLinux();
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'subtitle_generator.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  // --- Job Operations ---
  Future<void> insertJob(JobsCompanion job) => into(jobs).insert(job);
  Future<void> updateJob(JobsCompanion job) => (update(jobs)..where((t) => t.id.equals(job.id.value))).write(job);
  Future<JobEntry?> getJob(String id) => (select(jobs)..where((t) => t.id.equals(id))).getSingleOrNull();
  Stream<List<JobEntry>> watchAllJobs() => (select(jobs)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Future<List<JobEntry>> getActiveJobs() => (select(jobs)..where((t) => t.status.isNotIn(['completed', 'failed', 'cancelled']))).get();

  // --- Chunk Operations ---
  Future<void> insertChunk(ChunksCompanion chunk) => into(chunks).insert(chunk);
  Future<void> updateChunk(ChunksCompanion chunk) => (update(chunks)..where((t) => t.id.equals(chunk.id.value))).write(chunk);
  Future<List<ChunkEntry>> getChunksForJob(String jobId) => (select(chunks)..where((t) => t.jobId.equals(jobId))..orderBy([(t) => OrderingTerm.asc(t.chunkIndex)])).get();

  // --- Transcript Segment Operations ---
  Future<void> insertSegments(List<TranscriptSegmentsCompanion> segmentList) => batch((b) => b.insertAll(transcriptSegments, segmentList));
  Future<List<TranscriptSegmentEntry>> getSegmentsForJob(String jobId) => (select(transcriptSegments)..where((t) => t.jobId.equals(jobId))..orderBy([(t) => OrderingTerm.asc(t.segmentIndex)])).get();
  Future<void> updateSegmentTranslation(int id, String translatedText) => (update(transcriptSegments)..where((t) => t.id.equals(id))).write(TranscriptSegmentsCompanion(
    translatedText: Value(translatedText),
    isTranslated: const Value(true),
  ));

  // --- Subtitle Operations ---
  Future<void> insertSubtitle(SubtitlesCompanion subtitle) => into(subtitles).insert(subtitle);
  Future<void> updateSubtitle(SubtitlesCompanion subtitle) => (update(subtitles)..where((t) => t.id.equals(subtitle.id.value))).write(subtitle);
  Future<SubtitleEntry?> getSubtitle(String id) => (select(subtitles)..where((t) => t.id.equals(id))).getSingleOrNull();
  Stream<List<SubtitleEntry>> watchActiveSubtitles() => (select(subtitles)..where((t) => t.isDeleted.equals(false))..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Future<void> softDeleteSubtitle(String id) => (update(subtitles)..where((t) => t.id.equals(id))).write(SubtitlesCompanion(
    isDeleted: const Value(true),
    updatedAt: Value(BigInt.from(DateTime.now().millisecondsSinceEpoch)),
  ));
}

