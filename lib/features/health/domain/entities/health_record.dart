import 'blood_pressure_status.dart';

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.elderUserId,
    required this.systolic,
    required this.diastolic,
    required this.recordedAt,
    this.contactedAt,
    this.contactedById,
  });
  final String id;
  final String elderUserId;
  final int systolic;
  final int diastolic;
  final DateTime recordedAt;
  final DateTime? contactedAt;
  final String? contactedById;

  bool get hasBeenContacted => contactedAt != null;

  BloodPressureStatus get status => classifyBloodPressure(systolic, diastolic);

  bool get isAbnormal => status.needsAttention;
}
