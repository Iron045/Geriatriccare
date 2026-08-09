import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

final authUserIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).watchUserId(),
);
final currentProfileProvider = FutureProvider.family<AppUser?, String>(
  (ref, userId) => ref.watch(authRepositoryProvider).getProfile(userId),
);

Future<void> performSignOut(WidgetRef ref) async {
  final repository = ref.read(authRepositoryProvider);
  final userId = repository.currentUserId;
  if (userId != null) ref.invalidate(currentProfileProvider(userId));
  await repository.signOut();
  ref.invalidate(authUserIdProvider);
}
