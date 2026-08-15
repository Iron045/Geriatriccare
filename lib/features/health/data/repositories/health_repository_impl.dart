import '../../domain/entities/health_record.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_remote_data_source.dart';
import '../models/health_record_model.dart';

final class HealthRepositoryImpl implements HealthRepository {
  const HealthRepositoryImpl(this._remoteDataSource);

  final HealthRemoteDataSource _remoteDataSource;

  @override
  Stream<List<HealthRecord>> watchRecords(String elderId) => _remoteDataSource
      .watchRecords(elderId)
      .map(
        (models) =>
            models.map((model) => model.toEntity()).toList(growable: false),
      );

  @override
  Future<void> saveRecord(HealthRecord record) =>
      _remoteDataSource.saveRecord(HealthRecordModel.fromEntity(record));

  @override
  Future<void> markAsContacted({
    required String recordId,
    required String childId,
  }) => _remoteDataSource.markAsContacted(recordId: recordId, childId: childId);
}
