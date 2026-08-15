import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/medication_notification_service.dart';
import '../../domain/entities/pill_schedule.dart';
import '../providers/medication_providers.dart';

class MedicationNotificationSync extends ConsumerWidget {
  const MedicationNotificationSync({
    super.key,
    required this.elderId,
    required this.child,
  });

  final String elderId;
  final Widget child;

  void _sync(List<PillSchedule> schedules) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MedicationNotificationService.instance.syncSchedules(elderId, schedules);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(medicationSchedulesForElderProvider(elderId));
    final current = schedules.asData?.value;
    if (current != null) _sync(current);
    ref.listen(medicationSchedulesForElderProvider(elderId), (_, next) {
      final value = next.asData?.value;
      if (value != null) _sync(value);
    });
    return child;
  }
}
