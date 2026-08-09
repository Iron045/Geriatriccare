import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/health_record.dart';
import '../providers/health_providers.dart';
import 'record_blood_pressure_page.dart';

class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(healthRecordsProvider);
    return SafeArea(
      child: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không thể tải nhật ký sức khỏe:\n$error'),
          ),
        ),
        data: (items) => _HealthContent(records: items),
      ),
    );
  }
}

class _HealthContent extends ConsumerWidget {
  const _HealthContent({required this.records});
  final List<HealthRecord> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartRecords = records.take(7).toList().reversed.toList();
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(healthRecordsProvider),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nhật ký Sức khỏe',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const RecordBloodPressurePage(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ghi chỉ số'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Dữ liệu huyết áp được đồng bộ theo thời gian thực.',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
          const SizedBox(height: 26),
          if (records.isEmpty)
            const _EmptyHealthState()
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Huyết áp ${chartRecords.length} lần đo gần nhất',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 210,
                      child: CustomPaint(
                        painter: _BloodPressureChartPainter(chartRecords),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        _Legend(color: Color(0xFFF04444), text: 'Tâm thu'),
                        _Legend(
                          color: AppColors.primaryBright,
                          text: 'Tâm trương',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Lịch sử đo gần nhất',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...records.map((record) => _RecordCard(record: record)),
          ],
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});
  final HealthRecord record;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: record.isAbnormal
            ? const Color(0xFFFFEEEE)
            : AppColors.surfaceMuted,
        child: Icon(
          Icons.favorite,
          color: record.isAbnormal
              ? const Color(0xFFF04444)
              : const Color(0xFF9BABBF),
        ),
      ),
      title: Text(
        '${record.systolic} / ${record.diastolic} mmHg',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${record.status.title}\n${_formatDateTime(record.recordedAt)}'
        '${record.hasBeenContacted ? '\n✓ Đã liên hệ ${_formatDateTime(record.contactedAt!)}' : ''}',
        style: const TextStyle(fontSize: 16),
      ),
      isThreeLine: record.hasBeenContacted,
      trailing: Icon(
        record.isAbnormal ? Icons.warning_rounded : Icons.check_circle,
        color: record.isAbnormal ? AppColors.danger : const Color(0xFF20C66A),
        size: 34,
      ),
    ),
  );
}

class _EmptyHealthState extends StatelessWidget {
  const _EmptyHealthState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        const Icon(
          Icons.monitor_heart_outlined,
          size: 88,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: 18),
        Text(
          'Chưa có chỉ số huyết áp',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhấn “Ghi chỉ số” để lưu lần đo đầu tiên.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, color: color, size: 16),
      const SizedBox(width: 8),
      Text(text),
    ],
  );
}

class _BloodPressureChartPainter extends CustomPainter {
  const _BloodPressureChartPainter(this.records);
  final List<HealthRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE2E6ED)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    _drawSeries(
      canvas,
      size,
      records.map((record) => record.systolic).toList(),
      const Color(0xFFF04444),
    );
    _drawSeries(
      canvas,
      size,
      records.map((record) => record.diastolic).toList(),
      AppColors.primaryBright,
    );
  }

  void _drawSeries(Canvas canvas, Size size, List<int> values, Color color) {
    if (values.isEmpty) return;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final normalized = ((values[i] - 40) / 180).clamp(0.0, 1.0);
      final point = Offset(x, size.height - normalized * size.height);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawCircle(point, 5.5, Paint()..color = color);
    }
    if (values.length > 1) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BloodPressureChartPainter oldDelegate) {
    if (records.length != oldDelegate.records.length) return true;
    return !List.generate(
      records.length,
      (index) =>
          records[index].systolic == oldDelegate.records[index].systolic &&
          records[index].diastolic == oldDelegate.records[index].diastolic,
    ).every((same) => same);
  }
}

String _formatDateTime(DateTime value) {
  final now = DateTime.now();
  final date = DateTime(value.year, value.month, value.day);
  final today = DateTime(now.year, now.month, now.day);
  final dayLabel = date == today
      ? 'Hôm nay'
      : date == today.subtract(const Duration(days: 1))
      ? 'Hôm qua'
      : '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/${value.year}';
  return '$dayLabel, ${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
