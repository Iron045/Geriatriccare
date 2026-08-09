import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/entities/medication_intake.dart';
import '../../domain/entities/pill_schedule.dart';
import '../../domain/repositories/medication_repository.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepositoryImpl(ref.watch(firestoreProvider)),
);

final medicationSchedulesProvider = StreamProvider<List<PillSchedule>>((ref) {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  if (userId == null) return const Stream.empty();
  return ref.watch(medicationRepositoryProvider).watchSchedules(userId);
});

final medicationSchedulesForElderProvider =
    StreamProvider.family<List<PillSchedule>, String>((ref, elderId) {
      return ref.watch(medicationRepositoryProvider).watchSchedules(elderId);
    });

final todayMedicationIntakesProvider = StreamProvider<List<MedicationIntake>>((
  ref,
) {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  if (userId == null) return const Stream.empty();
  return ref
      .watch(medicationRepositoryProvider)
      .watchIntakes(elderId: userId, day: DateTime.now());
});

final todayMedicationIntakesForElderProvider =
    StreamProvider.family<List<MedicationIntake>, String>((ref, elderId) {
      return ref
          .watch(medicationRepositoryProvider)
          .watchIntakes(elderId: elderId, day: DateTime.now());
    });
