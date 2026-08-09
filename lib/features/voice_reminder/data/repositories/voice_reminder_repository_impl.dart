import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/voice_reminder.dart';
import '../../domain/repositories/voice_reminder_repository.dart';

final class VoiceReminderRepositoryImpl implements VoiceReminderRepository {
  VoiceReminderRepositoryImpl(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<VoiceReminder> upload({
    required String ownerId,
    required String title,
    required Uint8List audioBytes,
    required int durationSeconds,
  }) async {
    final document = _firestore.collection('voice_reminders').doc();
    final storagePath = 'voice_reminders/$ownerId/${document.id}.wav';
    final reference = _storage.ref(storagePath);
    await reference.putData(
      audioBytes,
      SettableMetadata(contentType: 'audio/wav'),
    );
    final downloadUrl = await reference.getDownloadURL();
    final now = DateTime.now();
    try {
      await document.set({
        'ownerId': ownerId,
        'title': title,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'durationSeconds': durationSeconds,
        'createdAt': Timestamp.fromDate(now),
      });
    } catch (_) {
      await reference.delete();
      rethrow;
    }
    return VoiceReminder(
      id: document.id,
      ownerId: ownerId,
      title: title,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      durationSeconds: durationSeconds,
      createdAt: now,
    );
  }
}
