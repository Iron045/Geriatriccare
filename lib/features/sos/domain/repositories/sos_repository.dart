import '../entities/sos_alert.dart';

abstract interface class SosRepository {
  Future<String> sendAlert(SosAlert alert);
  Stream<List<SosAlert>> watchActiveAlerts(String elderId);
  Stream<SosAlert?> watchAlert(String alertId);
  Future<void> acknowledgeAlert({
    required String alertId,
    required String childId,
  });
  Future<void> cancelAlert(String alertId);
  Future<void> resolveAlert(String alertId);
}
