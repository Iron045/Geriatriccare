import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/health_record.dart';

class HealthRecordModel {
  const HealthRecordModel({
    required this.id,
    required this.elderUserId,
    required this.systolic,
    required this.diastolic,
    required this.recordedAt,
    this.contactedAt,
    this.contactedById,
  });

  factory HealthRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return HealthRecordModel(
      id: document.id,
      elderUserId: data['elderUserId'] as String? ?? '',
      systolic: data['systolicBp'] as int? ?? 0,
      diastolic: data['diastolicBp'] as int? ?? 0,
      recordedAt:
          (data['recordedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      contactedAt: (data['contactedAt'] as Timestamp?)?.toDate(),
      contactedById: data['contactedById'] as String?,
    );
  }

  factory HealthRecordModel.fromEntity(HealthRecord entity) =>
      HealthRecordModel(
        id: entity.id,
        elderUserId: entity.elderUserId,
        systolic: entity.systolic,
        diastolic: entity.diastolic,
        recordedAt: entity.recordedAt,
        contactedAt: entity.contactedAt,
        contactedById: entity.contactedById,
      );

  final String id;
  final String elderUserId;
  final int systolic;
  final int diastolic;
  final DateTime recordedAt;
  final DateTime? contactedAt;
  final String? contactedById;

  HealthRecord toEntity() => HealthRecord(
    id: id,
    elderUserId: elderUserId,
    systolic: systolic,
    diastolic: diastolic,
    recordedAt: recordedAt,
    contactedAt: contactedAt,
    contactedById: contactedById,
  );

  Map<String, Object?> toFirestore() => {
    'elderUserId': elderUserId,
    'systolicBp': systolic,
    'diastolicBp': diastolic,
    'recordedAt': Timestamp.fromDate(recordedAt),
    'contactedAt': contactedAt == null
        ? null
        : Timestamp.fromDate(contactedAt!),
    'contactedById': contactedById,
  };
}
