import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/medication_history_entry.dart';
import '../providers/medication_providers.dart';

class MedicationHistorySection extends ConsumerStatefulWidget {
  const MedicationHistorySection({super.key, required this.elderId});

  final String elderId;

  @override
  ConsumerState<MedicationHistorySection> createState() =>
      _MedicationHistorySectionState();
}

class _MedicationHistorySectionState
    extends ConsumerState<MedicationHistorySection> {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.invalidate(medicationHistorySyncProvider(widget.elderId));
    });
  }

  @override
  void didUpdateWidget(covariant MedicationHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elderId != widget.elderId) {
      ref.invalidate(medicationHistorySyncProvider(widget.elderId));
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(medicationHistorySyncProvider(widget.elderId));
    final history = ref.watch(medicationHistoryProvider(widget.elderId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        Text(
          'Lịch sử uống thuốc',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Liều chưa xác nhận sau 5 giờ được ghi nhận là bỏ lỡ.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        history.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text('Không thể tải lịch sử thuốc: $error'),
            ),
          ),
          data: (items) => items.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Chưa có lịch sử uống thuốc.')),
                  ),
                )
              : Column(
                  children: items
                      .take(30)
                      .map((entry) => _HistoryCard(entry: entry))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final MedicationHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final missed = entry.status == MedicationHistoryStatus.missed;
    final color = missed ? AppColors.danger : AppColors.success;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .13),
          child: Icon(
            missed ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: color,
          ),
        ),
        title: Text(
          entry.medicationName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Liều lượng: ${entry.dosage}\n'
          'Ngày uống: ${_formatDateTime(entry.scheduledAt)}'
          '${entry.takenAt == null ? '' : '\nUống lúc ${_formatTime(entry.takenAt!)}'}',
        ),
        isThreeLine: true,
        trailing: Chip(
          side: BorderSide.none,
          backgroundColor: color.withValues(alpha: .13),
          label: Text(
            missed ? 'Bỏ lỡ' : 'Đã uống',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year} • '
    '${_formatTime(value)}';

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
