import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/medication_intake.dart';
import '../../domain/entities/pill_schedule.dart';
import '../../domain/entities/scheduled_medication_dose.dart';
import '../providers/medication_providers.dart';

class MedicationPage extends ConsumerWidget {
  const MedicationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(medicationSchedulesProvider);
    final intakes = ref.watch(todayMedicationIntakesProvider);
    return SafeArea(
      child: schedules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(error: error),
        data: (items) => intakes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(error: error),
          data: (logs) => _MedicationList(schedules: items, intakes: logs),
        ),
      ),
    );
  }
}

class _MedicationList extends ConsumerWidget {
  const _MedicationList({required this.schedules, required this.intakes});
  final List<PillSchedule> schedules;
  final List<MedicationIntake> intakes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final doses = buildMedicationDosesForDay(schedules, now);
    final futureSchedules = schedules.where((schedule) {
      final start = DateTime(
        schedule.startDate.year,
        schedule.startDate.month,
        schedule.startDate.day,
      );
      return start.isAfter(today);
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(medicationSchedulesProvider);
        ref.invalidate(todayMedicationIntakesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thuốc của tôi',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
                ),
              ),
              IconButton.filled(
                onPressed: () => _showAddSchedule(context, ref),
                tooltip: 'Thêm lịch thuốc',
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Lịch uống thuốc hôm nay được đồng bộ từ Firebase.',
            style: TextStyle(fontSize: 17, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          if (schedules.isEmpty)
            const _EmptyState()
          else if (doses.isEmpty)
            const _NoDoseToday()
          else
            ...doses.map((dose) {
              final taken = intakes.any(
                (intake) =>
                    intake.scheduleId == dose.schedule.id &&
                    intake.scheduledAt.year == dose.scheduledAt.year &&
                    intake.scheduledAt.month == dose.scheduledAt.month &&
                    intake.scheduledAt.day == dose.scheduledAt.day &&
                    intake.scheduledAt.hour == dose.scheduledAt.hour &&
                    intake.scheduledAt.minute == dose.scheduledAt.minute,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _DoseCard(dose: dose, taken: taken),
              );
            }),
          if (futureSchedules.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lịch sắp tới', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...futureSchedules.map(
              (schedule) => _FutureScheduleCard(schedule: schedule),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddSchedule(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final instruction = TextEditingController(text: 'Uống sau ăn');
    var quantity = 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var date = today;
    var time = TimeOfDay.now();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm lịch uống thuốc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Tên thuốc',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Liều lượng',
                    prefixIcon: Icon(Icons.medication_liquid_rounded),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        onPressed: quantity > 1
                            ? () => setDialogState(() => quantity--)
                            : null,
                        tooltip: 'Giảm số lượng',
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text(
                        '$quantity viên',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: quantity < 20
                            ? () => setDialogState(() => quantity++)
                            : null,
                        tooltip: 'Tăng số lượng',
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: instruction,
                  decoration: const InputDecoration(labelText: 'Hướng dẫn'),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('Ngày bắt đầu uống'),
                  trailing: Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 3650)),
                    );
                    if (selected != null) {
                      setDialogState(() => date = selected);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Giờ uống'),
                  trailing: Text(
                    _formatTime(time.hour, time.minute),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (selected != null) {
                      setDialogState(() => time = selected);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave != true || name.text.trim().isEmpty) return;
    final elderId = ref.read(authRepositoryProvider).currentUserId;
    if (elderId == null) return;
    try {
      await ref
          .read(medicationRepositoryProvider)
          .createSchedule(
            PillSchedule(
              id: '',
              elderUserId: elderId,
              medicationName: name.text.trim(),
              dosage: '$quantity viên',
              instruction: instruction.text.trim(),
              timesInMinutes: [time.hour * 60 + time.minute],
              startDate: DateTime(date.year, date.month, date.day),
            ),
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể lưu: $error')));
      }
    } finally {
      name.dispose();
      instruction.dispose();
    }
  }
}

class _DoseCard extends ConsumerStatefulWidget {
  const _DoseCard({required this.dose, required this.taken});
  final ScheduledMedicationDose dose;
  final bool taken;

  @override
  ConsumerState<_DoseCard> createState() => _DoseCardState();
}

class _DoseCardState extends ConsumerState<_DoseCard> {
  bool loading = false;

  Future<void> confirm() async {
    setState(() => loading = true);
    try {
      await ref
          .read(medicationRepositoryProvider)
          .confirmTaken(
            elderId: widget.dose.schedule.elderUserId,
            scheduleId: widget.dose.schedule.id,
            scheduledAt: widget.dose.scheduledAt,
            takenAt: DateTime.now(),
          );
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: widget.taken
                  ? const Color(0xFFD8F7E3)
                  : const Color(0xFFDCE8FF),
              child: Icon(
                widget.taken ? Icons.check_rounded : Icons.medication_rounded,
                size: 38,
                color: widget.taken ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatDate(widget.dose.scheduledAt)} • '
                    '${_formatTime(widget.dose.scheduledAt.hour, widget.dose.scheduledAt.minute)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    schedule.medicationName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${schedule.dosage} • ${schedule.instruction}',
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  widget.taken
                      ? const Chip(
                          avatar: Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          ),
                          label: Text('Đã uống'),
                        )
                      : OutlinedButton.icon(
                          onPressed: loading ? null : confirm,
                          icon: loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Xác nhận uống'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        const Icon(
          Icons.medication_outlined,
          size: 82,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 18),
        Text(
          'Chưa có lịch uống thuốc',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhấn nút + để thêm lịch thuốc đầu tiên.',
          style: TextStyle(fontSize: 17, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

class _NoDoseToday extends StatelessWidget {
  const _NoDoseToday();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(Icons.today_rounded, size: 38, color: AppColors.textMuted),
          SizedBox(width: 14),
          Expanded(child: Text('Không có liều thuốc trong hôm nay.')),
        ],
      ),
    ),
  );
}

class _FutureScheduleCard extends StatelessWidget {
  const _FutureScheduleCard({required this.schedule});

  final PillSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final times = schedule.timesInMinutes
        .map((minute) => _formatTime(minute ~/ 60, minute % 60))
        .join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: const CircleAvatar(
          radius: 29,
          backgroundColor: Color(0xFFDCE8FF),
          child: Icon(Icons.event_available_rounded, color: AppColors.primary),
        ),
        title: Text(
          schedule.medicationName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Bắt đầu ${_formatDate(schedule.startDate)} • $times\n'
          '${schedule.dosage} • ${schedule.instruction}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Không thể tải dữ liệu thuốc:\n$error'),
    ),
  );
}

String _formatTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
