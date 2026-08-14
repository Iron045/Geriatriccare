class ElderLocation {
  const ElderLocation({
    required this.elderId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.updatedAt,
  });

  final String elderId;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime updatedAt;
}
