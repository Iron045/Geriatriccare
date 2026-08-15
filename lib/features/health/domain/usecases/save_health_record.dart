import '../entities/health_record.dart';
import '../repositories/health_repository.dart';

final class SaveHealthRecord {
  const SaveHealthRecord(this._repository);
  final HealthRepository _repository;

  Future<void> call(HealthRecord record) {
    if (record.systolic < 70 || record.systolic > 250) {
      throw ArgumentError.value(
        record.systolic,
        'systolic',
        'Tâm thu phải trong khoảng 70–250 mmHg',
      );
    }
    if (record.diastolic < 40 || record.diastolic > 150) {
      throw ArgumentError.value(
        record.diastolic,
        'diastolic',
        'Tâm trương phải trong khoảng 40–150 mmHg',
      );
    }
    if (record.systolic <= record.diastolic) {
      throw ArgumentError.value(
        record.systolic,
        'systolic',
        'Tâm thu phải lớn hơn tâm trương',
      );
    }
    return _repository.saveRecord(record);
  }
}
