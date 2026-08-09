import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppBrand extends StatelessWidget {
  const AppBrand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 44 : 58,
          height: compact ? 44 : 58,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.monitor_heart_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          'Geriatric Care',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: compact ? 28 : 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
