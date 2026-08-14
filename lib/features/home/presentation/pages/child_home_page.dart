import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/live_greeting.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../health/domain/entities/health_record.dart';
import '../../../health/presentation/providers/health_providers.dart';
import '../../../medication/domain/entities/medication_intake.dart';
import '../../../medication/domain/entities/pill_schedule.dart';
import '../../../medication/domain/entities/scheduled_medication_dose.dart';
import '../../../medication/presentation/providers/medication_providers.dart';
import '../../../location/domain/entities/elder_location.dart';
import '../../../location/presentation/providers/elder_location_providers.dart';
import '../../../sos/domain/entities/sos_alert.dart';
import '../../../sos/presentation/providers/sos_providers.dart';

class ChildHomePage extends ConsumerWidget {
  const ChildHomePage({
    super.key,
    required this.childName,
    required this.elderDisplayName,
    required this.elderId,
    required this.elderPhone,
    required this.onOpenMedication,
    required this.onOpenHealth,
    required this.onOpenLinks,
  });

  final String childName;
  final String elderDisplayName;
  final String? elderId;
  final String? elderPhone;
  final VoidCallback onOpenMedication;
  final VoidCallback onOpenHealth;
  final VoidCallback onOpenLinks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = elderId;
    if (id == null) {
      return _UnlinkedHome(childName: childName, onOpenLinks: onOpenLinks);
    }
    final health = ref.watch(healthRecordsForElderProvider(id));
    final schedules = ref.watch(medicationSchedulesForElderProvider(id));
    final intakes = ref.watch(todayMedicationIntakesForElderProvider(id));
    final sosAlerts = ref.watch(activeSosAlertsProvider(id));
    final location = ref.watch(elderLocationProvider(id));
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(healthRecordsForElderProvider(id));
          ref.invalidate(medicationSchedulesForElderProvider(id));
          ref.invalidate(todayMedicationIntakesForElderProvider(id));
          ref.invalidate(elderLocationProvider(id));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            LiveGreeting(
              displayName: childName,
              subtitle: 'Theo dõi sức khỏe người thân của bạn',
            ),
            const SizedBox(height: 26),
            if (sosAlerts.asData?.value.isNotEmpty == true) ...[
              _SosAlertBanner(
                alert: sosAlerts.asData!.value.first,
                elderDisplayName: elderDisplayName,
                phone: elderPhone,
              ),
              const SizedBox(height: 18),
            ],
            _ElderCard(
              displayName: elderDisplayName,
              phone: elderPhone,
              onOpenLinks: onOpenLinks,
            ),
            const SizedBox(height: 18),
            _ElderLocationCard(
              elderDisplayName: elderDisplayName,
              location: location,
            ),
            const SizedBox(height: 28),
            const Text(
              'Tổng quan hôm nay',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _Overview(
              health: health,
              schedules: schedules,
              intakes: intakes,
              onOpenHealth: onOpenHealth,
              onOpenMedication: onOpenMedication,
            ),
            const SizedBox(height: 26),
            _SafetyNotice(
              health: health,
              schedules: schedules,
              intakes: intakes,
            ),
            const SizedBox(height: 28),
            const Text(
              'Hoạt động gần đây',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _RecentActivity(
              health: health,
              schedules: schedules,
              intakes: intakes,
            ),
          ],
        ),
      ),
    );
  }
}

class _ElderLocationCard extends StatelessWidget {
  const _ElderLocationCard({
    required this.elderDisplayName,
    required this.location,
  });

  final String elderDisplayName;
  final AsyncValue<ElderLocation?> location;

  Future<void> _openMap(BuildContext context, ElderLocation value) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${value.latitude},${value.longitude}',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng bản đồ.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = location.asData?.value;
    final loading = location.isLoading;
    final hasError = location.hasError;
    return Card(
      child: InkWell(
        onTap: value == null ? null : () => _openMap(context, value),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFE8F0FF),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vị trí của bố/mẹ',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loading
                          ? 'Đang tải vị trí...'
                          : hasError
                          ? 'Không thể tải vị trí'
                          : value == null
                          ? '$elderDisplayName chưa chia sẻ vị trí'
                          : 'Cập nhật ${_formatDateTime(value.updatedAt)} • sai số ${value.accuracyMeters.round()} m',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  value == null
                      ? Icons.location_off_outlined
                      : Icons.open_in_new_rounded,
                  color: value == null
                      ? AppColors.textMuted
                      : AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosAlertBanner extends ConsumerStatefulWidget {
  const _SosAlertBanner({
    required this.alert,
    required this.elderDisplayName,
    required this.phone,
  });

  final SosAlert alert;
  final String elderDisplayName;
  final String? phone;

  @override
  ConsumerState<_SosAlertBanner> createState() => _SosAlertBannerState();
}

class _SosAlertBannerState extends ConsumerState<_SosAlertBanner> {
  bool loading = false;

  Future<void> acknowledge() async {
    final childId = ref.read(authRepositoryProvider).currentUserId;
    if (childId == null || loading) return;
    setState(() => loading = true);
    try {
      await ref
          .read(sosRepositoryProvider)
          .acknowledgeAlert(alertId: widget.alert.id, childId: childId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận tiếp nhận cảnh báo SOS.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tiếp nhận SOS: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acknowledged = widget.alert.status == SosStatus.acknowledged;
    final color = acknowledged ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                acknowledged
                    ? Icons.verified_user_rounded
                    : Icons.emergency_rounded,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acknowledged ? 'ĐÃ TIẾP NHẬN SOS' : 'CẢNH BÁO SOS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${widget.elderDisplayName} • ${_formatDateTime(widget.alert.triggeredAt)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _showPhoneAction(context, widget.phone, false),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                  ),
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Liên hệ ngay'),
                ),
              ),
              if (!acknowledged) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : acknowledge,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.done_all_rounded),
                    label: const Text('Đã tiếp nhận'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UnlinkedHome extends StatelessWidget {
  const _UnlinkedHome({required this.childName, required this.onOpenLinks});

  final String childName;
  final VoidCallback onOpenLinks;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        LiveGreeting(
          displayName: childName,
        ),
        const SizedBox(height: 48),
        const Icon(
          Icons.link_off_rounded,
          size: 90,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 18),
        Text(
          'Chưa liên kết người thân',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        const Text(
          'Chấp nhận yêu cầu liên kết để theo dõi sức khỏe và lịch uống thuốc.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onOpenLinks,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Mở yêu cầu liên kết'),
        ),
      ],
    ),
  );
}

class _ElderCard extends StatelessWidget {
  const _ElderCard({
    required this.displayName,
    required this.phone,
    required this.onOpenLinks,
  });

  final String displayName;
  final String? phone;
  final VoidCallback onOpenLinks;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFE4F5EA),
                child: Icon(
                  Icons.elderly_rounded,
                  size: 46,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Đã liên kết tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenLinks,
                icon: const Icon(Icons.chevron_right_rounded, size: 34),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.phone_rounded,
                  label: 'Gọi điện',
                  color: AppColors.primary,
                  onPressed: () => _showPhoneAction(context, phone, false),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ContactButton(
                  icon: Icons.message_rounded,
                  label: 'Nhắn tin',
                  color: AppColors.success,
                  onPressed: () => _showPhoneAction(context, phone, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.health,
    required this.schedules,
    required this.intakes,
    required this.onOpenHealth,
    required this.onOpenMedication,
  });

  final AsyncValue<List<HealthRecord>> health;
  final AsyncValue<List<PillSchedule>> schedules;
  final AsyncValue<List<MedicationIntake>> intakes;
  final VoidCallback onOpenHealth;
  final VoidCallback onOpenMedication;

  @override
  Widget build(BuildContext context) {
    final records = health.asData?.value ?? const <HealthRecord>[];
    final latest = records.isEmpty ? null : records.first;
    final scheduleItems = schedules.asData?.value ?? const <PillSchedule>[];
    final doses = buildMedicationDosesForDay(scheduleItems, DateTime.now());
    final logs = intakes.asData?.value ?? const <MedicationIntake>[];
    final takenDoseCount = doses
        .where((dose) => logs.any((intake) => _matches(intake, dose)))
        .length;
    final medicationTitle = schedules.isLoading || intakes.isLoading
        ? '-- / -- liều'
        : '$takenDoseCount / ${doses.length} liều';
    final bpTitle = latest == null
        ? '-- / --'
        : '${latest.systolic} / ${latest.diastolic}';
    final bpSubtitle = latest == null
        ? 'Chưa có huyết áp'
        : latest.status.title;
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.favorite_rounded,
              iconColor: latest?.isAbnormal == true
                  ? AppColors.danger
                  : AppColors.success,
              title: bpTitle,
              subtitle: bpSubtitle,
              onTap: onOpenHealth,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SummaryCard(
              icon: Icons.medication_rounded,
              iconColor: AppColors.primary,
              title: medicationTitle,
              subtitle: 'Đã uống hôm nay',
              onTap: onOpenMedication,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyNotice extends ConsumerWidget {
  const _SafetyNotice({
    required this.health,
    required this.schedules,
    required this.intakes,
  });

  final AsyncValue<List<HealthRecord>> health;
  final AsyncValue<List<PillSchedule>> schedules;
  final AsyncValue<List<MedicationIntake>> intakes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = health.asData?.value ?? const <HealthRecord>[];
    final latest = records.isEmpty ? null : records.first;
    final scheduleItems = schedules.asData?.value ?? const <PillSchedule>[];
    final doses = buildMedicationDosesForDay(scheduleItems, DateTime.now());
    final logs = intakes.asData?.value ?? const <MedicationIntake>[];
    final missed = doses.where((dose) {
      final taken = logs.any((log) => _matches(log, dose));
      return !taken &&
          DateTime.now().isAfter(
            dose.scheduledAt.add(const Duration(hours: 5)),
          );
    }).length;
    final healthNeedsContact =
        latest?.status.needsAttention == true &&
        latest?.hasBeenContacted == false;
    final warning = healthNeedsContact || missed > 0;
    final title = healthNeedsContact
        ? latest!.status.title
        : missed > 0
        ? 'Có $missed liều thuốc bị bỏ lỡ'
        : latest?.hasBeenContacted == true
        ? 'Đã liên hệ người thân'
        : 'Không có cảnh báo sức khỏe';
    final subtitle = healthNeedsContact || missed > 0
        ? 'Vui lòng kiểm tra và liên hệ người thân.'
        : latest?.hasBeenContacted == true
        ? 'Đã xác nhận lúc ${_formatDateTime(latest!.contactedAt!)}.'
        : 'Các dữ liệu gần nhất đang trong phạm vi an toàn.';
    final color = latest?.hasBeenContacted == true && missed == 0
        ? AppColors.success
        : warning
        ? AppColors.danger
        : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .30)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(
              warning ? Icons.warning_rounded : Icons.shield_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 15)),
                if (healthNeedsContact) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        _markBloodPressureAsContacted(context, ref, latest!),
                    style: FilledButton.styleFrom(backgroundColor: color),
                    icon: const Icon(Icons.phone_in_talk_rounded),
                    label: const Text('Đã liên hệ'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({
    required this.health,
    required this.schedules,
    required this.intakes,
  });

  final AsyncValue<List<HealthRecord>> health;
  final AsyncValue<List<PillSchedule>> schedules;
  final AsyncValue<List<MedicationIntake>> intakes;

  @override
  Widget build(BuildContext context) {
    final records = health.asData?.value ?? const <HealthRecord>[];
    final logs = intakes.asData?.value ?? const <MedicationIntake>[];
    final scheduleItems = schedules.asData?.value ?? const <PillSchedule>[];
    if (records.isEmpty && logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa có hoạt động sức khỏe gần đây.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final activities = <_Activity>[];
    if (logs.isNotEmpty) {
      final latest = logs.reduce(
        (a, b) => a.takenAt.isAfter(b.takenAt) ? a : b,
      );
      String medicineName = 'thuốc';
      for (final schedule in scheduleItems) {
        if (schedule.id == latest.scheduleId) {
          medicineName = schedule.medicationName;
          break;
        }
      }
      activities.add(
        _Activity(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          title: 'Đã uống $medicineName',
          date: latest.takenAt,
        ),
      );
    }
    if (records.isNotEmpty) {
      final latest = records.first;
      activities.add(
        _Activity(
          icon: Icons.favorite_rounded,
          color: latest.status.needsAttention
              ? AppColors.danger
              : AppColors.primary,
          title: 'Đã ghi huyết áp ${latest.systolic}/${latest.diastolic} mmHg',
          date: latest.recordedAt,
        ),
      );
    }
    activities.sort((a, b) => b.date.compareTo(a.date));
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < activities.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 74),
            _ActivityTile(activity: activities[index]),
          ],
        ],
      ),
    );
  }
}

class _Activity {
  const _Activity({
    required this.icon,
    required this.color,
    required this.title,
    required this.date,
  });

  final IconData icon;
  final Color color;
  final String title;
  final DateTime date;
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(backgroundColor: color),
    icon: Icon(icon),
    label: Text(label),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 168),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 38),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final _Activity activity;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    leading: CircleAvatar(
      backgroundColor: activity.color.withValues(alpha: .14),
      child: Icon(activity.icon, color: activity.color),
    ),
    title: Text(
      activity.title,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(_formatDateTime(activity.date)),
  );
}

bool _matches(MedicationIntake intake, ScheduledMedicationDose dose) =>
    intake.scheduleId == dose.schedule.id &&
    intake.scheduledAt.year == dose.scheduledAt.year &&
    intake.scheduledAt.month == dose.scheduledAt.month &&
    intake.scheduledAt.day == dose.scheduledAt.day &&
    intake.scheduledAt.hour == dose.scheduledAt.hour &&
    intake.scheduledAt.minute == dose.scheduledAt.minute;

Future<void> _markBloodPressureAsContacted(
  BuildContext context,
  WidgetRef ref,
  HealthRecord record,
) async {
  final childId = ref.read(authRepositoryProvider).currentUserId;
  if (childId == null || record.id.isEmpty) return;
  try {
    await ref
        .read(healthRepositoryProvider)
        .markAsContacted(recordId: record.id, childId: childId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận liên hệ với người thân.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật trạng thái: $error')),
      );
    }
  }
}

String _formatDateTime(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final valueDay = DateTime(date.year, date.month, date.day);
  final day = valueDay == today
      ? 'Hôm nay'
      : valueDay == today.subtract(const Duration(days: 1))
      ? 'Hôm qua'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  return '$day, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

Future<void> _showPhoneAction(
  BuildContext context,
  String? phone,
  bool message,
) async {
  if (phone == null || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Người thân chưa có số điện thoại.')),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message ? Icons.message_rounded : Icons.phone_rounded,
              size: 52,
              color: message ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              message ? 'Nhắn tin cho người thân' : 'Gọi cho người thân',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(phone, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: phone));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép số điện thoại.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Sao chép số điện thoại'),
            ),
          ],
        ),
      ),
    ),
  );
}
