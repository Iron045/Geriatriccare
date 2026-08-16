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
    final snapshot = await reference.putData(
      audioBytes,
      SettableMetadata(contentType: 'audio/wav'),
    );
    String? downloadUrl;
    Object? downloadUrlError;
    try {
      downloadUrl = await _getDownloadUrlWithRetry(snapshot.ref);
    } catch (error) {
      // storagePath is sufficient to retrieve the file later. A temporary
      // getDownloadURL failure must not prevent Firestore metadata creation.
      downloadUrlError = error;
    }
    final now = DateTime.now();
    try {
      await document.set({
        'ownerId': ownerId,
        'title': title,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'uploadStatus': downloadUrl == null ? 'stored' : 'ready',
        if (downloadUrlError != null)
          'downloadUrlError': downloadUrlError.toString(),
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
      downloadUrl: downloadUrl ?? '',
      durationSeconds: durationSeconds,
      createdAt: now,
    );
  }

  Future<String> _getDownloadUrlWithRetry(Reference reference) async {
    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        return await reference.getDownloadURL();
      } on FirebaseException catch (error) {
        lastError = error;
        if (error.code != 'object-not-found' || attempt == 3) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    throw StateError('Không thể lấy URL bản ghi: $lastError');
  }
}
