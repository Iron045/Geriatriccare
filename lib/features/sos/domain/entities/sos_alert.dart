enum SosTriggerMethod { button, shake }

enum SosStatus { active, acknowledged, resolved, cancelled }

class SosAlert {
  const SosAlert({
    required this.id,
    required this.elderUserId,
    required this.triggerMethod,
    required this.status,
    required this.triggeredAt,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.locationCapturedAt,
    this.acknowledgedAt,
    this.acknowledgedById,
    this.resolvedAt,
  });

  final String id;
  final String elderUserId;
  final SosTriggerMethod triggerMethod;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final DateTime? locationCapturedAt;
  final SosStatus status;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedById;
  final DateTime? resolvedAt;
}
