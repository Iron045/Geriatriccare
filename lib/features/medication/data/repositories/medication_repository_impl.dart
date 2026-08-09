import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/medication_intake.dart';
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
  Future<void> createSchedule(PillSchedule schedule) {
    final collection = _firestore.collection('medication_schedules');
    final document = schedule.id.isEmpty
        ? collection.doc()
        : collection.doc(schedule.id);
    return document.set(PillScheduleModel.toFirestore(schedule));
  }

  @override
  Future<void> confirmTaken({
    required String elderId,
    required String scheduleId,
    required DateTime scheduledAt,
    required DateTime takenAt,
  }) {
    final key = '${elderId}_${scheduleId}_${_dateKey(scheduledAt)}';
    return _firestore.collection('medication_intakes').doc(key).set({
      'elderUserId': elderId,
      'scheduleId': scheduleId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'takenAt': Timestamp.fromDate(takenAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}'
      '_${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}';
}
