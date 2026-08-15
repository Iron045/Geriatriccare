import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/medication_intake.dart';
import '../../domain/entities/medication_history_entry.dart';
import '../../domain/entities/scheduled_medication_dose.dart';
import '../../domain/entities/pill_schedule.dart';
import '../../domain/repositories/medication_repository.dart';
import '../models/pill_schedule_model.dart';

final class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<PillSchedule>> watchSchedules(String elderId) => _firestore
      .collection('medication_schedules')
      .where('elderUserId', isEqualTo: elderId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(PillScheduleModel.fromFirestore)
            .where((schedule) => schedule.isActive)
            .toList(),
      );

  @override
  Stream<List<MedicationIntake>> watchIntakes({
    required String elderId,
    required DateTime day,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _firestore
        .collection('medication_intakes')
        .where('elderUserId', isEqualTo: elderId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) {
                final data = document.data();
                return MedicationIntake(
                  id: document.id,
                  elderUserId: data['elderUserId'] as String,
                  scheduleId: data['scheduleId'] as String,
                  scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
                  takenAt: (data['takenAt'] as Timestamp).toDate(),
                );
              })
              .where(
                (intake) =>
                    !intake.scheduledAt.isBefore(start) &&
                    intake.scheduledAt.isBefore(end),
              )
              .toList(),
        );
  }

  @override
  Stream<List<MedicationHistoryEntry>> watchHistory(String elderId) =>
      _firestore
          .collection('medication_history')
          .where('elderUserId', isEqualTo: elderId)
          .snapshots()
          .map((snapshot) {
            final items = snapshot.docs.map((document) {
              final data = document.data();
              return MedicationHistoryEntry(
                id: document.id,
                elderUserId: data['elderUserId'] as String,
                scheduleId: data['scheduleId'] as String,
                medicationName:
                    data['medicationName'] as String? ?? 'Không rõ tên thuốc',
                dosage: data['dosage'] as String? ?? 'Không rõ liều lượng',
                scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
                takenAt: (data['takenAt'] as Timestamp?)?.toDate(),
                status: data['status'] == MedicationHistoryStatus.missed.name
                    ? MedicationHistoryStatus.missed
                    : MedicationHistoryStatus.taken,
              );
            }).toList();
            items.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
            return items;
          });

  @override
  Future<void> syncMissedDoses({
    required String elderId,
    required List<PillSchedule> schedules,
    required DateTime now,
  }) async {
    final today = DateTime(now.year, now.month, now.day);
    final earliest = today.subtract(const Duration(days: 30));
    final historyCollection = _firestore.collection('medication_history');
    final existingSnapshot = await historyCollection
        .where('elderUserId', isEqualTo: elderId)
        .get();
    final existingIds = existingSnapshot.docs.map((item) => item.id).toSet();
    var batch = _firestore.batch();
    var pendingWrites = 0;
    for (
      var day = earliest;
      !day.isAfter(today);
      day = day.add(const Duration(days: 1))
    ) {
      for (final dose in buildMedicationDosesForDay(schedules, day)) {
        if (dose.schedule.elderUserId != elderId ||
            !now.isAfter(dose.scheduledAt.add(const Duration(hours: 5)))) {
          continue;
        }
        final id = _historyKey(elderId, dose.schedule.id, dose.scheduledAt);
        if (existingIds.contains(id)) continue;
        final reference = historyCollection.doc(id);
        batch.set(reference, {
          'elderUserId': elderId,
          'scheduleId': dose.schedule.id,
          'medicationName': dose.schedule.medicationName,
          'dosage': dose.schedule.dosage,
          'scheduledAt': Timestamp.fromDate(dose.scheduledAt),
          'takenAt': null,
          'status': MedicationHistoryStatus.missed.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        existingIds.add(id);
        pendingWrites++;
        if (pendingWrites == 450) {
          await batch.commit();
          batch = _firestore.batch();
          pendingWrites = 0;
        }
      }
    }
    if (pendingWrites > 0) await batch.commit();
  }

  @override
  Future<void> createSchedule(PillSchedule schedule) {
    final collection = _firestore.collection('medication_schedules');
    final document = schedule.id.isEmpty
        ? collection.doc()
        : collection.doc(schedule.id);
    return document.set(PillScheduleModel.toFirestore(schedule));
  }

  @override
  Future<void> deleteSchedule({
    required String scheduleId,
    required String elderId,
  }) async {
    final reference = _firestore
        .collection('medication_schedules')
        .doc(scheduleId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data == null || data['elderUserId'] != elderId) {
        throw StateError('Lịch thuốc không tồn tại hoặc không hợp lệ.');
      }
      transaction.delete(reference);
    });
  }

  @override
  Future<void> confirmTaken({
    required String elderId,
    required String scheduleId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledAt,
    required DateTime takenAt,
  }) async {
    final key = '${elderId}_${scheduleId}_${_dateKey(scheduledAt)}';
    final batch = _firestore.batch();
    batch.set(_firestore.collection('medication_intakes').doc(key), {
      'elderUserId': elderId,
      'scheduleId': scheduleId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'takenAt': Timestamp.fromDate(takenAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('medication_history').doc(key), {
      'elderUserId': elderId,
      'scheduleId': scheduleId,
      'medicationName': medicationName,
      'dosage': dosage,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'takenAt': Timestamp.fromDate(takenAt),
      'status': MedicationHistoryStatus.taken.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  String _historyKey(String elderId, String scheduleId, DateTime value) =>
      '${elderId}_${scheduleId}_${_dateKey(value)}';

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}'
      '_${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}';
}
