class MedicationIntake {
  const MedicationIntake({
    required this.id,
    required this.elderUserId,
    required this.scheduleId,
    required this.scheduledAt,
    required this.takenAt,
  });

  final String id;
  final String elderUserId;
  final String scheduleId;
  final DateTime scheduledAt;
  final DateTime takenAt;
}
