import '../entities/pill_schedule.dart';
import '../entities/medication_intake.dart';
import '../entities/medication_history_entry.dart';

abstract interface class MedicationRepository {
  Stream<List<PillSchedule>> watchSchedules(String elderId);
  Stream<List<MedicationIntake>> watchIntakes({
    required String elderId,
    required DateTime day,
  });
  Stream<List<MedicationHistoryEntry>> watchHistory(String elderId);
  Future<void> syncMissedDoses({
    required String elderId,
    required List<PillSchedule> schedules,
    required DateTime now,
  });
  Future<void> createSchedule(PillSchedule schedule);
  Future<void> deleteSchedule({
    required String scheduleId,
    required String elderId,
  });
  Future<void> confirmTaken({
    required String elderId,
    required String scheduleId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledAt,
    required DateTime takenAt,
  });
}
