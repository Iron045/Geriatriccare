import 'dart:typed_data';

import '../entities/voice_reminder.dart';

abstract interface class VoiceReminderRepository {
  Future<VoiceReminder> upload({
    required String ownerId,
    required String title,
    required Uint8List audioBytes,
    required int durationSeconds,
  });
}
