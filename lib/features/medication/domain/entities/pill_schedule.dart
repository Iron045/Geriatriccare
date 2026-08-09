class PillSchedule {
  const PillSchedule({
    required this.id,
    required this.elderUserId,
    required this.medicationName,
    required this.dosage,
    required this.instruction,
    required this.timesInMinutes,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  final String id;
  final String elderUserId;
  final String medicationName;
  final String dosage;
  final String instruction;
  final List<int> timesInMinutes;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
}
