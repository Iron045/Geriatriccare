class VoiceReminder {
  const VoiceReminder({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.storagePath,
    required this.downloadUrl,
    required this.durationSeconds,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String storagePath;
  final String downloadUrl;
  final int durationSeconds;
  final DateTime createdAt;
}
