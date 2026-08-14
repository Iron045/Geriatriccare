import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class LiveGreeting extends StatefulWidget {
  const LiveGreeting({
    super.key,
    required this.displayName,
    this.showDateTime = false,
    this.subtitle,
  });

  final String displayName;
  final bool showDateTime;
  final String? subtitle;

  @override
  State<LiveGreeting> createState() => _LiveGreetingState();
}

class _LiveGreetingState extends State<LiveGreeting> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Chào buổi ${_periodLabel(_now.hour)}, ${widget.displayName}',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      if (widget.showDateTime) ...[
        const SizedBox(height: 12),
        Text(
          _formatDateTime(_now),
          style: const TextStyle(fontSize: 19, color: AppColors.textMuted),
        ),
      ],
      if (widget.subtitle case final subtitle?) ...[
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 18, color: AppColors.textMuted),
        ),
      ],
    ],
  );
}

String _periodLabel(int hour) {
  if (hour >= 5 && hour < 12) return 'sáng';
  if (hour >= 12 && hour < 18) return 'chiều';
  return 'tối';
}

String _formatDateTime(DateTime value) {
  const weekdays = <String>[
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${weekdays[value.weekday - 1]}, '
      '${value.day.toString().padLeft(2, '0')} tháng ${value.month} '
      '• $hour:$minute';
}
