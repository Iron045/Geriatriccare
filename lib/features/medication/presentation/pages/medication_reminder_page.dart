import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_brand.dart';
import '../../domain/entities/medication_intake.dart';
import '../../domain/entities/pill_schedule.dart';
import '../../domain/entities/scheduled_medication_dose.dart';
import '../providers/medication_providers.dart';

class MedicationReminderPage extends ConsumerWidget {
  const MedicationReminderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(medicationSchedulesProvider);
    final intakes = ref.watch(todayMedicationIntakesProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        titleSpacing: 0,
        title: const AppBrand(compact: true),
      ),
      body: schedules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(error: error),
        data: (items) => intakes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(error: error),
          data: (logs) {
            final dose = _nextPendingDose(items, logs);
            if (dose == null) return const _NoDoseBody();
            return _ReminderBody(dose: dose);
          },
        ),
      ),
    );
  }

  ScheduledMedicationDose? _nextPendingDose(
    List<PillSchedule> schedules,
    List<MedicationIntake> intakes,
  ) {
    final doses = buildMedicationDosesForDay(schedules, DateTime.now());
    final pending = doses.where(
      (dose) => !intakes.any(
        (intake) =>
            intake.scheduleId == dose.schedule.id &&
            intake.scheduledAt.hour == dose.scheduledAt.hour &&
            intake.scheduledAt.minute == dose.scheduledAt.minute,
      ),
    );
    if (pending.isEmpty) return null;
    final now = DateTime.now();
    return pending.cast<ScheduledMedicationDose?>().firstWhere(
      (dose) => !dose!.scheduledAt.isBefore(now),
      orElse: () => pending.first,
    );
  }
}

class _ReminderBody extends ConsumerStatefulWidget {
  const _ReminderBody({required this.dose});
  final ScheduledMedicationDose dose;

  @override
  ConsumerState<_ReminderBody> createState() => _ReminderBodyState();
}

class _ReminderBodyState extends ConsumerState<_ReminderBody> {
  bool loading = false;

  Future<void> confirm() async {
    setState(() => loading = true);
    try {
      final dose = widget.dose;
      await ref
          .read(medicationRepositoryProvider)
          .confirmTaken(
            elderId: dose.schedule.elderUserId,
            scheduleId: dose.schedule.id,
            scheduledAt: dose.scheduledAt,
            takenAt: DateTime.now(),
          );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xác nhận: $error')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.dose.schedule;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.filledTonal(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã đến giờ uống ${schedule.dosage} '
                    '${schedule.medicationName}. ${schedule.instruction}.',
                  ),
                ),
              ),
              iconSize: 38,
              padding: const EdgeInsets.all(18),
              icon: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 54),
          Center(
            child: Container(
              width: 164,
              height: 164,
              decoration: const BoxDecoration(
                color: AppColors.primaryBright,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 92,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'ĐÃ ĐẾN GIỜ UỐNG THUỐC',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 29,
                      height: 1.25,
                    ),
                    children: [
                      const TextSpan(text: 'Hãy uống '),
                      TextSpan(
                        text: '${schedule.dosage}\n${schedule.medicationName}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' ngay bây giờ.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  schedule.instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: loading ? null : confirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(78),
              backgroundColor: const Color(0xFF17A94E),
            ),
            icon: loading
                ? const SizedBox.square(
                    dimension: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle, size: 36),
            label: const Text(
              'ĐÃ UỐNG',
              style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: loading ? null : () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(78),
              backgroundColor: const Color(0xFFF05208),
            ),
            icon: const Icon(Icons.snooze_rounded, size: 36),
            label: const Text(
              'NHẮC LẠI SAU 10 PHÚT',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDoseBody extends StatelessWidget {
  const _NoDoseBody();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text(
        'Không còn liều thuốc nào cần uống hôm nay.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Không thể tải lịch thuốc:\n$error'),
    ),
  );
}
