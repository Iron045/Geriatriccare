import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/health_remote_data_source.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../domain/entities/health_record.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/usecases/save_health_record.dart';

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>(
  (ref) => FirestoreHealthRemoteDataSource(ref.watch(firestoreProvider)),
);

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepositoryImpl(ref.watch(healthRemoteDataSourceProvider)),
);

final saveHealthRecordProvider = Provider<SaveHealthRecord>(
  (ref) => SaveHealthRecord(ref.watch(healthRepositoryProvider)),
);

final healthRecordsProvider = StreamProvider<List<HealthRecord>>((ref) {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  if (userId == null) return Stream.value(const []);
  return ref.watch(healthRepositoryProvider).watchRecords(userId);
});

final healthRecordsForElderProvider =
    StreamProvider.family<List<HealthRecord>, String>((ref, elderId) {
      return ref.watch(healthRepositoryProvider).watchRecords(elderId);
    });
