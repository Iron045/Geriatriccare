import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../medication/domain/entities/scheduled_medication_dose.dart';
import '../../../medication/presentation/providers/medication_providers.dart';
import '../../../sos/presentation/pages/sos_countdown_page.dart';

class ElderHomePage extends ConsumerStatefulWidget {
  const ElderHomePage({
    super.key,
    this.userId,
    required this.onViewMedication,
    required this.onOpenMedication,
    required this.onOpenHealth,
  });
  final String? userId;
  final VoidCallback onViewMedication;
  final VoidCallback onOpenMedication;
  final VoidCallback onOpenHealth;

  @override
  ConsumerState<ElderHomePage> createState() => _ElderHomePageState();
}

class _ElderHomePageState extends ConsumerState<ElderHomePage> {
  Timer? _holdTimer;
  bool _holding = false;

  Future<void> _confirmAndSendSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 58,
        ),
        title: const Text(
          'Xác nhận gửi cảnh báo?',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Cảnh báo khẩn cấp sẽ được gửi ngay đến người thân đã liên kết.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.notifications_active_rounded),
            label: const Text('Gửi cảnh báo'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SosCountdownPage(elderId: widget.userId!),
      ),
    );
  }

  void _startSosHold() {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy tài khoản Elder.')),
      );
      return;
    }
    setState(() => _holding = true);
    _holdTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _holding = false);
      _confirmAndSendSos();
    });
  }

  void _cancelSosHold() {
    _holdTimer?.cancel();
    if (mounted) setState(() => _holding = false);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.userId == null
        ? null
        : ref.watch(currentProfileProvider(widget.userId!)).asData?.value;
    final honorific = profile?.gender.elderHonorific ?? 'Người cao tuổi';
    final displayName = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName.trim()
        : 'bạn';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chào buổi sáng, $honorific $displayName',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Thứ Tư, 05 tháng 8 • 07:53',
              style: TextStyle(fontSize: 19, color: AppColors.textMuted),
            ),
            const SizedBox(height: 46),
            Center(
              child: Semantics(
                button: true,
                label:
                    'Gọi khẩn cấp. Nhấn giữ một phẩy năm giây để gửi cảnh báo.',
                child: GestureDetector(
                  onLongPressStart: (_) => _startSosHold(),
                  onLongPressEnd: (_) {
                    if (_holdTimer?.isActive ?? false) _cancelSosHold();
                  },
                  onLongPressCancel: _cancelSosHold,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _holding ? 270 : 250,
                    height: _holding ? 270 : 250,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: .25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 76,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'GỌI KHẨN\nCẤP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nhấn giữ 1,5 giây để gửi cảnh báo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            if (widget.userId == null)
              _FallbackMedicationSummary(onView: widget.onViewMedication)
            else
              _FirebaseMedicationSummary(onView: widget.onViewMedication),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: _Shortcut(
                    icon: Icons.medication,
                    label: 'Uống thuốc',
                    background: const Color(0xFFD8E6FF),
                    foreground: AppColors.primary,
                    onTap: widget.onOpenMedication,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _Shortcut(
                    icon: Icons.monitor_heart,
                    label: 'Ghi sức khỏe',
                    background: AppColors.success,
                    foreground: Colors.white,
                    onTap: widget.onOpenHealth,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FirebaseMedicationSummary extends ConsumerWidget {
  const _FirebaseMedicationSummary({required this.onView});
  final VoidCallback onView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(medicationSchedulesProvider);
    final intakes = ref.watch(todayMedicationIntakesProvider);
    if (schedules.isLoading || intakes.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final scheduleItems = schedules.value ?? const [];
    final intakeItems = intakes.value ?? const [];
    final doses = buildMedicationDosesForDay(scheduleItems, DateTime.now());
    final pending = doses.where(
      (dose) => !intakeItems.any(
        (intake) =>
            intake.scheduleId == dose.schedule.id &&
            intake.scheduledAt.hour == dose.scheduledAt.hour &&
            intake.scheduledAt.minute == dose.scheduledAt.minute,
      ),
    );
    if (pending.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Color(0xFFD8F7E3),
                  child: Icon(Icons.check, color: AppColors.success),
                ),
                title: Text(
                  'Không còn liều thuốc cần uống',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Lịch thuốc hôm nay đã hoàn thành.'),
              ),
              FilledButton.tonal(
                onPressed: onView,
                child: const Center(child: Text('Xem lịch thuốc')),
              ),
            ],
          ),
        ),
      );
    }
    final dose = pending.first;
    final remaining = dose.scheduledAt.difference(DateTime.now());
    final isUpcoming = !remaining.isNegative && remaining.inMinutes <= 30;
    final isOverdue = remaining.isNegative;
    final time =
        '${dose.scheduledAt.hour.toString().padLeft(2, '0')}:'
        '${dose.scheduledAt.minute.toString().padLeft(2, '0')}';
    final timeLabel = isUpcoming
        ? '$time (Sắp tới)'
        : isOverdue
        ? '$time (Đã quá giờ)'
        : time;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFD9D9),
                  child: Icon(Icons.medication, color: AppColors.danger),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dose.schedule.dosage} ${dose.schedule.medicationName}',
                        style: const TextStyle(fontSize: 19),
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 23,
                          color: isUpcoming || isOverdue
                              ? const Color(0xFFC82020)
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onView,
              child: const Center(child: Text('Xem thuốc')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackMedicationSummary extends StatelessWidget {
  const _FallbackMedicationSummary({required this.onView});
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Icon(Icons.medication_outlined)),
            title: Text('Lịch uống thuốc'),
          ),
          FilledButton(
            onPressed: onView,
            child: const Center(child: Text('Xem thuốc')),
          ),
        ],
      ),
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        height: 170,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 58, color: foreground),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: foreground),
            ),
          ],
        ),
      ),
    ),
  );
}
