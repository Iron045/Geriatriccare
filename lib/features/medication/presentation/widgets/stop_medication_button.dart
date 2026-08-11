import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/pill_schedule.dart';
import '../providers/medication_providers.dart';

class StopMedicationButton extends ConsumerStatefulWidget {
  const StopMedicationButton({
    super.key,
    required this.schedule,
    this.compact = false,
  });

  final PillSchedule schedule;
  final bool compact;

  @override
  ConsumerState<StopMedicationButton> createState() =>
      _StopMedicationButtonState();
}

class _StopMedicationButtonState extends ConsumerState<StopMedicationButton> {
  bool _loading = false;

  Future<void> _stop() async {
    if (_loading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.medication_liquid_rounded,
          color: AppColors.danger,
          size: 48,
        ),
        title: const Text('Xóa lịch thuốc?'),
        content: Text(
          'Lịch ${widget.schedule.medicationName} sẽ bị xóa khỏi Firebase và các thông báo chưa đến hạn sẽ bị hủy. Lịch sử đã uống vẫn được giữ lại.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa thuốc'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(medicationRepositoryProvider)
          .deleteSchedule(
            scheduleId: widget.schedule.id,
            elderId: widget.schedule.elderUserId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${widget.schedule.medicationName}.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa thuốc: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.stop_circle_outlined);
    if (widget.compact) {
      return IconButton(
        onPressed: _loading ? null : _stop,
        color: AppColors.danger,
        tooltip: 'Ngừng và xóa thuốc',
        icon: icon,
      );
    }
    return TextButton.icon(
      onPressed: _loading ? null : _stop,
      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
      icon: icon,
      label: const Text('Ngừng thuốc'),
    );
  }
}
