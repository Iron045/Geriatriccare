import 'pill_schedule.dart';

class ScheduledMedicationDose {
  const ScheduledMedicationDose({
    required this.schedule,
    required this.scheduledAt,
  });

  final PillSchedule schedule;
  final DateTime scheduledAt;
}

List<ScheduledMedicationDose> buildMedicationDosesForDay(
  List<PillSchedule> schedules,
  DateTime day,
) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final doses = <ScheduledMedicationDose>[];
  for (final schedule in schedules) {
    final start = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );
    final endDate = schedule.endDate;
    final end = endDate == null
        ? null
        : DateTime(endDate.year, endDate.month, endDate.day);
    if (dayStart.isBefore(start) || (end != null && dayStart.isAfter(end))) {
      continue;
    }
    for (final minute in schedule.timesInMinutes) {
      doses.add(
        ScheduledMedicationDose(
          schedule: schedule,
          scheduledAt: dayStart.add(Duration(minutes: minute)),
        ),
      );
    }
  }
  doses.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return doses;
}
