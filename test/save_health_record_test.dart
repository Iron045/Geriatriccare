import 'package:flutter_test/flutter_test.dart';
import 'package:geriatriccare/features/health/domain/entities/health_record.dart';
import 'package:geriatriccare/features/health/domain/repositories/health_repository.dart';
import 'package:geriatriccare/features/health/domain/usecases/save_health_record.dart';

void main() {
  test('saves a valid blood pressure record', () async {
    final repository = _FakeHealthRepository();
    final useCase = SaveHealthRecord(repository);
    final record = HealthRecord(
      id: '',
      elderUserId: 'elder',
      systolic: 120,
      diastolic: 80,
      recordedAt: DateTime(2026, 8, 7),
    );

    await useCase(record);

    expect(repository.saved, same(record));
  });

  test('rejects systolic pressure not greater than diastolic', () async {
    final useCase = SaveHealthRecord(_FakeHealthRepository());
    final record = HealthRecord(
      id: '',
      elderUserId: 'elder',
      systolic: 80,
      diastolic: 90,
      recordedAt: DateTime(2026, 8, 7),
    );

    expect(() => useCase(record), throwsArgumentError);
  });
}

class _FakeHealthRepository implements HealthRepository {
  HealthRecord? saved;
  String? contactedRecordId;

  @override
  Future<void> saveRecord(HealthRecord record) async => saved = record;

  @override
  Future<void> markAsContacted({
    required String recordId,
    required String childId,
  }) async {
    contactedRecordId = recordId;
  }

  @override
  Stream<List<HealthRecord>> watchRecords(String elderId) =>
      Stream.value(const []);
}
