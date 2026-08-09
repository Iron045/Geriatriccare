import '../entities/pill_schedule.dart';
import '../entities/medication_intake.dart';

abstract interface class MedicationRepository {
  Stream<List<PillSchedule>> watchSchedules(String elderId);
  Stream<List<MedicationIntake>> watchIntakes({
    required String elderId,
    required DateTime day,
  });
  Future<void> createSchedule(PillSchedule schedule);
  Future<void> confirmTaken({
    required String elderId,
    required String scheduleId,
    required DateTime scheduledAt,
    required DateTime takenAt,
  });
}
