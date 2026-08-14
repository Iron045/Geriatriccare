import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/elder_location.dart';
import '../../domain/repositories/elder_location_repository.dart';

final class ElderLocationRepositoryImpl implements ElderLocationRepository {
  ElderLocationRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _locations =>
      _firestore.collection('elder_locations');

  @override
  Stream<ElderLocation?> watchLocation(String elderId) =>
      _locations.doc(elderId).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        final updatedAt = data['updatedAt'];
        return ElderLocation(
          elderId: elderId,
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          accuracyMeters: (data['accuracyMeters'] as num?)?.toDouble() ?? 0,
          updatedAt: updatedAt is Timestamp
              ? updatedAt.toDate()
              : DateTime.now(),
        );
      });

  @override
  Future<void> saveLocation(ElderLocation location) =>
      _locations.doc(location.elderId).set({
        'elderId': location.elderId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracyMeters': location.accuracyMeters,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
