import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../health/presentation/pages/elder_health_page.dart';
import '../../../medication/presentation/pages/elder_medication_page.dart';

enum CareTab { medication, healthJournal }

class ElderCarePage extends StatelessWidget {
  const ElderCarePage({super.key, required this.initialTab});

  final CareTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey(initialTab),
      length: 2,
      initialIndex: initialTab.index,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: DecoratedBox(
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
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: const [
                    Tab(
                      height: 64,
                      icon: Icon(Icons.medication_rounded),
                      text: 'Thuốc của tôi',
                    ),
                    Tab(
                      height: 64,
                      icon: Icon(Icons.monitor_heart_rounded),
                      text: 'Nhật ký sức khỏe',
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [ElderMedicationPage(), ElderHealthPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
