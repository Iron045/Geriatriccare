import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/health_record_model.dart';

abstract interface class HealthRemoteDataSource {
  Stream<List<HealthRecordModel>> watchRecords(String elderId);
  Future<void> saveRecord(HealthRecordModel record);
  Future<void> markAsContacted({
    required String recordId,
    required String childId,
  });
}

final class FirestoreHealthRemoteDataSource implements HealthRemoteDataSource {
  FirestoreHealthRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('health_records');

  @override
  Stream<List<HealthRecordModel>> watchRecords(String elderId) => _records
      .where('elderUserId', isEqualTo: elderId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map(HealthRecordModel.fromFirestore)
            .toList(growable: true);
        records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        return List.unmodifiable(records);
      });

  @override
  Future<void> saveRecord(HealthRecordModel record) {
    final document = record.id.isEmpty
        ? _records.doc()
        : _records.doc(record.id);
    return document.set(record.toFirestore());
  }

  @override
  Future<void> markAsContacted({
    required String recordId,
    required String childId,
  }) => _records.doc(recordId).update({
    'contactedAt': FieldValue.serverTimestamp(),
    'contactedById': childId,
  });
}
