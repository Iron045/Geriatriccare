import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/voice_reminder_repository_impl.dart';
import '../../domain/repositories/voice_reminder_repository.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

final voiceReminderRepositoryProvider = Provider<VoiceReminderRepository>(
  (ref) => VoiceReminderRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  ),
);
