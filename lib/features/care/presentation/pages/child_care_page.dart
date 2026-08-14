import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../account_linking/domain/entities/account_link_request.dart';
import '../../../account_linking/presentation/providers/account_link_providers.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../health/domain/entities/health_record.dart';
import '../../../health/presentation/providers/health_providers.dart';
import '../../../medication/domain/entities/medication_intake.dart';
import '../../../medication/domain/entities/pill_schedule.dart';
import '../../../medication/domain/entities/scheduled_medication_dose.dart';
import '../../../medication/presentation/providers/medication_providers.dart';
import '../../../medication/presentation/widgets/stop_medication_button.dart';
import '../../../medication/presentation/widgets/medication_history_section.dart';

class ChildCarePage extends ConsumerWidget {
  const ChildCarePage({super.key, required this.user, this.initialTab = 0});

  final AppUser user;
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(childAccountLinksProvider(user.phoneNumber));
    return links.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Không thể tải dữ liệu sức khỏe',
        message: error.toString(),
      ),
      data: (items) {
        final accepted = items.where(
          (link) =>
              link.status == LinkRequestStatus.accepted &&
              link.childId == user.id,
        );
        if (accepted.isEmpty) {
          return const _MessageState(
            icon: Icons.link_off_rounded,
            title: 'Chưa liên kết người thân',
            message:
                'Hãy chấp nhận yêu cầu liên kết từ tài khoản người cao tuổi để xem thuốc và nhật ký sức khỏe.',
          );
        }
        return _ChildCareTabs(link: accepted.first, initialTab: initialTab);
      },
    );
  }
}

class _ChildCareTabs extends ConsumerWidget {
  const _ChildCareTabs({required this.link, required this.initialTab});

  final AccountLinkRequest link;
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elderProfile = ref.watch(currentProfileProvider(link.elderId));
    final gender =
        elderProfile.asData?.value?.gender ??
        userGenderFromName(link.elderGender);
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sức khỏe ${gender.parentRelationship} ${link.elderName}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      tabs: const [
                        Tab(
                          height: 60,
                          icon: Icon(Icons.medication_rounded),
                          text: 'Danh sách thuốc',
                        ),
                        Tab(
                          height: 60,
                          icon: Icon(Icons.monitor_heart_rounded),
                          text: 'Nhật ký sức khỏe',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ChildMedicationTab(elderId: link.elderId),
                  _ChildHealthJournalTab(elderId: link.elderId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildMedicationTab extends ConsumerWidget {
  const _ChildMedicationTab({required this.elderId});

  final String elderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(medicationSchedulesForElderProvider(elderId));
    final intakes = ref.watch(todayMedicationIntakesForElderProvider(elderId));
    return schedules.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _MessageState(
        icon: Icons.medication_outlined,
        title: 'Không thể tải danh sách thuốc',
        message: error.toString(),
      ),
      data: (items) => intakes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageState(
          icon: Icons.medication_outlined,
          title: 'Không thể tải trạng thái uống thuốc',
          message: error.toString(),
        ),
        data: (logs) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final doses = buildMedicationDosesForDay(items, now);
          final futureSchedules = items.where((schedule) {
            final start = DateTime(
              schedule.startDate.year,
              schedule.startDate.month,
              schedule.startDate.day,
            );
            return start.isAfter(today);
          }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(medicationSchedulesForElderProvider(elderId));
              ref.invalidate(todayMedicationIntakesForElderProvider(elderId));
              ref.invalidate(medicationHistorySyncProvider(elderId));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lịch uống thuốc hôm nay',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => _showAddMedication(context, ref),
                      tooltip: 'Thêm thuốc cho người thân',
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Theo dõi trạng thái uống thuốc của người thân theo thời gian thực.',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                if (items.isEmpty)
                  const _MessageCard(
                    icon: Icons.medication_outlined,
                    text: 'Người thân chưa có lịch uống thuốc.',
                  )
                else if (doses.isEmpty)
                  const _MessageCard(
                    icon: Icons.today_rounded,
                    text: 'Không có liều thuốc trong hôm nay.',
                  )
                else
                  ...doses.map(
                    (dose) => _MedicationCard(
                      dose: dose,
                      intake: _findIntake(dose, logs),
                    ),
                  ),
                if (futureSchedules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Lịch sắp tới',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ...futureSchedules.map(
                    (schedule) => _UpcomingMedicationCard(schedule: schedule),
                  ),
                ],
                MedicationHistorySection(elderId: elderId),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddMedication(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final instruction = TextEditingController(text: 'Uống sau ăn');
    var quantity = 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var date = today;
    var time = TimeOfDay.now();
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm thuốc cho người thân'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Tên thuốc',
                      prefixIcon: Icon(Icons.medication_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập tên thuốc'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Liều lượng',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filledTonal(
                          onPressed: quantity > 1
                              ? () => setDialogState(() => quantity--)
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        Text(
                          '$quantity viên',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: quantity < 20
                              ? () => setDialogState(() => quantity++)
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: instruction,
                    decoration: const InputDecoration(
                      labelText: 'Hướng dẫn sử dụng',
                      prefixIcon: Icon(Icons.restaurant_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_rounded),
                    title: const Text('Ngày bắt đầu uống'),
                    trailing: Text(
                      _date(date),
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
                      _time(DateTime(2000, 1, 1, time.hour, time.minute)),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Lưu thuốc'),
            ),
          ],
        ),
      ),
    );
    if (save == true && context.mounted) {
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
        ref.invalidate(medicationSchedulesForElderProvider(elderId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm thuốc cho người thân.')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể thêm thuốc: $error')),
          );
        }
      }
    }
    name.dispose();
    instruction.dispose();
  }

  MedicationIntake? _findIntake(
    ScheduledMedicationDose dose,
    List<MedicationIntake> intakes,
  ) {
    for (final intake in intakes) {
      if (intake.scheduleId == dose.schedule.id &&
          intake.scheduledAt.year == dose.scheduledAt.year &&
          intake.scheduledAt.month == dose.scheduledAt.month &&
          intake.scheduledAt.day == dose.scheduledAt.day &&
          intake.scheduledAt.hour == dose.scheduledAt.hour &&
          intake.scheduledAt.minute == dose.scheduledAt.minute) {
        return intake;
      }
    }
    return null;
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.dose, required this.intake});

  final ScheduledMedicationDose dose;
  final MedicationIntake? intake;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final taken = intake != null;
    final missed =
        !taken &&
        now.isAfter(dose.scheduledAt.add(const Duration(hours: 5)));
    final upcoming =
        !taken &&
        !missed &&
        dose.scheduledAt.isAfter(now) &&
        dose.scheduledAt.difference(now) <= const Duration(minutes: 30);
    final color = taken
        ? AppColors.success
        : missed
        ? AppColors.danger
        : AppColors.primary;
    final status = taken
        ? 'Đã uống lúc ${_time(intake!.takenAt)}'
        : missed
        ? 'Đã bỏ lỡ'
        : upcoming
        ? 'Sắp tới trong ${dose.scheduledAt.difference(now).inMinutes + 1} phút'
        : 'Chưa đến giờ';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                taken ? Icons.check_rounded : Icons.medication_rounded,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_date(dose.scheduledAt)} • ${_time(dose.scheduledAt)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    dose.schedule.medicationName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${dose.schedule.dosage} • ${dose.schedule.instruction}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                  StopMedicationButton(schedule: dose.schedule),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingMedicationCard extends StatelessWidget {
  const _UpcomingMedicationCard({required this.schedule});

  final PillSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final times = schedule.timesInMinutes
        .map(
          (minute) =>
              '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}',
        )
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
          'Bắt đầu ${_date(schedule.startDate)} • $times\n'
          '${schedule.dosage} • ${schedule.instruction}',
        ),
        isThreeLine: true,
        trailing: StopMedicationButton(schedule: schedule, compact: true),
      ),
    );
  }
}

class _ChildHealthJournalTab extends ConsumerWidget {
  const _ChildHealthJournalTab({required this.elderId});

  final String elderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(healthRecordsForElderProvider(elderId));
    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _MessageState(
        icon: Icons.monitor_heart_outlined,
        title: 'Không thể tải nhật ký sức khỏe',
        message: error.toString(),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(healthRecordsForElderProvider(elderId)),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Nhật ký huyết áp',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Các chỉ số gần nhất.',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const _MessageCard(
                icon: Icons.monitor_heart_outlined,
                text: 'Người thân chưa ghi chỉ số huyết áp.',
              )
            else ...[
              _BloodPressureChart(
                records: items.take(7).toList().reversed.toList(),
              ),
              const SizedBox(height: 22),
              Text(
                'Lịch sử đo gần nhất',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ...items.map((record) => _HealthRecordCard(record: record)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BloodPressureChart extends StatelessWidget {
  const _BloodPressureChart({required this.records});

  final List<HealthRecord> records;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Huyết áp ${records.length} lần đo gần nhất',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 190,
            child: CustomPaint(
              painter: _ChildBloodPressurePainter(records),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 20,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ChartLegend(color: AppColors.danger, label: 'Tâm thu'),
              _ChartLegend(color: AppColors.primary, label: 'Tâm trương'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 15, color: color),
      const SizedBox(width: 7),
      Text(label),
    ],
  );
}

class _ChildBloodPressurePainter extends CustomPainter {
  const _ChildBloodPressurePainter(this.records);

  final List<HealthRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE1E6EE)
      ..strokeWidth = 1.4;
    for (var index = 0; index < 5; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    _drawLine(
      canvas,
      size,
      records.map((record) => record.systolic).toList(),
      AppColors.danger,
      labelAbove: true,
    );
    _drawLine(
      canvas,
      size,
      records.map((record) => record.diastolic).toList(),
      AppColors.primary,
      labelAbove: false,
    );
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<int> values,
    Color color, {
    required bool labelAbove,
  }) {
    if (values.isEmpty) return;
    final path = Path();
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final normalized = ((values[index] - 40) / 180).clamp(0.0, 1.0);
      final point = Offset(x, size.height - normalized * size.height);
      points.add(point);
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    if (points.length > 1) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], 5, Paint()..color = color);
      _drawValueLabel(
        canvas,
        size,
        points[index],
        values[index],
        color,
        labelAbove,
      );
    }
  }

  void _drawValueLabel(
    Canvas canvas,
    Size size,
    Offset point,
    int value,
    Color color,
    bool labelAbove,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const padding = EdgeInsets.symmetric(horizontal: 5, vertical: 2);
    final labelSize = Size(
      textPainter.width + padding.horizontal,
      textPainter.height + padding.vertical,
    );
    var left = point.dx - labelSize.width / 2;
    left = left.clamp(0.0, size.width - labelSize.width).toDouble();
    var top = labelAbove ? point.dy - labelSize.height - 8 : point.dy + 8;
    top = top.clamp(0.0, size.height - labelSize.height).toDouble();
    final rect = Rect.fromLTWH(left, top, labelSize.width, labelSize.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    textPainter.paint(canvas, Offset(left + padding.left, top + padding.top));
  }

  @override
  bool shouldRepaint(covariant _ChildBloodPressurePainter oldDelegate) =>
      oldDelegate.records != records;
}

class _HealthRecordCard extends StatelessWidget {
  const _HealthRecordCard({required this.record});

  final HealthRecord record;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: CircleAvatar(
        radius: 29,
        backgroundColor: record.isAbnormal
            ? const Color(0xFFFFEEEE)
            : AppColors.surfaceMuted,
        child: Icon(
          Icons.favorite,
          color: record.isAbnormal ? AppColors.danger : AppColors.primary,
        ),
      ),
      title: Text(
        '${record.systolic} / ${record.diastolic} mmHg',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${record.status.title}\n${_dateTime(record.recordedAt)}'
        '${record.hasBeenContacted ? '\n✓ Đã liên hệ ${_dateTime(record.contactedAt!)}' : ''}',
      ),
      isThreeLine: record.hasBeenContacted,
      trailing: Icon(
        record.isAbnormal ? Icons.warning_rounded : Icons.check_circle,
        color: record.isAbnormal ? AppColors.danger : AppColors.success,
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 62, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 76, color: AppColors.textMuted),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} • ${_time(value)}';
