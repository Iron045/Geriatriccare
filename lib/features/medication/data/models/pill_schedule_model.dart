import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/pill_schedule.dart';

abstract final class PillScheduleModel {
  static PillSchedule fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return PillSchedule(
      id: document.id,
      elderUserId: data['elderUserId'] as String? ?? '',
      medicationName: data['medicationName'] as String? ?? '',
      dosage: data['dosage'] as String? ?? '',
      instruction: data['instruction'] as String? ?? '',
      timesInMinutes: (data['timesInMinutes'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> toFirestore(PillSchedule schedule) => {
    'elderUserId': schedule.elderUserId,
    'medicationName': schedule.medicationName,
    'dosage': schedule.dosage,
    'instruction': schedule.instruction,
    'timesInMinutes': schedule.timesInMinutes,
    'startDate': Timestamp.fromDate(schedule.startDate),
    'endDate': schedule.endDate == null
        ? null
        : Timestamp.fromDate(schedule.endDate!),
    'isActive': schedule.isActive,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
