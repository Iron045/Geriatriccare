import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sos_alert.dart';

abstract final class SosAlertModel {
  static SosAlert fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return SosAlert(
      id: document.id,
      elderUserId: data['elderUserId'] as String? ?? '',
      triggerMethod: SosTriggerMethod.values.firstWhere(
        (value) => value.name == data['triggerMethod'],
        orElse: () => SosTriggerMethod.button,
      ),
      status: SosStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => SosStatus.active,
      ),
      triggeredAt:
          (data['triggeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationAccuracy: (data['locationAccuracy'] as num?)?.toDouble(),
      locationCapturedAt: (data['locationCapturedAt'] as Timestamp?)?.toDate(),
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
      acknowledgedById: data['acknowledgedById'] as String?,
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, Object?> toFirestore(SosAlert alert) => {
    'elderUserId': alert.elderUserId,
    'triggerMethod': alert.triggerMethod.name,
    'status': alert.status.name,
    'triggeredAt': Timestamp.fromDate(alert.triggeredAt),
    'latitude': alert.latitude,
    'longitude': alert.longitude,
    'locationAccuracy': alert.locationAccuracy,
    'locationCapturedAt': alert.locationCapturedAt == null
        ? null
        : Timestamp.fromDate(alert.locationCapturedAt!),
    'acknowledgedAt': alert.acknowledgedAt == null
        ? null
        : Timestamp.fromDate(alert.acknowledgedAt!),
    'acknowledgedById': alert.acknowledgedById,
    'resolvedAt': alert.resolvedAt == null
        ? null
        : Timestamp.fromDate(alert.resolvedAt!),
  };
}
