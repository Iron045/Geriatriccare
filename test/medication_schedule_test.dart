import 'package:flutter_test/flutter_test.dart';
import 'package:geriatriccare/features/medication/domain/entities/pill_schedule.dart';
import 'package:geriatriccare/features/medication/domain/entities/scheduled_medication_dose.dart';

void main() {
  test('builds and sorts all medication doses for a day', () {
    final day = DateTime(2026, 8, 7);
    final schedules = [
      PillSchedule(
        id: 'a',
        elderUserId: 'elder',
        medicationName: 'Amlodipine 5mg',
        dosage: '1 viên',
        instruction: 'Sau ăn',
        timesInMinutes: const [20 * 60, 7 * 60],
        startDate: day,
      ),
    ];

    final doses = buildMedicationDosesForDay(schedules, day);

    expect(doses, hasLength(2));
    expect(doses.first.scheduledAt.hour, 7);
    expect(doses.last.scheduledAt.hour, 20);
  });

  test('excludes schedules outside their active date range', () {
    final day = DateTime(2026, 8, 7);
    final schedules = [
      PillSchedule(
        id: 'expired',
        elderUserId: 'elder',
        medicationName: 'Thuốc cũ',
        dosage: '1 viên',
        instruction: 'Sau ăn',
        timesInMinutes: const [7 * 60],
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      ),
    ];

    expect(buildMedicationDosesForDay(schedules, day), isEmpty);
  });
}
