// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $JobsTable extends Jobs with TableInfo<$JobsTable, JobEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _videoFilePathMeta =
      const VerificationMeta('videoFilePath');
  @override
  late final GeneratedColumn<String> videoFilePath = GeneratedColumn<String>(
      'video_file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originalFilenameMeta =
      const VerificationMeta('originalFilename');
  @override
  late final GeneratedColumn<String> originalFilename = GeneratedColumn<String>(
      'original_filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<BigInt> fileSizeBytes = GeneratedColumn<BigInt>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _audioStreamIndexMeta =
      const VerificationMeta('audioStreamIndex');
  @override
  late final GeneratedColumn<int> audioStreamIndex = GeneratedColumn<int>(
      'audio_stream_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sourceLanguageMeta =
      const VerificationMeta('sourceLanguage');
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
      'source_language', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetLanguageMeta =
      const VerificationMeta('targetLanguage');
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
      'target_language', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('en'));
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _translationModelMeta =
      const VerificationMeta('translationModel');
  @override
  late final GeneratedColumn<String> translationModel = GeneratedColumn<String>(
      'translation_model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentChunkIndexMeta =
      const VerificationMeta('currentChunkIndex');
  @override
  late final GeneratedColumn<int> currentChunkIndex = GeneratedColumn<int>(
      'current_chunk_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalChunksMeta =
      const VerificationMeta('totalChunks');
  @override
  late final GeneratedColumn<int> totalChunks = GeneratedColumn<int>(
      'total_chunks', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cachedAudioPathMeta =
      const VerificationMeta('cachedAudioPath');
  @override
  late final GeneratedColumn<String> cachedAudioPath = GeneratedColumn<String>(
      'cached_audio_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _failedStageMeta =
      const VerificationMeta('failedStage');
  @override
  late final GeneratedColumn<String> failedStage = GeneratedColumn<String>(
      'failed_stage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _interruptedAtMeta =
      const VerificationMeta('interruptedAt');
  @override
  late final GeneratedColumn<BigInt> interruptedAt = GeneratedColumn<BigInt>(
      'interrupted_at', aliasedName, true,
      type: DriftSqlType.bigInt, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
      'created_at', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        videoFilePath,
        originalFilename,
        fileSizeBytes,
        durationSeconds,
        audioStreamIndex,
        sourceLanguage,
        targetLanguage,
        provider,
        translationModel,
        status,
        currentChunkIndex,
        totalChunks,
        errorMessage,
        cachedAudioPath,
        failedStage,
        interruptedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(Insertable<JobEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('video_file_path')) {
      context.handle(
          _videoFilePathMeta,
          videoFilePath.isAcceptableOrUnknown(
              data['video_file_path']!, _videoFilePathMeta));
    } else if (isInserting) {
      context.missing(_videoFilePathMeta);
    }
    if (data.containsKey('original_filename')) {
      context.handle(
          _originalFilenameMeta,
          originalFilename.isAcceptableOrUnknown(
              data['original_filename']!, _originalFilenameMeta));
    } else if (isInserting) {
      context.missing(_originalFilenameMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('audio_stream_index')) {
      context.handle(
          _audioStreamIndexMeta,
          audioStreamIndex.isAcceptableOrUnknown(
              data['audio_stream_index']!, _audioStreamIndexMeta));
    }
    if (data.containsKey('source_language')) {
      context.handle(
          _sourceLanguageMeta,
          sourceLanguage.isAcceptableOrUnknown(
              data['source_language']!, _sourceLanguageMeta));
    } else if (isInserting) {
      context.missing(_sourceLanguageMeta);
    }
    if (data.containsKey('target_language')) {
      context.handle(
          _targetLanguageMeta,
          targetLanguage.isAcceptableOrUnknown(
              data['target_language']!, _targetLanguageMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('translation_model')) {
      context.handle(
          _translationModelMeta,
          translationModel.isAcceptableOrUnknown(
              data['translation_model']!, _translationModelMeta));
    } else if (isInserting) {
      context.missing(_translationModelMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('current_chunk_index')) {
      context.handle(
          _currentChunkIndexMeta,
          currentChunkIndex.isAcceptableOrUnknown(
              data['current_chunk_index']!, _currentChunkIndexMeta));
    }
    if (data.containsKey('total_chunks')) {
      context.handle(
          _totalChunksMeta,
          totalChunks.isAcceptableOrUnknown(
              data['total_chunks']!, _totalChunksMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('cached_audio_path')) {
      context.handle(
          _cachedAudioPathMeta,
          cachedAudioPath.isAcceptableOrUnknown(
              data['cached_audio_path']!, _cachedAudioPathMeta));
    }
    if (data.containsKey('failed_stage')) {
      context.handle(
          _failedStageMeta,
          failedStage.isAcceptableOrUnknown(
              data['failed_stage']!, _failedStageMeta));
    }
    if (data.containsKey('interrupted_at')) {
      context.handle(
          _interruptedAtMeta,
          interruptedAt.isAcceptableOrUnknown(
              data['interrupted_at']!, _interruptedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JobEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      videoFilePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}video_file_path'])!,
      originalFilename: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}original_filename'])!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
          DriftSqlType.bigInt, data['${effectivePrefix}file_size_bytes'])!,
      durationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}duration_seconds'])!,
      audioStreamIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}audio_stream_index'])!,
      sourceLanguage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_language'])!,
      targetLanguage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}target_language'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      translationModel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}translation_model'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      currentChunkIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_chunk_index'])!,
      totalChunks: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_chunks'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      cachedAudioPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cached_audio_path']),
      failedStage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}failed_stage']),
      interruptedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}interrupted_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class JobEntry extends DataClass implements Insertable<JobEntry> {
  final String id;
  final String videoFilePath;
  final String originalFilename;
  final BigInt fileSizeBytes;
  final double durationSeconds;
  final int audioStreamIndex;
  final String sourceLanguage;
  final String targetLanguage;
  final String provider;
  final String translationModel;
  final String status;
  final int currentChunkIndex;
  final int totalChunks;
  final String? errorMessage;
  final String? cachedAudioPath;
  final String? failedStage;
  final BigInt? interruptedAt;
  final BigInt createdAt;
  final BigInt updatedAt;
  const JobEntry(
      {required this.id,
      required this.videoFilePath,
      required this.originalFilename,
      required this.fileSizeBytes,
      required this.durationSeconds,
      required this.audioStreamIndex,
      required this.sourceLanguage,
      required this.targetLanguage,
      required this.provider,
      required this.translationModel,
      required this.status,
      required this.currentChunkIndex,
      required this.totalChunks,
      this.errorMessage,
      this.cachedAudioPath,
      this.failedStage,
      this.interruptedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['video_file_path'] = Variable<String>(videoFilePath);
    map['original_filename'] = Variable<String>(originalFilename);
    map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes);
    map['duration_seconds'] = Variable<double>(durationSeconds);
    map['audio_stream_index'] = Variable<int>(audioStreamIndex);
    map['source_language'] = Variable<String>(sourceLanguage);
    map['target_language'] = Variable<String>(targetLanguage);
    map['provider'] = Variable<String>(provider);
    map['translation_model'] = Variable<String>(translationModel);
    map['status'] = Variable<String>(status);
    map['current_chunk_index'] = Variable<int>(currentChunkIndex);
    map['total_chunks'] = Variable<int>(totalChunks);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || cachedAudioPath != null) {
      map['cached_audio_path'] = Variable<String>(cachedAudioPath);
    }
    if (!nullToAbsent || failedStage != null) {
      map['failed_stage'] = Variable<String>(failedStage);
    }
    if (!nullToAbsent || interruptedAt != null) {
      map['interrupted_at'] = Variable<BigInt>(interruptedAt);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      videoFilePath: Value(videoFilePath),
      originalFilename: Value(originalFilename),
      fileSizeBytes: Value(fileSizeBytes),
      durationSeconds: Value(durationSeconds),
      audioStreamIndex: Value(audioStreamIndex),
      sourceLanguage: Value(sourceLanguage),
      targetLanguage: Value(targetLanguage),
      provider: Value(provider),
      translationModel: Value(translationModel),
      status: Value(status),
      currentChunkIndex: Value(currentChunkIndex),
      totalChunks: Value(totalChunks),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      cachedAudioPath: cachedAudioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedAudioPath),
      failedStage: failedStage == null && nullToAbsent
          ? const Value.absent()
          : Value(failedStage),
      interruptedAt: interruptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(interruptedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory JobEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobEntry(
      id: serializer.fromJson<String>(json['id']),
      videoFilePath: serializer.fromJson<String>(json['videoFilePath']),
      originalFilename: serializer.fromJson<String>(json['originalFilename']),
      fileSizeBytes: serializer.fromJson<BigInt>(json['fileSizeBytes']),
      durationSeconds: serializer.fromJson<double>(json['durationSeconds']),
      audioStreamIndex: serializer.fromJson<int>(json['audioStreamIndex']),
      sourceLanguage: serializer.fromJson<String>(json['sourceLanguage']),
      targetLanguage: serializer.fromJson<String>(json['targetLanguage']),
      provider: serializer.fromJson<String>(json['provider']),
      translationModel: serializer.fromJson<String>(json['translationModel']),
      status: serializer.fromJson<String>(json['status']),
      currentChunkIndex: serializer.fromJson<int>(json['currentChunkIndex']),
      totalChunks: serializer.fromJson<int>(json['totalChunks']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      cachedAudioPath: serializer.fromJson<String?>(json['cachedAudioPath']),
      failedStage: serializer.fromJson<String?>(json['failedStage']),
      interruptedAt: serializer.fromJson<BigInt?>(json['interruptedAt']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'videoFilePath': serializer.toJson<String>(videoFilePath),
      'originalFilename': serializer.toJson<String>(originalFilename),
      'fileSizeBytes': serializer.toJson<BigInt>(fileSizeBytes),
      'durationSeconds': serializer.toJson<double>(durationSeconds),
      'audioStreamIndex': serializer.toJson<int>(audioStreamIndex),
      'sourceLanguage': serializer.toJson<String>(sourceLanguage),
      'targetLanguage': serializer.toJson<String>(targetLanguage),
      'provider': serializer.toJson<String>(provider),
      'translationModel': serializer.toJson<String>(translationModel),
      'status': serializer.toJson<String>(status),
      'currentChunkIndex': serializer.toJson<int>(currentChunkIndex),
      'totalChunks': serializer.toJson<int>(totalChunks),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'cachedAudioPath': serializer.toJson<String?>(cachedAudioPath),
      'failedStage': serializer.toJson<String?>(failedStage),
      'interruptedAt': serializer.toJson<BigInt?>(interruptedAt),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
    };
  }

  JobEntry copyWith(
          {String? id,
          String? videoFilePath,
          String? originalFilename,
          BigInt? fileSizeBytes,
          double? durationSeconds,
          int? audioStreamIndex,
          String? sourceLanguage,
          String? targetLanguage,
          String? provider,
          String? translationModel,
          String? status,
          int? currentChunkIndex,
          int? totalChunks,
          Value<String?> errorMessage = const Value.absent(),
          Value<String?> cachedAudioPath = const Value.absent(),
          Value<String?> failedStage = const Value.absent(),
          Value<BigInt?> interruptedAt = const Value.absent(),
          BigInt? createdAt,
          BigInt? updatedAt}) =>
      JobEntry(
        id: id ?? this.id,
        videoFilePath: videoFilePath ?? this.videoFilePath,
        originalFilename: originalFilename ?? this.originalFilename,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        audioStreamIndex: audioStreamIndex ?? this.audioStreamIndex,
        sourceLanguage: sourceLanguage ?? this.sourceLanguage,
        targetLanguage: targetLanguage ?? this.targetLanguage,
        provider: provider ?? this.provider,
        translationModel: translationModel ?? this.translationModel,
        status: status ?? this.status,
        currentChunkIndex: currentChunkIndex ?? this.currentChunkIndex,
        totalChunks: totalChunks ?? this.totalChunks,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        cachedAudioPath: cachedAudioPath.present
            ? cachedAudioPath.value
            : this.cachedAudioPath,
        failedStage: failedStage.present ? failedStage.value : this.failedStage,
        interruptedAt:
            interruptedAt.present ? interruptedAt.value : this.interruptedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  JobEntry copyWithCompanion(JobsCompanion data) {
    return JobEntry(
      id: data.id.present ? data.id.value : this.id,
      videoFilePath: data.videoFilePath.present
          ? data.videoFilePath.value
          : this.videoFilePath,
      originalFilename: data.originalFilename.present
          ? data.originalFilename.value
          : this.originalFilename,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      audioStreamIndex: data.audioStreamIndex.present
          ? data.audioStreamIndex.value
          : this.audioStreamIndex,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
      provider: data.provider.present ? data.provider.value : this.provider,
      translationModel: data.translationModel.present
          ? data.translationModel.value
          : this.translationModel,
      status: data.status.present ? data.status.value : this.status,
      currentChunkIndex: data.currentChunkIndex.present
          ? data.currentChunkIndex.value
          : this.currentChunkIndex,
      totalChunks:
          data.totalChunks.present ? data.totalChunks.value : this.totalChunks,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      cachedAudioPath: data.cachedAudioPath.present
          ? data.cachedAudioPath.value
          : this.cachedAudioPath,
      failedStage:
          data.failedStage.present ? data.failedStage.value : this.failedStage,
      interruptedAt: data.interruptedAt.present
          ? data.interruptedAt.value
          : this.interruptedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobEntry(')
          ..write('id: $id, ')
          ..write('videoFilePath: $videoFilePath, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('audioStreamIndex: $audioStreamIndex, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('provider: $provider, ')
          ..write('translationModel: $translationModel, ')
          ..write('status: $status, ')
          ..write('currentChunkIndex: $currentChunkIndex, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('cachedAudioPath: $cachedAudioPath, ')
          ..write('failedStage: $failedStage, ')
          ..write('interruptedAt: $interruptedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      videoFilePath,
      originalFilename,
      fileSizeBytes,
      durationSeconds,
      audioStreamIndex,
      sourceLanguage,
      targetLanguage,
      provider,
      translationModel,
      status,
      currentChunkIndex,
      totalChunks,
      errorMessage,
      cachedAudioPath,
      failedStage,
      interruptedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobEntry &&
          other.id == this.id &&
          other.videoFilePath == this.videoFilePath &&
          other.originalFilename == this.originalFilename &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.durationSeconds == this.durationSeconds &&
          other.audioStreamIndex == this.audioStreamIndex &&
          other.sourceLanguage == this.sourceLanguage &&
          other.targetLanguage == this.targetLanguage &&
          other.provider == this.provider &&
          other.translationModel == this.translationModel &&
          other.status == this.status &&
          other.currentChunkIndex == this.currentChunkIndex &&
          other.totalChunks == this.totalChunks &&
          other.errorMessage == this.errorMessage &&
          other.cachedAudioPath == this.cachedAudioPath &&
          other.failedStage == this.failedStage &&
          other.interruptedAt == this.interruptedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class JobsCompanion extends UpdateCompanion<JobEntry> {
  final Value<String> id;
  final Value<String> videoFilePath;
  final Value<String> originalFilename;
  final Value<BigInt> fileSizeBytes;
  final Value<double> durationSeconds;
  final Value<int> audioStreamIndex;
  final Value<String> sourceLanguage;
  final Value<String> targetLanguage;
  final Value<String> provider;
  final Value<String> translationModel;
  final Value<String> status;
  final Value<int> currentChunkIndex;
  final Value<int> totalChunks;
  final Value<String?> errorMessage;
  final Value<String?> cachedAudioPath;
  final Value<String?> failedStage;
  final Value<BigInt?> interruptedAt;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<int> rowid;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.videoFilePath = const Value.absent(),
    this.originalFilename = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.audioStreamIndex = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.provider = const Value.absent(),
    this.translationModel = const Value.absent(),
    this.status = const Value.absent(),
    this.currentChunkIndex = const Value.absent(),
    this.totalChunks = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.cachedAudioPath = const Value.absent(),
    this.failedStage = const Value.absent(),
    this.interruptedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobsCompanion.insert({
    required String id,
    required String videoFilePath,
    required String originalFilename,
    required BigInt fileSizeBytes,
    this.durationSeconds = const Value.absent(),
    this.audioStreamIndex = const Value.absent(),
    required String sourceLanguage,
    this.targetLanguage = const Value.absent(),
    required String provider,
    required String translationModel,
    required String status,
    this.currentChunkIndex = const Value.absent(),
    this.totalChunks = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.cachedAudioPath = const Value.absent(),
    this.failedStage = const Value.absent(),
    this.interruptedAt = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        videoFilePath = Value(videoFilePath),
        originalFilename = Value(originalFilename),
        fileSizeBytes = Value(fileSizeBytes),
        sourceLanguage = Value(sourceLanguage),
        provider = Value(provider),
        translationModel = Value(translationModel),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<JobEntry> custom({
    Expression<String>? id,
    Expression<String>? videoFilePath,
    Expression<String>? originalFilename,
    Expression<BigInt>? fileSizeBytes,
    Expression<double>? durationSeconds,
    Expression<int>? audioStreamIndex,
    Expression<String>? sourceLanguage,
    Expression<String>? targetLanguage,
    Expression<String>? provider,
    Expression<String>? translationModel,
    Expression<String>? status,
    Expression<int>? currentChunkIndex,
    Expression<int>? totalChunks,
    Expression<String>? errorMessage,
    Expression<String>? cachedAudioPath,
    Expression<String>? failedStage,
    Expression<BigInt>? interruptedAt,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoFilePath != null) 'video_file_path': videoFilePath,
      if (originalFilename != null) 'original_filename': originalFilename,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (audioStreamIndex != null) 'audio_stream_index': audioStreamIndex,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (provider != null) 'provider': provider,
      if (translationModel != null) 'translation_model': translationModel,
      if (status != null) 'status': status,
      if (currentChunkIndex != null) 'current_chunk_index': currentChunkIndex,
      if (totalChunks != null) 'total_chunks': totalChunks,
      if (errorMessage != null) 'error_message': errorMessage,
      if (cachedAudioPath != null) 'cached_audio_path': cachedAudioPath,
      if (failedStage != null) 'failed_stage': failedStage,
      if (interruptedAt != null) 'interrupted_at': interruptedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobsCompanion copyWith(
      {Value<String>? id,
      Value<String>? videoFilePath,
      Value<String>? originalFilename,
      Value<BigInt>? fileSizeBytes,
      Value<double>? durationSeconds,
      Value<int>? audioStreamIndex,
      Value<String>? sourceLanguage,
      Value<String>? targetLanguage,
      Value<String>? provider,
      Value<String>? translationModel,
      Value<String>? status,
      Value<int>? currentChunkIndex,
      Value<int>? totalChunks,
      Value<String?>? errorMessage,
      Value<String?>? cachedAudioPath,
      Value<String?>? failedStage,
      Value<BigInt?>? interruptedAt,
      Value<BigInt>? createdAt,
      Value<BigInt>? updatedAt,
      Value<int>? rowid}) {
    return JobsCompanion(
      id: id ?? this.id,
      videoFilePath: videoFilePath ?? this.videoFilePath,
      originalFilename: originalFilename ?? this.originalFilename,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioStreamIndex: audioStreamIndex ?? this.audioStreamIndex,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      provider: provider ?? this.provider,
      translationModel: translationModel ?? this.translationModel,
      status: status ?? this.status,
      currentChunkIndex: currentChunkIndex ?? this.currentChunkIndex,
      totalChunks: totalChunks ?? this.totalChunks,
      errorMessage: errorMessage ?? this.errorMessage,
      cachedAudioPath: cachedAudioPath ?? this.cachedAudioPath,
      failedStage: failedStage ?? this.failedStage,
      interruptedAt: interruptedAt ?? this.interruptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (videoFilePath.present) {
      map['video_file_path'] = Variable<String>(videoFilePath.value);
    }
    if (originalFilename.present) {
      map['original_filename'] = Variable<String>(originalFilename.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<double>(durationSeconds.value);
    }
    if (audioStreamIndex.present) {
      map['audio_stream_index'] = Variable<int>(audioStreamIndex.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (translationModel.present) {
      map['translation_model'] = Variable<String>(translationModel.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (currentChunkIndex.present) {
      map['current_chunk_index'] = Variable<int>(currentChunkIndex.value);
    }
    if (totalChunks.present) {
      map['total_chunks'] = Variable<int>(totalChunks.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (cachedAudioPath.present) {
      map['cached_audio_path'] = Variable<String>(cachedAudioPath.value);
    }
    if (failedStage.present) {
      map['failed_stage'] = Variable<String>(failedStage.value);
    }
    if (interruptedAt.present) {
      map['interrupted_at'] = Variable<BigInt>(interruptedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('videoFilePath: $videoFilePath, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('audioStreamIndex: $audioStreamIndex, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('provider: $provider, ')
          ..write('translationModel: $translationModel, ')
          ..write('status: $status, ')
          ..write('currentChunkIndex: $currentChunkIndex, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('cachedAudioPath: $cachedAudioPath, ')
          ..write('failedStage: $failedStage, ')
          ..write('interruptedAt: $interruptedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChunksTable extends Chunks with TableInfo<$ChunksTable, ChunkEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES jobs (id) ON DELETE CASCADE'));
  static const VerificationMeta _chunkIndexMeta =
      const VerificationMeta('chunkIndex');
  @override
  late final GeneratedColumn<int> chunkIndex = GeneratedColumn<int>(
      'chunk_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startSecondsMeta =
      const VerificationMeta('startSeconds');
  @override
  late final GeneratedColumn<double> startSeconds = GeneratedColumn<double>(
      'start_seconds', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _endSecondsMeta =
      const VerificationMeta('endSeconds');
  @override
  late final GeneratedColumn<double> endSeconds = GeneratedColumn<double>(
      'end_seconds', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _audioFilePathMeta =
      const VerificationMeta('audioFilePath');
  @override
  late final GeneratedColumn<String> audioFilePath = GeneratedColumn<String>(
      'audio_file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<BigInt> fileSizeBytes = GeneratedColumn<BigInt>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
      'created_at', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<BigInt> completedAt = GeneratedColumn<BigInt>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.bigInt, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobId,
        chunkIndex,
        startSeconds,
        endSeconds,
        durationSeconds,
        audioFilePath,
        fileSizeBytes,
        status,
        attempts,
        errorMessage,
        createdAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chunks';
  @override
  VerificationContext validateIntegrity(Insertable<ChunkEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('chunk_index')) {
      context.handle(
          _chunkIndexMeta,
          chunkIndex.isAcceptableOrUnknown(
              data['chunk_index']!, _chunkIndexMeta));
    } else if (isInserting) {
      context.missing(_chunkIndexMeta);
    }
    if (data.containsKey('start_seconds')) {
      context.handle(
          _startSecondsMeta,
          startSeconds.isAcceptableOrUnknown(
              data['start_seconds']!, _startSecondsMeta));
    } else if (isInserting) {
      context.missing(_startSecondsMeta);
    }
    if (data.containsKey('end_seconds')) {
      context.handle(
          _endSecondsMeta,
          endSeconds.isAcceptableOrUnknown(
              data['end_seconds']!, _endSecondsMeta));
    } else if (isInserting) {
      context.missing(_endSecondsMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('audio_file_path')) {
      context.handle(
          _audioFilePathMeta,
          audioFilePath.isAcceptableOrUnknown(
              data['audio_file_path']!, _audioFilePathMeta));
    } else if (isInserting) {
      context.missing(_audioFilePathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChunkEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChunkEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      chunkIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chunk_index'])!,
      startSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}start_seconds'])!,
      endSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}end_seconds'])!,
      durationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}duration_seconds'])!,
      audioFilePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}audio_file_path'])!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
          DriftSqlType.bigInt, data['${effectivePrefix}file_size_bytes'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}created_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $ChunksTable createAlias(String alias) {
    return $ChunksTable(attachedDatabase, alias);
  }
}

class ChunkEntry extends DataClass implements Insertable<ChunkEntry> {
  final String id;
  final String jobId;
  final int chunkIndex;
  final double startSeconds;
  final double endSeconds;
  final double durationSeconds;
  final String audioFilePath;
  final BigInt fileSizeBytes;
  final String status;
  final int attempts;
  final String? errorMessage;
  final BigInt createdAt;
  final BigInt? completedAt;
  const ChunkEntry(
      {required this.id,
      required this.jobId,
      required this.chunkIndex,
      required this.startSeconds,
      required this.endSeconds,
      required this.durationSeconds,
      required this.audioFilePath,
      required this.fileSizeBytes,
      required this.status,
      required this.attempts,
      this.errorMessage,
      required this.createdAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['chunk_index'] = Variable<int>(chunkIndex);
    map['start_seconds'] = Variable<double>(startSeconds);
    map['end_seconds'] = Variable<double>(endSeconds);
    map['duration_seconds'] = Variable<double>(durationSeconds);
    map['audio_file_path'] = Variable<String>(audioFilePath);
    map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<BigInt>(completedAt);
    }
    return map;
  }

  ChunksCompanion toCompanion(bool nullToAbsent) {
    return ChunksCompanion(
      id: Value(id),
      jobId: Value(jobId),
      chunkIndex: Value(chunkIndex),
      startSeconds: Value(startSeconds),
      endSeconds: Value(endSeconds),
      durationSeconds: Value(durationSeconds),
      audioFilePath: Value(audioFilePath),
      fileSizeBytes: Value(fileSizeBytes),
      status: Value(status),
      attempts: Value(attempts),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ChunkEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChunkEntry(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      chunkIndex: serializer.fromJson<int>(json['chunkIndex']),
      startSeconds: serializer.fromJson<double>(json['startSeconds']),
      endSeconds: serializer.fromJson<double>(json['endSeconds']),
      durationSeconds: serializer.fromJson<double>(json['durationSeconds']),
      audioFilePath: serializer.fromJson<String>(json['audioFilePath']),
      fileSizeBytes: serializer.fromJson<BigInt>(json['fileSizeBytes']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      completedAt: serializer.fromJson<BigInt?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'chunkIndex': serializer.toJson<int>(chunkIndex),
      'startSeconds': serializer.toJson<double>(startSeconds),
      'endSeconds': serializer.toJson<double>(endSeconds),
      'durationSeconds': serializer.toJson<double>(durationSeconds),
      'audioFilePath': serializer.toJson<String>(audioFilePath),
      'fileSizeBytes': serializer.toJson<BigInt>(fileSizeBytes),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'completedAt': serializer.toJson<BigInt?>(completedAt),
    };
  }

  ChunkEntry copyWith(
          {String? id,
          String? jobId,
          int? chunkIndex,
          double? startSeconds,
          double? endSeconds,
          double? durationSeconds,
          String? audioFilePath,
          BigInt? fileSizeBytes,
          String? status,
          int? attempts,
          Value<String?> errorMessage = const Value.absent(),
          BigInt? createdAt,
          Value<BigInt?> completedAt = const Value.absent()}) =>
      ChunkEntry(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        chunkIndex: chunkIndex ?? this.chunkIndex,
        startSeconds: startSeconds ?? this.startSeconds,
        endSeconds: endSeconds ?? this.endSeconds,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        audioFilePath: audioFilePath ?? this.audioFilePath,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  ChunkEntry copyWithCompanion(ChunksCompanion data) {
    return ChunkEntry(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      chunkIndex:
          data.chunkIndex.present ? data.chunkIndex.value : this.chunkIndex,
      startSeconds: data.startSeconds.present
          ? data.startSeconds.value
          : this.startSeconds,
      endSeconds:
          data.endSeconds.present ? data.endSeconds.value : this.endSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      audioFilePath: data.audioFilePath.present
          ? data.audioFilePath.value
          : this.audioFilePath,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChunkEntry(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('startSeconds: $startSeconds, ')
          ..write('endSeconds: $endSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('audioFilePath: $audioFilePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      jobId,
      chunkIndex,
      startSeconds,
      endSeconds,
      durationSeconds,
      audioFilePath,
      fileSizeBytes,
      status,
      attempts,
      errorMessage,
      createdAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChunkEntry &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.chunkIndex == this.chunkIndex &&
          other.startSeconds == this.startSeconds &&
          other.endSeconds == this.endSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.audioFilePath == this.audioFilePath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class ChunksCompanion extends UpdateCompanion<ChunkEntry> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<int> chunkIndex;
  final Value<double> startSeconds;
  final Value<double> endSeconds;
  final Value<double> durationSeconds;
  final Value<String> audioFilePath;
  final Value<BigInt> fileSizeBytes;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> errorMessage;
  final Value<BigInt> createdAt;
  final Value<BigInt?> completedAt;
  final Value<int> rowid;
  const ChunksCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.startSeconds = const Value.absent(),
    this.endSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.audioFilePath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChunksCompanion.insert({
    required String id,
    required String jobId,
    required int chunkIndex,
    required double startSeconds,
    required double endSeconds,
    required double durationSeconds,
    required String audioFilePath,
    required BigInt fileSizeBytes,
    required String status,
    this.attempts = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required BigInt createdAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        jobId = Value(jobId),
        chunkIndex = Value(chunkIndex),
        startSeconds = Value(startSeconds),
        endSeconds = Value(endSeconds),
        durationSeconds = Value(durationSeconds),
        audioFilePath = Value(audioFilePath),
        fileSizeBytes = Value(fileSizeBytes),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<ChunkEntry> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<int>? chunkIndex,
    Expression<double>? startSeconds,
    Expression<double>? endSeconds,
    Expression<double>? durationSeconds,
    Expression<String>? audioFilePath,
    Expression<BigInt>? fileSizeBytes,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? errorMessage,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (chunkIndex != null) 'chunk_index': chunkIndex,
      if (startSeconds != null) 'start_seconds': startSeconds,
      if (endSeconds != null) 'end_seconds': endSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (audioFilePath != null) 'audio_file_path': audioFilePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChunksCompanion copyWith(
      {Value<String>? id,
      Value<String>? jobId,
      Value<int>? chunkIndex,
      Value<double>? startSeconds,
      Value<double>? endSeconds,
      Value<double>? durationSeconds,
      Value<String>? audioFilePath,
      Value<BigInt>? fileSizeBytes,
      Value<String>? status,
      Value<int>? attempts,
      Value<String?>? errorMessage,
      Value<BigInt>? createdAt,
      Value<BigInt?>? completedAt,
      Value<int>? rowid}) {
    return ChunksCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (chunkIndex.present) {
      map['chunk_index'] = Variable<int>(chunkIndex.value);
    }
    if (startSeconds.present) {
      map['start_seconds'] = Variable<double>(startSeconds.value);
    }
    if (endSeconds.present) {
      map['end_seconds'] = Variable<double>(endSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<double>(durationSeconds.value);
    }
    if (audioFilePath.present) {
      map['audio_file_path'] = Variable<String>(audioFilePath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<BigInt>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChunksCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('startSeconds: $startSeconds, ')
          ..write('endSeconds: $endSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('audioFilePath: $audioFilePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranscriptSegmentsTable extends TranscriptSegments
    with TableInfo<$TranscriptSegmentsTable, TranscriptSegmentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES jobs (id) ON DELETE CASCADE'));
  static const VerificationMeta _chunkIdMeta =
      const VerificationMeta('chunkId');
  @override
  late final GeneratedColumn<String> chunkId = GeneratedColumn<String>(
      'chunk_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES chunks (id) ON DELETE CASCADE'));
  static const VerificationMeta _segmentIndexMeta =
      const VerificationMeta('segmentIndex');
  @override
  late final GeneratedColumn<int> segmentIndex = GeneratedColumn<int>(
      'segment_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startSecondsMeta =
      const VerificationMeta('startSeconds');
  @override
  late final GeneratedColumn<double> startSeconds = GeneratedColumn<double>(
      'start_seconds', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _endSecondsMeta =
      const VerificationMeta('endSeconds');
  @override
  late final GeneratedColumn<double> endSeconds = GeneratedColumn<double>(
      'end_seconds', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _sourceTextMeta =
      const VerificationMeta('sourceText');
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
      'source_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _translatedTextMeta =
      const VerificationMeta('translatedText');
  @override
  late final GeneratedColumn<String> translatedText = GeneratedColumn<String>(
      'translated_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _speakerTagMeta =
      const VerificationMeta('speakerTag');
  @override
  late final GeneratedColumn<String> speakerTag = GeneratedColumn<String>(
      'speaker_tag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isTranslatedMeta =
      const VerificationMeta('isTranslated');
  @override
  late final GeneratedColumn<bool> isTranslated = GeneratedColumn<bool>(
      'is_translated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_translated" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobId,
        chunkId,
        segmentIndex,
        startSeconds,
        endSeconds,
        sourceText,
        translatedText,
        speakerTag,
        isTranslated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcript_segments';
  @override
  VerificationContext validateIntegrity(
      Insertable<TranscriptSegmentEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('chunk_id')) {
      context.handle(_chunkIdMeta,
          chunkId.isAcceptableOrUnknown(data['chunk_id']!, _chunkIdMeta));
    } else if (isInserting) {
      context.missing(_chunkIdMeta);
    }
    if (data.containsKey('segment_index')) {
      context.handle(
          _segmentIndexMeta,
          segmentIndex.isAcceptableOrUnknown(
              data['segment_index']!, _segmentIndexMeta));
    } else if (isInserting) {
      context.missing(_segmentIndexMeta);
    }
    if (data.containsKey('start_seconds')) {
      context.handle(
          _startSecondsMeta,
          startSeconds.isAcceptableOrUnknown(
              data['start_seconds']!, _startSecondsMeta));
    } else if (isInserting) {
      context.missing(_startSecondsMeta);
    }
    if (data.containsKey('end_seconds')) {
      context.handle(
          _endSecondsMeta,
          endSeconds.isAcceptableOrUnknown(
              data['end_seconds']!, _endSecondsMeta));
    } else if (isInserting) {
      context.missing(_endSecondsMeta);
    }
    if (data.containsKey('source_text')) {
      context.handle(
          _sourceTextMeta,
          sourceText.isAcceptableOrUnknown(
              data['source_text']!, _sourceTextMeta));
    } else if (isInserting) {
      context.missing(_sourceTextMeta);
    }
    if (data.containsKey('translated_text')) {
      context.handle(
          _translatedTextMeta,
          translatedText.isAcceptableOrUnknown(
              data['translated_text']!, _translatedTextMeta));
    }
    if (data.containsKey('speaker_tag')) {
      context.handle(
          _speakerTagMeta,
          speakerTag.isAcceptableOrUnknown(
              data['speaker_tag']!, _speakerTagMeta));
    }
    if (data.containsKey('is_translated')) {
      context.handle(
          _isTranslatedMeta,
          isTranslated.isAcceptableOrUnknown(
              data['is_translated']!, _isTranslatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TranscriptSegmentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranscriptSegmentEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      chunkId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chunk_id'])!,
      segmentIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}segment_index'])!,
      startSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}start_seconds'])!,
      endSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}end_seconds'])!,
      sourceText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_text'])!,
      translatedText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}translated_text']),
      speakerTag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}speaker_tag']),
      isTranslated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_translated'])!,
    );
  }

  @override
  $TranscriptSegmentsTable createAlias(String alias) {
    return $TranscriptSegmentsTable(attachedDatabase, alias);
  }
}

class TranscriptSegmentEntry extends DataClass
    implements Insertable<TranscriptSegmentEntry> {
  final int id;
  final String jobId;
  final String chunkId;
  final int segmentIndex;
  final double startSeconds;
  final double endSeconds;
  final String sourceText;
  final String? translatedText;
  final String? speakerTag;
  final bool isTranslated;
  const TranscriptSegmentEntry(
      {required this.id,
      required this.jobId,
      required this.chunkId,
      required this.segmentIndex,
      required this.startSeconds,
      required this.endSeconds,
      required this.sourceText,
      this.translatedText,
      this.speakerTag,
      required this.isTranslated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_id'] = Variable<String>(jobId);
    map['chunk_id'] = Variable<String>(chunkId);
    map['segment_index'] = Variable<int>(segmentIndex);
    map['start_seconds'] = Variable<double>(startSeconds);
    map['end_seconds'] = Variable<double>(endSeconds);
    map['source_text'] = Variable<String>(sourceText);
    if (!nullToAbsent || translatedText != null) {
      map['translated_text'] = Variable<String>(translatedText);
    }
    if (!nullToAbsent || speakerTag != null) {
      map['speaker_tag'] = Variable<String>(speakerTag);
    }
    map['is_translated'] = Variable<bool>(isTranslated);
    return map;
  }

  TranscriptSegmentsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptSegmentsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      chunkId: Value(chunkId),
      segmentIndex: Value(segmentIndex),
      startSeconds: Value(startSeconds),
      endSeconds: Value(endSeconds),
      sourceText: Value(sourceText),
      translatedText: translatedText == null && nullToAbsent
          ? const Value.absent()
          : Value(translatedText),
      speakerTag: speakerTag == null && nullToAbsent
          ? const Value.absent()
          : Value(speakerTag),
      isTranslated: Value(isTranslated),
    );
  }

  factory TranscriptSegmentEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranscriptSegmentEntry(
      id: serializer.fromJson<int>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      chunkId: serializer.fromJson<String>(json['chunkId']),
      segmentIndex: serializer.fromJson<int>(json['segmentIndex']),
      startSeconds: serializer.fromJson<double>(json['startSeconds']),
      endSeconds: serializer.fromJson<double>(json['endSeconds']),
      sourceText: serializer.fromJson<String>(json['sourceText']),
      translatedText: serializer.fromJson<String?>(json['translatedText']),
      speakerTag: serializer.fromJson<String?>(json['speakerTag']),
      isTranslated: serializer.fromJson<bool>(json['isTranslated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobId': serializer.toJson<String>(jobId),
      'chunkId': serializer.toJson<String>(chunkId),
      'segmentIndex': serializer.toJson<int>(segmentIndex),
      'startSeconds': serializer.toJson<double>(startSeconds),
      'endSeconds': serializer.toJson<double>(endSeconds),
      'sourceText': serializer.toJson<String>(sourceText),
      'translatedText': serializer.toJson<String?>(translatedText),
      'speakerTag': serializer.toJson<String?>(speakerTag),
      'isTranslated': serializer.toJson<bool>(isTranslated),
    };
  }

  TranscriptSegmentEntry copyWith(
          {int? id,
          String? jobId,
          String? chunkId,
          int? segmentIndex,
          double? startSeconds,
          double? endSeconds,
          String? sourceText,
          Value<String?> translatedText = const Value.absent(),
          Value<String?> speakerTag = const Value.absent(),
          bool? isTranslated}) =>
      TranscriptSegmentEntry(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        chunkId: chunkId ?? this.chunkId,
        segmentIndex: segmentIndex ?? this.segmentIndex,
        startSeconds: startSeconds ?? this.startSeconds,
        endSeconds: endSeconds ?? this.endSeconds,
        sourceText: sourceText ?? this.sourceText,
        translatedText:
            translatedText.present ? translatedText.value : this.translatedText,
        speakerTag: speakerTag.present ? speakerTag.value : this.speakerTag,
        isTranslated: isTranslated ?? this.isTranslated,
      );
  TranscriptSegmentEntry copyWithCompanion(TranscriptSegmentsCompanion data) {
    return TranscriptSegmentEntry(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      chunkId: data.chunkId.present ? data.chunkId.value : this.chunkId,
      segmentIndex: data.segmentIndex.present
          ? data.segmentIndex.value
          : this.segmentIndex,
      startSeconds: data.startSeconds.present
          ? data.startSeconds.value
          : this.startSeconds,
      endSeconds:
          data.endSeconds.present ? data.endSeconds.value : this.endSeconds,
      sourceText:
          data.sourceText.present ? data.sourceText.value : this.sourceText,
      translatedText: data.translatedText.present
          ? data.translatedText.value
          : this.translatedText,
      speakerTag:
          data.speakerTag.present ? data.speakerTag.value : this.speakerTag,
      isTranslated: data.isTranslated.present
          ? data.isTranslated.value
          : this.isTranslated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptSegmentEntry(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('chunkId: $chunkId, ')
          ..write('segmentIndex: $segmentIndex, ')
          ..write('startSeconds: $startSeconds, ')
          ..write('endSeconds: $endSeconds, ')
          ..write('sourceText: $sourceText, ')
          ..write('translatedText: $translatedText, ')
          ..write('speakerTag: $speakerTag, ')
          ..write('isTranslated: $isTranslated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      jobId,
      chunkId,
      segmentIndex,
      startSeconds,
      endSeconds,
      sourceText,
      translatedText,
      speakerTag,
      isTranslated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptSegmentEntry &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.chunkId == this.chunkId &&
          other.segmentIndex == this.segmentIndex &&
          other.startSeconds == this.startSeconds &&
          other.endSeconds == this.endSeconds &&
          other.sourceText == this.sourceText &&
          other.translatedText == this.translatedText &&
          other.speakerTag == this.speakerTag &&
          other.isTranslated == this.isTranslated);
}

class TranscriptSegmentsCompanion
    extends UpdateCompanion<TranscriptSegmentEntry> {
  final Value<int> id;
  final Value<String> jobId;
  final Value<String> chunkId;
  final Value<int> segmentIndex;
  final Value<double> startSeconds;
  final Value<double> endSeconds;
  final Value<String> sourceText;
  final Value<String?> translatedText;
  final Value<String?> speakerTag;
  final Value<bool> isTranslated;
  const TranscriptSegmentsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.chunkId = const Value.absent(),
    this.segmentIndex = const Value.absent(),
    this.startSeconds = const Value.absent(),
    this.endSeconds = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.translatedText = const Value.absent(),
    this.speakerTag = const Value.absent(),
    this.isTranslated = const Value.absent(),
  });
  TranscriptSegmentsCompanion.insert({
    this.id = const Value.absent(),
    required String jobId,
    required String chunkId,
    required int segmentIndex,
    required double startSeconds,
    required double endSeconds,
    required String sourceText,
    this.translatedText = const Value.absent(),
    this.speakerTag = const Value.absent(),
    this.isTranslated = const Value.absent(),
  })  : jobId = Value(jobId),
        chunkId = Value(chunkId),
        segmentIndex = Value(segmentIndex),
        startSeconds = Value(startSeconds),
        endSeconds = Value(endSeconds),
        sourceText = Value(sourceText);
  static Insertable<TranscriptSegmentEntry> custom({
    Expression<int>? id,
    Expression<String>? jobId,
    Expression<String>? chunkId,
    Expression<int>? segmentIndex,
    Expression<double>? startSeconds,
    Expression<double>? endSeconds,
    Expression<String>? sourceText,
    Expression<String>? translatedText,
    Expression<String>? speakerTag,
    Expression<bool>? isTranslated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (chunkId != null) 'chunk_id': chunkId,
      if (segmentIndex != null) 'segment_index': segmentIndex,
      if (startSeconds != null) 'start_seconds': startSeconds,
      if (endSeconds != null) 'end_seconds': endSeconds,
      if (sourceText != null) 'source_text': sourceText,
      if (translatedText != null) 'translated_text': translatedText,
      if (speakerTag != null) 'speaker_tag': speakerTag,
      if (isTranslated != null) 'is_translated': isTranslated,
    });
  }

  TranscriptSegmentsCompanion copyWith(
      {Value<int>? id,
      Value<String>? jobId,
      Value<String>? chunkId,
      Value<int>? segmentIndex,
      Value<double>? startSeconds,
      Value<double>? endSeconds,
      Value<String>? sourceText,
      Value<String?>? translatedText,
      Value<String?>? speakerTag,
      Value<bool>? isTranslated}) {
    return TranscriptSegmentsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      chunkId: chunkId ?? this.chunkId,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      speakerTag: speakerTag ?? this.speakerTag,
      isTranslated: isTranslated ?? this.isTranslated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (chunkId.present) {
      map['chunk_id'] = Variable<String>(chunkId.value);
    }
    if (segmentIndex.present) {
      map['segment_index'] = Variable<int>(segmentIndex.value);
    }
    if (startSeconds.present) {
      map['start_seconds'] = Variable<double>(startSeconds.value);
    }
    if (endSeconds.present) {
      map['end_seconds'] = Variable<double>(endSeconds.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (translatedText.present) {
      map['translated_text'] = Variable<String>(translatedText.value);
    }
    if (speakerTag.present) {
      map['speaker_tag'] = Variable<String>(speakerTag.value);
    }
    if (isTranslated.present) {
      map['is_translated'] = Variable<bool>(isTranslated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('chunkId: $chunkId, ')
          ..write('segmentIndex: $segmentIndex, ')
          ..write('startSeconds: $startSeconds, ')
          ..write('endSeconds: $endSeconds, ')
          ..write('sourceText: $sourceText, ')
          ..write('translatedText: $translatedText, ')
          ..write('speakerTag: $speakerTag, ')
          ..write('isTranslated: $isTranslated')
          ..write(')'))
        .toString();
  }
}

class $SubtitlesTable extends Subtitles
    with TableInfo<$SubtitlesTable, SubtitleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtitlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES jobs (id) ON DELETE SET NULL'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originalFilenameMeta =
      const VerificationMeta('originalFilename');
  @override
  late final GeneratedColumn<String> originalFilename = GeneratedColumn<String>(
      'original_filename', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceLanguageMeta =
      const VerificationMeta('sourceLanguage');
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
      'source_language', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetLanguageMeta =
      const VerificationMeta('targetLanguage');
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
      'target_language', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('en'));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<double> durationSeconds = GeneratedColumn<double>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _providerUsedMeta =
      const VerificationMeta('providerUsed');
  @override
  late final GeneratedColumn<String> providerUsed = GeneratedColumn<String>(
      'provider_used', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _translationModelMeta =
      const VerificationMeta('translationModel');
  @override
  late final GeneratedColumn<String> translationModel = GeneratedColumn<String>(
      'translation_model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cueCountMeta =
      const VerificationMeta('cueCount');
  @override
  late final GeneratedColumn<int> cueCount = GeneratedColumn<int>(
      'cue_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<BigInt> fileSizeBytes = GeneratedColumn<BigInt>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _localSrtPathMeta =
      const VerificationMeta('localSrtPath');
  @override
  late final GeneratedColumn<String> localSrtPath = GeneratedColumn<String>(
      'local_srt_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localVttPathMeta =
      const VerificationMeta('localVttPath');
  @override
  late final GeneratedColumn<String> localVttPath = GeneratedColumn<String>(
      'local_vtt_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _storagePathMeta =
      const VerificationMeta('storagePath');
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
      'storage_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _storagePathVttMeta =
      const VerificationMeta('storagePathVtt');
  @override
  late final GeneratedColumn<String> storagePathVtt = GeneratedColumn<String>(
      'storage_path_vtt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDirtyMeta =
      const VerificationMeta('isDirty');
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
      'is_dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_dirty" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _cloudSyncedAtMeta =
      const VerificationMeta('cloudSyncedAt');
  @override
  late final GeneratedColumn<BigInt> cloudSyncedAt = GeneratedColumn<BigInt>(
      'cloud_synced_at', aliasedName, true,
      type: DriftSqlType.bigInt, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
      'created_at', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<BigInt> updatedAt = GeneratedColumn<BigInt>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobId,
        userId,
        title,
        originalFilename,
        sourceLanguage,
        targetLanguage,
        durationSeconds,
        providerUsed,
        translationModel,
        cueCount,
        fileSizeBytes,
        localSrtPath,
        localVttPath,
        storagePath,
        storagePathVtt,
        isDirty,
        isDeleted,
        cloudSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtitles';
  @override
  VerificationContext validateIntegrity(Insertable<SubtitleEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_filename')) {
      context.handle(
          _originalFilenameMeta,
          originalFilename.isAcceptableOrUnknown(
              data['original_filename']!, _originalFilenameMeta));
    } else if (isInserting) {
      context.missing(_originalFilenameMeta);
    }
    if (data.containsKey('source_language')) {
      context.handle(
          _sourceLanguageMeta,
          sourceLanguage.isAcceptableOrUnknown(
              data['source_language']!, _sourceLanguageMeta));
    } else if (isInserting) {
      context.missing(_sourceLanguageMeta);
    }
    if (data.containsKey('target_language')) {
      context.handle(
          _targetLanguageMeta,
          targetLanguage.isAcceptableOrUnknown(
              data['target_language']!, _targetLanguageMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('provider_used')) {
      context.handle(
          _providerUsedMeta,
          providerUsed.isAcceptableOrUnknown(
              data['provider_used']!, _providerUsedMeta));
    } else if (isInserting) {
      context.missing(_providerUsedMeta);
    }
    if (data.containsKey('translation_model')) {
      context.handle(
          _translationModelMeta,
          translationModel.isAcceptableOrUnknown(
              data['translation_model']!, _translationModelMeta));
    }
    if (data.containsKey('cue_count')) {
      context.handle(_cueCountMeta,
          cueCount.isAcceptableOrUnknown(data['cue_count']!, _cueCountMeta));
    } else if (isInserting) {
      context.missing(_cueCountMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('local_srt_path')) {
      context.handle(
          _localSrtPathMeta,
          localSrtPath.isAcceptableOrUnknown(
              data['local_srt_path']!, _localSrtPathMeta));
    } else if (isInserting) {
      context.missing(_localSrtPathMeta);
    }
    if (data.containsKey('local_vtt_path')) {
      context.handle(
          _localVttPathMeta,
          localVttPath.isAcceptableOrUnknown(
              data['local_vtt_path']!, _localVttPathMeta));
    }
    if (data.containsKey('storage_path')) {
      context.handle(
          _storagePathMeta,
          storagePath.isAcceptableOrUnknown(
              data['storage_path']!, _storagePathMeta));
    }
    if (data.containsKey('storage_path_vtt')) {
      context.handle(
          _storagePathVttMeta,
          storagePathVtt.isAcceptableOrUnknown(
              data['storage_path_vtt']!, _storagePathVttMeta));
    }
    if (data.containsKey('is_dirty')) {
      context.handle(_isDirtyMeta,
          isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('cloud_synced_at')) {
      context.handle(
          _cloudSyncedAtMeta,
          cloudSyncedAt.isAcceptableOrUnknown(
              data['cloud_synced_at']!, _cloudSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubtitleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubtitleEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      originalFilename: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}original_filename'])!,
      sourceLanguage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_language'])!,
      targetLanguage: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}target_language'])!,
      durationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}duration_seconds'])!,
      providerUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_used'])!,
      translationModel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}translation_model']),
      cueCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cue_count'])!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
          DriftSqlType.bigInt, data['${effectivePrefix}file_size_bytes'])!,
      localSrtPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_srt_path'])!,
      localVttPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_vtt_path']),
      storagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storage_path']),
      storagePathVtt: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}storage_path_vtt']),
      isDirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_dirty'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      cloudSyncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}cloud_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SubtitlesTable createAlias(String alias) {
    return $SubtitlesTable(attachedDatabase, alias);
  }
}

class SubtitleEntry extends DataClass implements Insertable<SubtitleEntry> {
  final String id;
  final String? jobId;
  final String? userId;
  final String title;
  final String originalFilename;
  final String sourceLanguage;
  final String targetLanguage;
  final double durationSeconds;
  final String providerUsed;
  final String? translationModel;
  final int cueCount;
  final BigInt fileSizeBytes;
  final String localSrtPath;
  final String? localVttPath;
  final String? storagePath;
  final String? storagePathVtt;
  final bool isDirty;
  final bool isDeleted;
  final BigInt? cloudSyncedAt;
  final BigInt createdAt;
  final BigInt updatedAt;
  const SubtitleEntry(
      {required this.id,
      this.jobId,
      this.userId,
      required this.title,
      required this.originalFilename,
      required this.sourceLanguage,
      required this.targetLanguage,
      required this.durationSeconds,
      required this.providerUsed,
      this.translationModel,
      required this.cueCount,
      required this.fileSizeBytes,
      required this.localSrtPath,
      this.localVttPath,
      this.storagePath,
      this.storagePathVtt,
      required this.isDirty,
      required this.isDeleted,
      this.cloudSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['title'] = Variable<String>(title);
    map['original_filename'] = Variable<String>(originalFilename);
    map['source_language'] = Variable<String>(sourceLanguage);
    map['target_language'] = Variable<String>(targetLanguage);
    map['duration_seconds'] = Variable<double>(durationSeconds);
    map['provider_used'] = Variable<String>(providerUsed);
    if (!nullToAbsent || translationModel != null) {
      map['translation_model'] = Variable<String>(translationModel);
    }
    map['cue_count'] = Variable<int>(cueCount);
    map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes);
    map['local_srt_path'] = Variable<String>(localSrtPath);
    if (!nullToAbsent || localVttPath != null) {
      map['local_vtt_path'] = Variable<String>(localVttPath);
    }
    if (!nullToAbsent || storagePath != null) {
      map['storage_path'] = Variable<String>(storagePath);
    }
    if (!nullToAbsent || storagePathVtt != null) {
      map['storage_path_vtt'] = Variable<String>(storagePathVtt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || cloudSyncedAt != null) {
      map['cloud_synced_at'] = Variable<BigInt>(cloudSyncedAt);
    }
    map['created_at'] = Variable<BigInt>(createdAt);
    map['updated_at'] = Variable<BigInt>(updatedAt);
    return map;
  }

  SubtitlesCompanion toCompanion(bool nullToAbsent) {
    return SubtitlesCompanion(
      id: Value(id),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      title: Value(title),
      originalFilename: Value(originalFilename),
      sourceLanguage: Value(sourceLanguage),
      targetLanguage: Value(targetLanguage),
      durationSeconds: Value(durationSeconds),
      providerUsed: Value(providerUsed),
      translationModel: translationModel == null && nullToAbsent
          ? const Value.absent()
          : Value(translationModel),
      cueCount: Value(cueCount),
      fileSizeBytes: Value(fileSizeBytes),
      localSrtPath: Value(localSrtPath),
      localVttPath: localVttPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localVttPath),
      storagePath: storagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(storagePath),
      storagePathVtt: storagePathVtt == null && nullToAbsent
          ? const Value.absent()
          : Value(storagePathVtt),
      isDirty: Value(isDirty),
      isDeleted: Value(isDeleted),
      cloudSyncedAt: cloudSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubtitleEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubtitleEntry(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      userId: serializer.fromJson<String?>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      originalFilename: serializer.fromJson<String>(json['originalFilename']),
      sourceLanguage: serializer.fromJson<String>(json['sourceLanguage']),
      targetLanguage: serializer.fromJson<String>(json['targetLanguage']),
      durationSeconds: serializer.fromJson<double>(json['durationSeconds']),
      providerUsed: serializer.fromJson<String>(json['providerUsed']),
      translationModel: serializer.fromJson<String?>(json['translationModel']),
      cueCount: serializer.fromJson<int>(json['cueCount']),
      fileSizeBytes: serializer.fromJson<BigInt>(json['fileSizeBytes']),
      localSrtPath: serializer.fromJson<String>(json['localSrtPath']),
      localVttPath: serializer.fromJson<String?>(json['localVttPath']),
      storagePath: serializer.fromJson<String?>(json['storagePath']),
      storagePathVtt: serializer.fromJson<String?>(json['storagePathVtt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      cloudSyncedAt: serializer.fromJson<BigInt?>(json['cloudSyncedAt']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      updatedAt: serializer.fromJson<BigInt>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String?>(jobId),
      'userId': serializer.toJson<String?>(userId),
      'title': serializer.toJson<String>(title),
      'originalFilename': serializer.toJson<String>(originalFilename),
      'sourceLanguage': serializer.toJson<String>(sourceLanguage),
      'targetLanguage': serializer.toJson<String>(targetLanguage),
      'durationSeconds': serializer.toJson<double>(durationSeconds),
      'providerUsed': serializer.toJson<String>(providerUsed),
      'translationModel': serializer.toJson<String?>(translationModel),
      'cueCount': serializer.toJson<int>(cueCount),
      'fileSizeBytes': serializer.toJson<BigInt>(fileSizeBytes),
      'localSrtPath': serializer.toJson<String>(localSrtPath),
      'localVttPath': serializer.toJson<String?>(localVttPath),
      'storagePath': serializer.toJson<String?>(storagePath),
      'storagePathVtt': serializer.toJson<String?>(storagePathVtt),
      'isDirty': serializer.toJson<bool>(isDirty),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'cloudSyncedAt': serializer.toJson<BigInt?>(cloudSyncedAt),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'updatedAt': serializer.toJson<BigInt>(updatedAt),
    };
  }

  SubtitleEntry copyWith(
          {String? id,
          Value<String?> jobId = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          String? title,
          String? originalFilename,
          String? sourceLanguage,
          String? targetLanguage,
          double? durationSeconds,
          String? providerUsed,
          Value<String?> translationModel = const Value.absent(),
          int? cueCount,
          BigInt? fileSizeBytes,
          String? localSrtPath,
          Value<String?> localVttPath = const Value.absent(),
          Value<String?> storagePath = const Value.absent(),
          Value<String?> storagePathVtt = const Value.absent(),
          bool? isDirty,
          bool? isDeleted,
          Value<BigInt?> cloudSyncedAt = const Value.absent(),
          BigInt? createdAt,
          BigInt? updatedAt}) =>
      SubtitleEntry(
        id: id ?? this.id,
        jobId: jobId.present ? jobId.value : this.jobId,
        userId: userId.present ? userId.value : this.userId,
        title: title ?? this.title,
        originalFilename: originalFilename ?? this.originalFilename,
        sourceLanguage: sourceLanguage ?? this.sourceLanguage,
        targetLanguage: targetLanguage ?? this.targetLanguage,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        providerUsed: providerUsed ?? this.providerUsed,
        translationModel: translationModel.present
            ? translationModel.value
            : this.translationModel,
        cueCount: cueCount ?? this.cueCount,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        localSrtPath: localSrtPath ?? this.localSrtPath,
        localVttPath:
            localVttPath.present ? localVttPath.value : this.localVttPath,
        storagePath: storagePath.present ? storagePath.value : this.storagePath,
        storagePathVtt:
            storagePathVtt.present ? storagePathVtt.value : this.storagePathVtt,
        isDirty: isDirty ?? this.isDirty,
        isDeleted: isDeleted ?? this.isDeleted,
        cloudSyncedAt:
            cloudSyncedAt.present ? cloudSyncedAt.value : this.cloudSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SubtitleEntry copyWithCompanion(SubtitlesCompanion data) {
    return SubtitleEntry(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      originalFilename: data.originalFilename.present
          ? data.originalFilename.value
          : this.originalFilename,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      providerUsed: data.providerUsed.present
          ? data.providerUsed.value
          : this.providerUsed,
      translationModel: data.translationModel.present
          ? data.translationModel.value
          : this.translationModel,
      cueCount: data.cueCount.present ? data.cueCount.value : this.cueCount,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      localSrtPath: data.localSrtPath.present
          ? data.localSrtPath.value
          : this.localSrtPath,
      localVttPath: data.localVttPath.present
          ? data.localVttPath.value
          : this.localVttPath,
      storagePath:
          data.storagePath.present ? data.storagePath.value : this.storagePath,
      storagePathVtt: data.storagePathVtt.present
          ? data.storagePathVtt.value
          : this.storagePathVtt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      cloudSyncedAt: data.cloudSyncedAt.present
          ? data.cloudSyncedAt.value
          : this.cloudSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubtitleEntry(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('providerUsed: $providerUsed, ')
          ..write('translationModel: $translationModel, ')
          ..write('cueCount: $cueCount, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('localSrtPath: $localSrtPath, ')
          ..write('localVttPath: $localVttPath, ')
          ..write('storagePath: $storagePath, ')
          ..write('storagePathVtt: $storagePathVtt, ')
          ..write('isDirty: $isDirty, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('cloudSyncedAt: $cloudSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        jobId,
        userId,
        title,
        originalFilename,
        sourceLanguage,
        targetLanguage,
        durationSeconds,
        providerUsed,
        translationModel,
        cueCount,
        fileSizeBytes,
        localSrtPath,
        localVttPath,
        storagePath,
        storagePathVtt,
        isDirty,
        isDeleted,
        cloudSyncedAt,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubtitleEntry &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.originalFilename == this.originalFilename &&
          other.sourceLanguage == this.sourceLanguage &&
          other.targetLanguage == this.targetLanguage &&
          other.durationSeconds == this.durationSeconds &&
          other.providerUsed == this.providerUsed &&
          other.translationModel == this.translationModel &&
          other.cueCount == this.cueCount &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.localSrtPath == this.localSrtPath &&
          other.localVttPath == this.localVttPath &&
          other.storagePath == this.storagePath &&
          other.storagePathVtt == this.storagePathVtt &&
          other.isDirty == this.isDirty &&
          other.isDeleted == this.isDeleted &&
          other.cloudSyncedAt == this.cloudSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubtitlesCompanion extends UpdateCompanion<SubtitleEntry> {
  final Value<String> id;
  final Value<String?> jobId;
  final Value<String?> userId;
  final Value<String> title;
  final Value<String> originalFilename;
  final Value<String> sourceLanguage;
  final Value<String> targetLanguage;
  final Value<double> durationSeconds;
  final Value<String> providerUsed;
  final Value<String?> translationModel;
  final Value<int> cueCount;
  final Value<BigInt> fileSizeBytes;
  final Value<String> localSrtPath;
  final Value<String?> localVttPath;
  final Value<String?> storagePath;
  final Value<String?> storagePathVtt;
  final Value<bool> isDirty;
  final Value<bool> isDeleted;
  final Value<BigInt?> cloudSyncedAt;
  final Value<BigInt> createdAt;
  final Value<BigInt> updatedAt;
  final Value<int> rowid;
  const SubtitlesCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalFilename = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.providerUsed = const Value.absent(),
    this.translationModel = const Value.absent(),
    this.cueCount = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.localSrtPath = const Value.absent(),
    this.localVttPath = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.storagePathVtt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.cloudSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubtitlesCompanion.insert({
    required String id,
    this.jobId = const Value.absent(),
    this.userId = const Value.absent(),
    required String title,
    required String originalFilename,
    required String sourceLanguage,
    this.targetLanguage = const Value.absent(),
    required double durationSeconds,
    required String providerUsed,
    this.translationModel = const Value.absent(),
    required int cueCount,
    required BigInt fileSizeBytes,
    required String localSrtPath,
    this.localVttPath = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.storagePathVtt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.cloudSyncedAt = const Value.absent(),
    required BigInt createdAt,
    required BigInt updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        originalFilename = Value(originalFilename),
        sourceLanguage = Value(sourceLanguage),
        durationSeconds = Value(durationSeconds),
        providerUsed = Value(providerUsed),
        cueCount = Value(cueCount),
        fileSizeBytes = Value(fileSizeBytes),
        localSrtPath = Value(localSrtPath),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SubtitleEntry> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? originalFilename,
    Expression<String>? sourceLanguage,
    Expression<String>? targetLanguage,
    Expression<double>? durationSeconds,
    Expression<String>? providerUsed,
    Expression<String>? translationModel,
    Expression<int>? cueCount,
    Expression<BigInt>? fileSizeBytes,
    Expression<String>? localSrtPath,
    Expression<String>? localVttPath,
    Expression<String>? storagePath,
    Expression<String>? storagePathVtt,
    Expression<bool>? isDirty,
    Expression<bool>? isDeleted,
    Expression<BigInt>? cloudSyncedAt,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (originalFilename != null) 'original_filename': originalFilename,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (providerUsed != null) 'provider_used': providerUsed,
      if (translationModel != null) 'translation_model': translationModel,
      if (cueCount != null) 'cue_count': cueCount,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (localSrtPath != null) 'local_srt_path': localSrtPath,
      if (localVttPath != null) 'local_vtt_path': localVttPath,
      if (storagePath != null) 'storage_path': storagePath,
      if (storagePathVtt != null) 'storage_path_vtt': storagePathVtt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (cloudSyncedAt != null) 'cloud_synced_at': cloudSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubtitlesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? jobId,
      Value<String?>? userId,
      Value<String>? title,
      Value<String>? originalFilename,
      Value<String>? sourceLanguage,
      Value<String>? targetLanguage,
      Value<double>? durationSeconds,
      Value<String>? providerUsed,
      Value<String?>? translationModel,
      Value<int>? cueCount,
      Value<BigInt>? fileSizeBytes,
      Value<String>? localSrtPath,
      Value<String?>? localVttPath,
      Value<String?>? storagePath,
      Value<String?>? storagePathVtt,
      Value<bool>? isDirty,
      Value<bool>? isDeleted,
      Value<BigInt?>? cloudSyncedAt,
      Value<BigInt>? createdAt,
      Value<BigInt>? updatedAt,
      Value<int>? rowid}) {
    return SubtitlesCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      originalFilename: originalFilename ?? this.originalFilename,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      providerUsed: providerUsed ?? this.providerUsed,
      translationModel: translationModel ?? this.translationModel,
      cueCount: cueCount ?? this.cueCount,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      localSrtPath: localSrtPath ?? this.localSrtPath,
      localVttPath: localVttPath ?? this.localVttPath,
      storagePath: storagePath ?? this.storagePath,
      storagePathVtt: storagePathVtt ?? this.storagePathVtt,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
      cloudSyncedAt: cloudSyncedAt ?? this.cloudSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalFilename.present) {
      map['original_filename'] = Variable<String>(originalFilename.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<double>(durationSeconds.value);
    }
    if (providerUsed.present) {
      map['provider_used'] = Variable<String>(providerUsed.value);
    }
    if (translationModel.present) {
      map['translation_model'] = Variable<String>(translationModel.value);
    }
    if (cueCount.present) {
      map['cue_count'] = Variable<int>(cueCount.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<BigInt>(fileSizeBytes.value);
    }
    if (localSrtPath.present) {
      map['local_srt_path'] = Variable<String>(localSrtPath.value);
    }
    if (localVttPath.present) {
      map['local_vtt_path'] = Variable<String>(localVttPath.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (storagePathVtt.present) {
      map['storage_path_vtt'] = Variable<String>(storagePathVtt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (cloudSyncedAt.present) {
      map['cloud_synced_at'] = Variable<BigInt>(cloudSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<BigInt>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtitlesCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('providerUsed: $providerUsed, ')
          ..write('translationModel: $translationModel, ')
          ..write('cueCount: $cueCount, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('localSrtPath: $localSrtPath, ')
          ..write('localVttPath: $localVttPath, ')
          ..write('storagePath: $storagePath, ')
          ..write('storagePathVtt: $storagePathVtt, ')
          ..write('isDirty: $isDirty, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('cloudSyncedAt: $cloudSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _subtitleIdMeta =
      const VerificationMeta('subtitleId');
  @override
  late final GeneratedColumn<String> subtitleId = GeneratedColumn<String>(
      'subtitle_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES subtitles (id) ON DELETE CASCADE'));
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enqueuedAtMeta =
      const VerificationMeta('enqueuedAt');
  @override
  late final GeneratedColumn<BigInt> enqueuedAt = GeneratedColumn<BigInt>(
      'enqueued_at', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, subtitleId, operation, attempts, lastError, enqueuedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subtitle_id')) {
      context.handle(
          _subtitleIdMeta,
          subtitleId.isAcceptableOrUnknown(
              data['subtitle_id']!, _subtitleIdMeta));
    } else if (isInserting) {
      context.missing(_subtitleIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('enqueued_at')) {
      context.handle(
          _enqueuedAtMeta,
          enqueuedAt.isAcceptableOrUnknown(
              data['enqueued_at']!, _enqueuedAtMeta));
    } else if (isInserting) {
      context.missing(_enqueuedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      subtitleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtitle_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      enqueuedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}enqueued_at'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int id;
  final String subtitleId;
  final String operation;
  final int attempts;
  final String? lastError;
  final BigInt enqueuedAt;
  const SyncQueueEntry(
      {required this.id,
      required this.subtitleId,
      required this.operation,
      required this.attempts,
      this.lastError,
      required this.enqueuedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subtitle_id'] = Variable<String>(subtitleId);
    map['operation'] = Variable<String>(operation);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['enqueued_at'] = Variable<BigInt>(enqueuedAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      subtitleId: Value(subtitleId),
      operation: Value(operation),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      enqueuedAt: Value(enqueuedAt),
    );
  }

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      subtitleId: serializer.fromJson<String>(json['subtitleId']),
      operation: serializer.fromJson<String>(json['operation']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      enqueuedAt: serializer.fromJson<BigInt>(json['enqueuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subtitleId': serializer.toJson<String>(subtitleId),
      'operation': serializer.toJson<String>(operation),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'enqueuedAt': serializer.toJson<BigInt>(enqueuedAt),
    };
  }

  SyncQueueEntry copyWith(
          {int? id,
          String? subtitleId,
          String? operation,
          int? attempts,
          Value<String?> lastError = const Value.absent(),
          BigInt? enqueuedAt}) =>
      SyncQueueEntry(
        id: id ?? this.id,
        subtitleId: subtitleId ?? this.subtitleId,
        operation: operation ?? this.operation,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
        enqueuedAt: enqueuedAt ?? this.enqueuedAt,
      );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      subtitleId:
          data.subtitleId.present ? data.subtitleId.value : this.subtitleId,
      operation: data.operation.present ? data.operation.value : this.operation,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      enqueuedAt:
          data.enqueuedAt.present ? data.enqueuedAt.value : this.enqueuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('subtitleId: $subtitleId, ')
          ..write('operation: $operation, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('enqueuedAt: $enqueuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, subtitleId, operation, attempts, lastError, enqueuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.subtitleId == this.subtitleId &&
          other.operation == this.operation &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.enqueuedAt == this.enqueuedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> subtitleId;
  final Value<String> operation;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<BigInt> enqueuedAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.subtitleId = const Value.absent(),
    this.operation = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.enqueuedAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String subtitleId,
    required String operation,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required BigInt enqueuedAt,
  })  : subtitleId = Value(subtitleId),
        operation = Value(operation),
        enqueuedAt = Value(enqueuedAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? subtitleId,
    Expression<String>? operation,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<BigInt>? enqueuedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subtitleId != null) 'subtitle_id': subtitleId,
      if (operation != null) 'operation': operation,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (enqueuedAt != null) 'enqueued_at': enqueuedAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? subtitleId,
      Value<String>? operation,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<BigInt>? enqueuedAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      subtitleId: subtitleId ?? this.subtitleId,
      operation: operation ?? this.operation,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      enqueuedAt: enqueuedAt ?? this.enqueuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subtitleId.present) {
      map['subtitle_id'] = Variable<String>(subtitleId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (enqueuedAt.present) {
      map['enqueued_at'] = Variable<BigInt>(enqueuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('subtitleId: $subtitleId, ')
          ..write('operation: $operation, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('enqueuedAt: $enqueuedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $ChunksTable chunks = $ChunksTable(this);
  late final $TranscriptSegmentsTable transcriptSegments =
      $TranscriptSegmentsTable(this);
  late final $SubtitlesTable subtitles = $SubtitlesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [jobs, chunks, transcriptSegments, subtitles, syncQueue];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('jobs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('chunks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('jobs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transcript_segments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('chunks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transcript_segments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('jobs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('subtitles', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('subtitles',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('sync_queue', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$JobsTableCreateCompanionBuilder = JobsCompanion Function({
  required String id,
  required String videoFilePath,
  required String originalFilename,
  required BigInt fileSizeBytes,
  Value<double> durationSeconds,
  Value<int> audioStreamIndex,
  required String sourceLanguage,
  Value<String> targetLanguage,
  required String provider,
  required String translationModel,
  required String status,
  Value<int> currentChunkIndex,
  Value<int> totalChunks,
  Value<String?> errorMessage,
  Value<String?> cachedAudioPath,
  Value<String?> failedStage,
  Value<BigInt?> interruptedAt,
  required BigInt createdAt,
  required BigInt updatedAt,
  Value<int> rowid,
});
typedef $$JobsTableUpdateCompanionBuilder = JobsCompanion Function({
  Value<String> id,
  Value<String> videoFilePath,
  Value<String> originalFilename,
  Value<BigInt> fileSizeBytes,
  Value<double> durationSeconds,
  Value<int> audioStreamIndex,
  Value<String> sourceLanguage,
  Value<String> targetLanguage,
  Value<String> provider,
  Value<String> translationModel,
  Value<String> status,
  Value<int> currentChunkIndex,
  Value<int> totalChunks,
  Value<String?> errorMessage,
  Value<String?> cachedAudioPath,
  Value<String?> failedStage,
  Value<BigInt?> interruptedAt,
  Value<BigInt> createdAt,
  Value<BigInt> updatedAt,
  Value<int> rowid,
});

class $$JobsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JobsTable,
    JobEntry,
    $$JobsTableFilterComposer,
    $$JobsTableOrderingComposer,
    $$JobsTableCreateCompanionBuilder,
    $$JobsTableUpdateCompanionBuilder> {
  $$JobsTableTableManager(_$AppDatabase db, $JobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$JobsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$JobsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> videoFilePath = const Value.absent(),
            Value<String> originalFilename = const Value.absent(),
            Value<BigInt> fileSizeBytes = const Value.absent(),
            Value<double> durationSeconds = const Value.absent(),
            Value<int> audioStreamIndex = const Value.absent(),
            Value<String> sourceLanguage = const Value.absent(),
            Value<String> targetLanguage = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<String> translationModel = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> currentChunkIndex = const Value.absent(),
            Value<int> totalChunks = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> cachedAudioPath = const Value.absent(),
            Value<String?> failedStage = const Value.absent(),
            Value<BigInt?> interruptedAt = const Value.absent(),
            Value<BigInt> createdAt = const Value.absent(),
            Value<BigInt> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              JobsCompanion(
            id: id,
            videoFilePath: videoFilePath,
            originalFilename: originalFilename,
            fileSizeBytes: fileSizeBytes,
            durationSeconds: durationSeconds,
            audioStreamIndex: audioStreamIndex,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            provider: provider,
            translationModel: translationModel,
            status: status,
            currentChunkIndex: currentChunkIndex,
            totalChunks: totalChunks,
            errorMessage: errorMessage,
            cachedAudioPath: cachedAudioPath,
            failedStage: failedStage,
            interruptedAt: interruptedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String videoFilePath,
            required String originalFilename,
            required BigInt fileSizeBytes,
            Value<double> durationSeconds = const Value.absent(),
            Value<int> audioStreamIndex = const Value.absent(),
            required String sourceLanguage,
            Value<String> targetLanguage = const Value.absent(),
            required String provider,
            required String translationModel,
            required String status,
            Value<int> currentChunkIndex = const Value.absent(),
            Value<int> totalChunks = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> cachedAudioPath = const Value.absent(),
            Value<String?> failedStage = const Value.absent(),
            Value<BigInt?> interruptedAt = const Value.absent(),
            required BigInt createdAt,
            required BigInt updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              JobsCompanion.insert(
            id: id,
            videoFilePath: videoFilePath,
            originalFilename: originalFilename,
            fileSizeBytes: fileSizeBytes,
            durationSeconds: durationSeconds,
            audioStreamIndex: audioStreamIndex,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            provider: provider,
            translationModel: translationModel,
            status: status,
            currentChunkIndex: currentChunkIndex,
            totalChunks: totalChunks,
            errorMessage: errorMessage,
            cachedAudioPath: cachedAudioPath,
            failedStage: failedStage,
            interruptedAt: interruptedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$JobsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $JobsTable> {
  $$JobsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get videoFilePath => $state.composableBuilder(
      column: $state.table.videoFilePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get originalFilename => $state.composableBuilder(
      column: $state.table.originalFilename,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get durationSeconds => $state.composableBuilder(
      column: $state.table.durationSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get audioStreamIndex => $state.composableBuilder(
      column: $state.table.audioStreamIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceLanguage => $state.composableBuilder(
      column: $state.table.sourceLanguage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get targetLanguage => $state.composableBuilder(
      column: $state.table.targetLanguage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get provider => $state.composableBuilder(
      column: $state.table.provider,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get translationModel => $state.composableBuilder(
      column: $state.table.translationModel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get currentChunkIndex => $state.composableBuilder(
      column: $state.table.currentChunkIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalChunks => $state.composableBuilder(
      column: $state.table.totalChunks,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get cachedAudioPath => $state.composableBuilder(
      column: $state.table.cachedAudioPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get failedStage => $state.composableBuilder(
      column: $state.table.failedStage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get interruptedAt => $state.composableBuilder(
      column: $state.table.interruptedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter chunksRefs(
      ComposableFilter Function($$ChunksTableFilterComposer f) f) {
    final $$ChunksTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.chunks,
        getReferencedColumn: (t) => t.jobId,
        builder: (joinBuilder, parentComposers) => $$ChunksTableFilterComposer(
            ComposerState(
                $state.db, $state.db.chunks, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter transcriptSegmentsRefs(
      ComposableFilter Function($$TranscriptSegmentsTableFilterComposer f) f) {
    final $$TranscriptSegmentsTableFilterComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.transcriptSegments,
            getReferencedColumn: (t) => t.jobId,
            builder: (joinBuilder, parentComposers) =>
                $$TranscriptSegmentsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.transcriptSegments,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter subtitlesRefs(
      ComposableFilter Function($$SubtitlesTableFilterComposer f) f) {
    final $$SubtitlesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.subtitles,
        getReferencedColumn: (t) => t.jobId,
        builder: (joinBuilder, parentComposers) =>
            $$SubtitlesTableFilterComposer(ComposerState(
                $state.db, $state.db.subtitles, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$JobsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $JobsTable> {
  $$JobsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get videoFilePath => $state.composableBuilder(
      column: $state.table.videoFilePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get originalFilename => $state.composableBuilder(
      column: $state.table.originalFilename,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get durationSeconds => $state.composableBuilder(
      column: $state.table.durationSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get audioStreamIndex => $state.composableBuilder(
      column: $state.table.audioStreamIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceLanguage => $state.composableBuilder(
      column: $state.table.sourceLanguage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get targetLanguage => $state.composableBuilder(
      column: $state.table.targetLanguage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get provider => $state.composableBuilder(
      column: $state.table.provider,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get translationModel => $state.composableBuilder(
      column: $state.table.translationModel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get currentChunkIndex => $state.composableBuilder(
      column: $state.table.currentChunkIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalChunks => $state.composableBuilder(
      column: $state.table.totalChunks,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get cachedAudioPath => $state.composableBuilder(
      column: $state.table.cachedAudioPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get failedStage => $state.composableBuilder(
      column: $state.table.failedStage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get interruptedAt => $state.composableBuilder(
      column: $state.table.interruptedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ChunksTableCreateCompanionBuilder = ChunksCompanion Function({
  required String id,
  required String jobId,
  required int chunkIndex,
  required double startSeconds,
  required double endSeconds,
  required double durationSeconds,
  required String audioFilePath,
  required BigInt fileSizeBytes,
  required String status,
  Value<int> attempts,
  Value<String?> errorMessage,
  required BigInt createdAt,
  Value<BigInt?> completedAt,
  Value<int> rowid,
});
typedef $$ChunksTableUpdateCompanionBuilder = ChunksCompanion Function({
  Value<String> id,
  Value<String> jobId,
  Value<int> chunkIndex,
  Value<double> startSeconds,
  Value<double> endSeconds,
  Value<double> durationSeconds,
  Value<String> audioFilePath,
  Value<BigInt> fileSizeBytes,
  Value<String> status,
  Value<int> attempts,
  Value<String?> errorMessage,
  Value<BigInt> createdAt,
  Value<BigInt?> completedAt,
  Value<int> rowid,
});

class $$ChunksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChunksTable,
    ChunkEntry,
    $$ChunksTableFilterComposer,
    $$ChunksTableOrderingComposer,
    $$ChunksTableCreateCompanionBuilder,
    $$ChunksTableUpdateCompanionBuilder> {
  $$ChunksTableTableManager(_$AppDatabase db, $ChunksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ChunksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ChunksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> jobId = const Value.absent(),
            Value<int> chunkIndex = const Value.absent(),
            Value<double> startSeconds = const Value.absent(),
            Value<double> endSeconds = const Value.absent(),
            Value<double> durationSeconds = const Value.absent(),
            Value<String> audioFilePath = const Value.absent(),
            Value<BigInt> fileSizeBytes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<BigInt> createdAt = const Value.absent(),
            Value<BigInt?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChunksCompanion(
            id: id,
            jobId: jobId,
            chunkIndex: chunkIndex,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            durationSeconds: durationSeconds,
            audioFilePath: audioFilePath,
            fileSizeBytes: fileSizeBytes,
            status: status,
            attempts: attempts,
            errorMessage: errorMessage,
            createdAt: createdAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String jobId,
            required int chunkIndex,
            required double startSeconds,
            required double endSeconds,
            required double durationSeconds,
            required String audioFilePath,
            required BigInt fileSizeBytes,
            required String status,
            Value<int> attempts = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            required BigInt createdAt,
            Value<BigInt?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChunksCompanion.insert(
            id: id,
            jobId: jobId,
            chunkIndex: chunkIndex,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            durationSeconds: durationSeconds,
            audioFilePath: audioFilePath,
            fileSizeBytes: fileSizeBytes,
            status: status,
            attempts: attempts,
            errorMessage: errorMessage,
            createdAt: createdAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
        ));
}

class $$ChunksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ChunksTable> {
  $$ChunksTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get chunkIndex => $state.composableBuilder(
      column: $state.table.chunkIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get startSeconds => $state.composableBuilder(
      column: $state.table.startSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get endSeconds => $state.composableBuilder(
      column: $state.table.endSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get durationSeconds => $state.composableBuilder(
      column: $state.table.durationSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get audioFilePath => $state.composableBuilder(
      column: $state.table.audioFilePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get completedAt => $state.composableBuilder(
      column: $state.table.completedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.jobId,
        referencedTable: $state.db.jobs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$JobsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.jobs, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter transcriptSegmentsRefs(
      ComposableFilter Function($$TranscriptSegmentsTableFilterComposer f) f) {
    final $$TranscriptSegmentsTableFilterComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.transcriptSegments,
            getReferencedColumn: (t) => t.chunkId,
            builder: (joinBuilder, parentComposers) =>
                $$TranscriptSegmentsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.transcriptSegments,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$ChunksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ChunksTable> {
  $$ChunksTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get chunkIndex => $state.composableBuilder(
      column: $state.table.chunkIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get startSeconds => $state.composableBuilder(
      column: $state.table.startSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get endSeconds => $state.composableBuilder(
      column: $state.table.endSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get durationSeconds => $state.composableBuilder(
      column: $state.table.durationSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get audioFilePath => $state.composableBuilder(
      column: $state.table.audioFilePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get completedAt => $state.composableBuilder(
      column: $state.table.completedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.jobId,
        referencedTable: $state.db.jobs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$JobsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.jobs, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$TranscriptSegmentsTableCreateCompanionBuilder
    = TranscriptSegmentsCompanion Function({
  Value<int> id,
  required String jobId,
  required String chunkId,
  required int segmentIndex,
  required double startSeconds,
  required double endSeconds,
  required String sourceText,
  Value<String?> translatedText,
  Value<String?> speakerTag,
  Value<bool> isTranslated,
});
typedef $$TranscriptSegmentsTableUpdateCompanionBuilder
    = TranscriptSegmentsCompanion Function({
  Value<int> id,
  Value<String> jobId,
  Value<String> chunkId,
  Value<int> segmentIndex,
  Value<double> startSeconds,
  Value<double> endSeconds,
  Value<String> sourceText,
  Value<String?> translatedText,
  Value<String?> speakerTag,
  Value<bool> isTranslated,
});

class $$TranscriptSegmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TranscriptSegmentsTable,
    TranscriptSegmentEntry,
    $$TranscriptSegmentsTableFilterComposer,
    $$TranscriptSegmentsTableOrderingComposer,
    $$TranscriptSegmentsTableCreateCompanionBuilder,
    $$TranscriptSegmentsTableUpdateCompanionBuilder> {
  $$TranscriptSegmentsTableTableManager(
      _$AppDatabase db, $TranscriptSegmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TranscriptSegmentsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$TranscriptSegmentsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> jobId = const Value.absent(),
            Value<String> chunkId = const Value.absent(),
            Value<int> segmentIndex = const Value.absent(),
            Value<double> startSeconds = const Value.absent(),
            Value<double> endSeconds = const Value.absent(),
            Value<String> sourceText = const Value.absent(),
            Value<String?> translatedText = const Value.absent(),
            Value<String?> speakerTag = const Value.absent(),
            Value<bool> isTranslated = const Value.absent(),
          }) =>
              TranscriptSegmentsCompanion(
            id: id,
            jobId: jobId,
            chunkId: chunkId,
            segmentIndex: segmentIndex,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            sourceText: sourceText,
            translatedText: translatedText,
            speakerTag: speakerTag,
            isTranslated: isTranslated,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String jobId,
            required String chunkId,
            required int segmentIndex,
            required double startSeconds,
            required double endSeconds,
            required String sourceText,
            Value<String?> translatedText = const Value.absent(),
            Value<String?> speakerTag = const Value.absent(),
            Value<bool> isTranslated = const Value.absent(),
          }) =>
              TranscriptSegmentsCompanion.insert(
            id: id,
            jobId: jobId,
            chunkId: chunkId,
            segmentIndex: segmentIndex,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            sourceText: sourceText,
            translatedText: translatedText,
            speakerTag: speakerTag,
            isTranslated: isTranslated,
          ),
        ));
}

class $$TranscriptSegmentsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TranscriptSegmentsTable> {
  $$TranscriptSegmentsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get segmentIndex => $state.composableBuilder(
      column: $state.table.segmentIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get startSeconds => $state.composableBuilder(
      column: $state.table.startSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get endSeconds => $state.composableBuilder(
      column: $state.table.endSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceText => $state.composableBuilder(
      column: $state.table.sourceText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get translatedText => $state.composableBuilder(
      column: $state.table.translatedText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get speakerTag => $state.composableBuilder(
      column: $state.table.speakerTag,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isTranslated => $state.composableBuilder(
      column: $state.table.isTranslated,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.jobId,
        referencedTable: $state.db.jobs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$JobsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.jobs, joinBuilder, parentComposers)));
    return composer;
  }

  $$ChunksTableFilterComposer get chunkId {
    final $$ChunksTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chunkId,
        referencedTable: $state.db.chunks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$ChunksTableFilterComposer(
            ComposerState(
                $state.db, $state.db.chunks, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$TranscriptSegmentsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TranscriptSegmentsTable> {
  $$TranscriptSegmentsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get segmentIndex => $state.composableBuilder(
      column: $state.table.segmentIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get startSeconds => $state.composableBuilder(
      column: $state.table.startSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get endSeconds => $state.composableBuilder(
      column: $state.table.endSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceText => $state.composableBuilder(
      column: $state.table.sourceText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get translatedText => $state.composableBuilder(
      column: $state.table.translatedText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get speakerTag => $state.composableBuilder(
      column: $state.table.speakerTag,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isTranslated => $state.composableBuilder(
      column: $state.table.isTranslated,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.jobId,
        referencedTable: $state.db.jobs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$JobsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.jobs, joinBuilder, parentComposers)));
    return composer;
  }

  $$ChunksTableOrderingComposer get chunkId {
    final $$ChunksTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chunkId,
        referencedTable: $state.db.chunks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ChunksTableOrderingComposer(ComposerState(
                $state.db, $state.db.chunks, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$SubtitlesTableCreateCompanionBuilder = SubtitlesCompanion Function({
  required String id,
  Value<String?> jobId,
  Value<String?> userId,
  required String title,
  required String originalFilename,
  required String sourceLanguage,
  Value<String> targetLanguage,
  required double durationSeconds,
  required String providerUsed,
  Value<String?> translationModel,
  required int cueCount,
  required BigInt fileSizeBytes,
  required String localSrtPath,
  Value<String?> localVttPath,
  Value<String?> storagePath,
  Value<String?> storagePathVtt,
  Value<bool> isDirty,
  Value<bool> isDeleted,
  Value<BigInt?> cloudSyncedAt,
  required BigInt createdAt,
  required BigInt updatedAt,
  Value<int> rowid,
});
typedef $$SubtitlesTableUpdateCompanionBuilder = SubtitlesCompanion Function({
  Value<String> id,
  Value<String?> jobId,
  Value<String?> userId,
  Value<String> title,
  Value<String> originalFilename,
  Value<String> sourceLanguage,
  Value<String> targetLanguage,
  Value<double> durationSeconds,
  Value<String> providerUsed,
  Value<String?> translationModel,
  Value<int> cueCount,
  Value<BigInt> fileSizeBytes,
  Value<String> localSrtPath,
  Value<String?> localVttPath,
  Value<String?> storagePath,
  Value<String?> storagePathVtt,
  Value<bool> isDirty,
  Value<bool> isDeleted,
  Value<BigInt?> cloudSyncedAt,
  Value<BigInt> createdAt,
  Value<BigInt> updatedAt,
  Value<int> rowid,
});

class $$SubtitlesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubtitlesTable,
    SubtitleEntry,
    $$SubtitlesTableFilterComposer,
    $$SubtitlesTableOrderingComposer,
    $$SubtitlesTableCreateCompanionBuilder,
    $$SubtitlesTableUpdateCompanionBuilder> {
  $$SubtitlesTableTableManager(_$AppDatabase db, $SubtitlesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SubtitlesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SubtitlesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> originalFilename = const Value.absent(),
            Value<String> sourceLanguage = const Value.absent(),
            Value<String> targetLanguage = const Value.absent(),
            Value<double> durationSeconds = const Value.absent(),
            Value<String> providerUsed = const Value.absent(),
            Value<String?> translationModel = const Value.absent(),
            Value<int> cueCount = const Value.absent(),
            Value<BigInt> fileSizeBytes = const Value.absent(),
            Value<String> localSrtPath = const Value.absent(),
            Value<String?> localVttPath = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<String?> storagePathVtt = const Value.absent(),
            Value<bool> isDirty = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<BigInt?> cloudSyncedAt = const Value.absent(),
            Value<BigInt> createdAt = const Value.absent(),
            Value<BigInt> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubtitlesCompanion(
            id: id,
            jobId: jobId,
            userId: userId,
            title: title,
            originalFilename: originalFilename,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            durationSeconds: durationSeconds,
            providerUsed: providerUsed,
            translationModel: translationModel,
            cueCount: cueCount,
            fileSizeBytes: fileSizeBytes,
            localSrtPath: localSrtPath,
            localVttPath: localVttPath,
            storagePath: storagePath,
            storagePathVtt: storagePathVtt,
            isDirty: isDirty,
            isDeleted: isDeleted,
            cloudSyncedAt: cloudSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> jobId = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            required String title,
            required String originalFilename,
            required String sourceLanguage,
            Value<String> targetLanguage = const Value.absent(),
            required double durationSeconds,
            required String providerUsed,
            Value<String?> translationModel = const Value.absent(),
            required int cueCount,
            required BigInt fileSizeBytes,
            required String localSrtPath,
            Value<String?> localVttPath = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<String?> storagePathVtt = const Value.absent(),
            Value<bool> isDirty = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<BigInt?> cloudSyncedAt = const Value.absent(),
            required BigInt createdAt,
            required BigInt updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubtitlesCompanion.insert(
            id: id,
            jobId: jobId,
            userId: userId,
            title: title,
            originalFilename: originalFilename,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            durationSeconds: durationSeconds,
            providerUsed: providerUsed,
            translationModel: translationModel,
            cueCount: cueCount,
            fileSizeBytes: fileSizeBytes,
            localSrtPath: localSrtPath,
            localVttPath: localVttPath,
            storagePath: storagePath,
            storagePathVtt: storagePathVtt,
            isDirty: isDirty,
            isDeleted: isDeleted,
            cloudSyncedAt: cloudSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$SubtitlesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SubtitlesTable> {
  $$SubtitlesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get originalFilename => $state.composableBuilder(
      column: $state.table.originalFilename,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sourceLanguage => $state.composableBuilder(
      column: $state.table.sourceLanguage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get targetLanguage => $state.composableBuilder(
      column: $state.table.targetLanguage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get durationSeconds => $state.composableBuilder(
      column: $state.table.durationSeconds,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get providerUsed => $state.composableBuilder(
      column: $state.table.providerUsed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get translationModel => $state.composableBuilder(
      column: $state.table.translationModel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get cueCount => $state.composableBuilder(
      column: $state.table.cueCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localSrtPath => $state.composableBuilder(
      column: $state.table.localSrtPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get localVttPath => $state.composableBuilder(
      column: $state.table.localVttPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get storagePath => $state.composableBuilder(
      column: $state.table.storagePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get storagePathVtt => $state.composableBuilder(
      column: $state.table.storagePathVtt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDirty => $state.composableBuilder(
      column: $state.table.isDirty,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get cloudSyncedAt => $state.composableBuilder(
      column: $state.table.cloudSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.jobId,
        referencedTable: $state.db.jobs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$JobsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.jobs, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter syncQueueRefs(
      ComposableFilter Function($$SyncQueueTableFilterComposer f) f) {
    final $$SyncQueueTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.syncQueue,
        getReferencedColumn: (t) => t.subtitleId,
        builder: (joinBuilder, parentComposers) =>
            $$SyncQueueTableFilterComposer(ComposerState(
                $state.db, $state.db.syncQueue, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$SubtitlesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SubtitlesTable> {
  $$SubtitlesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get originalFilename => $state.composableBuilder(
      column: $state.table.originalFilename,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sourceLanguage => $state.composableBuilder(
      column: $state.table.sourceLanguage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get targetLanguage => $state.composableBuilder(
      column: $state.table.targetLanguage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get durationSeconds => $state.composableBuilder(
      column: $state.table.durationSeconds,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get providerUsed => $state.composableBuilder(
      column: $state.table.providerUsed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get translationModel => $state.composableBuilder(
      column: $state.table.translationModel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get cueCount => $state.composableBuilder(
      column: $state.table.cueCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get fileSizeBytes => $state.composableBuilder(
      column: $state.table.fileSizeBytes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localSrtPath => $state.composableBuilder(
      column: $state.table.localSrtPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get localVttPath => $state.composableBuilder(
      column: $state.table.localVttPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get storagePath => $state.composableBuilder(
      column: $state.table.storagePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get storagePathVtt => $state.composableBuilder(
      column: $state.table.storagePathVtt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDirty => $state.composableBuilder(
      column: $state.table.isDirty,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isDeleted => $state.composableBuilder(
      column: $state.table.isDeleted,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get cloudSyncedAt => $state.composableBuilder(
      column: $state.table.cloudSyncedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.jobId,
        referencedTable: $state.db.jobs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$JobsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.jobs, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String subtitleId,
  required String operation,
  Value<int> attempts,
  Value<String?> lastError,
  required BigInt enqueuedAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> subtitleId,
  Value<String> operation,
  Value<int> attempts,
  Value<String?> lastError,
  Value<BigInt> enqueuedAt,
});

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueEntry,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncQueueTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncQueueTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> subtitleId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<BigInt> enqueuedAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            subtitleId: subtitleId,
            operation: operation,
            attempts: attempts,
            lastError: lastError,
            enqueuedAt: enqueuedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String subtitleId,
            required String operation,
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            required BigInt enqueuedAt,
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            subtitleId: subtitleId,
            operation: operation,
            attempts: attempts,
            lastError: lastError,
            enqueuedAt: enqueuedAt,
          ),
        ));
}

class $$SyncQueueTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastError => $state.composableBuilder(
      column: $state.table.lastError,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get enqueuedAt => $state.composableBuilder(
      column: $state.table.enqueuedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$SubtitlesTableFilterComposer get subtitleId {
    final $$SubtitlesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subtitleId,
        referencedTable: $state.db.subtitles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$SubtitlesTableFilterComposer(ComposerState(
                $state.db, $state.db.subtitles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$SyncQueueTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get operation => $state.composableBuilder(
      column: $state.table.operation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastError => $state.composableBuilder(
      column: $state.table.lastError,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get enqueuedAt => $state.composableBuilder(
      column: $state.table.enqueuedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$SubtitlesTableOrderingComposer get subtitleId {
    final $$SubtitlesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subtitleId,
        referencedTable: $state.db.subtitles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$SubtitlesTableOrderingComposer(ComposerState(
                $state.db, $state.db.subtitles, joinBuilder, parentComposers)));
    return composer;
  }
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$ChunksTableTableManager get chunks =>
      $$ChunksTableTableManager(_db, _db.chunks);
  $$TranscriptSegmentsTableTableManager get transcriptSegments =>
      $$TranscriptSegmentsTableTableManager(_db, _db.transcriptSegments);
  $$SubtitlesTableTableManager get subtitles =>
      $$SubtitlesTableTableManager(_db, _db.subtitles);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
