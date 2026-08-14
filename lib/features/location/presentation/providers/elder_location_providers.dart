import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../sos/data/services/sos_location_service.dart';
import '../../data/repositories/elder_location_repository_impl.dart';
import '../../domain/entities/elder_location.dart';
import '../../domain/repositories/elder_location_repository.dart';

final elderLocationRepositoryProvider = Provider<ElderLocationRepository>(
  (ref) => ElderLocationRepositoryImpl(ref.watch(firestoreProvider)),
);

final elderLocationProvider = StreamProvider.family<ElderLocation?, String>(
  (ref, elderId) =>
      ref.watch(elderLocationRepositoryProvider).watchLocation(elderId),
);

Future<bool> publishCurrentElderLocation(WidgetRef ref, String elderId) async {
  final result = await SosLocationService.captureCurrentPosition();
  final position = result.position;
  if (position == null) return false;
  await ref.read(elderLocationRepositoryProvider).saveLocation(
    ElderLocation(
      elderId: elderId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      updatedAt: DateTime.now(),
    ),
  );
  return true;
}
