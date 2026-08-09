import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/sos_repository_impl.dart';
import '../../domain/entities/sos_alert.dart';
import '../../domain/repositories/sos_repository.dart';

final sosRepositoryProvider = Provider<SosRepository>(
  (ref) => SosRepositoryImpl(ref.watch(firestoreProvider)),
);

final activeSosAlertsProvider = StreamProvider.family<List<SosAlert>, String>((
  ref,
  elderId,
) {
  return ref.watch(sosRepositoryProvider).watchActiveAlerts(elderId);
});

final sosAlertProvider = StreamProvider.family<SosAlert?, String>(
  (ref, alertId) => ref.watch(sosRepositoryProvider).watchAlert(alertId),
);
