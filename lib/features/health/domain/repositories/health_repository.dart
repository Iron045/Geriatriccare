import '../entities/health_record.dart';

abstract interface class HealthRepository {
  Stream<List<HealthRecord>> watchRecords(String elderId);
  Future<void> saveRecord(HealthRecord record);
  Future<void> markAsContacted({
    required String recordId,
    required String childId,
  });
}
