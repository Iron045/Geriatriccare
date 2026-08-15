enum MedicationHistoryStatus { taken, missed }

class MedicationHistoryEntry {
  const MedicationHistoryEntry({
    required this.id,
    required this.elderUserId,
    required this.scheduleId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
  });

  final String id;
  final String elderUserId;
  final String scheduleId;
  final String medicationName;
  final String dosage;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final MedicationHistoryStatus status;
}
