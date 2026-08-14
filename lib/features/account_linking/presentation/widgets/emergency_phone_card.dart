import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';

class EmergencyPhoneCard extends StatelessWidget {
  const EmergencyPhoneCard({super.key});

  static const number = '115';

  Future<void> _confirmCall(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.local_hospital_rounded,
          color: AppColors.danger,
          size: 54,
        ),
        title: const Text(
          'Gọi cấp cứu 115?',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Chỉ gọi 115 khi cần hỗ trợ y tế khẩn cấp.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Hủy'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Gọi 115'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final launched = await launchUrl(Uri(scheme: 'tel', path: number));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiết bị không thể thực hiện cuộc gọi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF0F0),
    child: InkWell(
      onTap: () => _confirmCall(context),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 31,
              backgroundColor: AppColors.danger,
              child: Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cấp cứu y tế',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Số điện thoại khẩn cấp 115',
                    style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(104, 50),
              ),
              onPressed: () => _confirmCall(context),
              icon: const Icon(Icons.phone_rounded),
              label: const Text(
                '115',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
