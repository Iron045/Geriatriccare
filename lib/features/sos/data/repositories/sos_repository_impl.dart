import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sos_alert.dart';
import '../../domain/repositories/sos_repository.dart';
import '../models/sos_alert_model.dart';

final class SosRepositoryImpl implements SosRepository {
  SosRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _firestore.collection('sos_alerts');

  @override
  Future<String> sendAlert(SosAlert alert) async {
    final existingSnapshot = await _alerts
        .where('elderUserId', isEqualTo: alert.elderUserId)
        .get();
    final existing = existingSnapshot.docs
        .map(SosAlertModel.fromFirestore)
        .where(
          (item) =>
              item.status == SosStatus.active ||
              item.status == SosStatus.acknowledged,
        )
        .toList()
      ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    if (existing.isNotEmpty) return existing.first.id;
    final document = alert.id.isEmpty ? _alerts.doc() : _alerts.doc(alert.id);
    await document.set(SosAlertModel.toFirestore(alert));
    return document.id;
  }

  @override
  Stream<List<SosAlert>> watchActiveAlerts(String elderId) => _alerts
      .where('elderUserId', isEqualTo: elderId)
      .snapshots()
      .map((snapshot) {
        final alerts = snapshot.docs
            .map(SosAlertModel.fromFirestore)
            .where(
              (alert) =>
                  alert.status == SosStatus.active ||
                  alert.status == SosStatus.acknowledged,
            )
            .toList();
        alerts.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
        return alerts;
      });

  @override
  Stream<SosAlert?> watchAlert(String alertId) => _alerts
      .doc(alertId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.exists ? SosAlertModel.fromFirestore(snapshot) : null,
      );

  @override
  Future<void> acknowledgeAlert({
    required String alertId,
    required String childId,
  }) => _alerts.doc(alertId).update({
    'status': SosStatus.acknowledged.name,
    'acknowledgedAt': FieldValue.serverTimestamp(),
    'acknowledgedById': childId,
  });

  @override
  Future<void> cancelAlert(String alertId) => _alerts.doc(alertId).update({
    'status': SosStatus.cancelled.name,
    'resolvedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> resolveAlert(String alertId) => _alerts.doc(alertId).update({
    'status': SosStatus.resolved.name,
    'resolvedAt': FieldValue.serverTimestamp(),
  });
}
