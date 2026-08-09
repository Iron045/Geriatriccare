import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_brand.dart';
import '../../../account_linking/presentation/pages/contacts_page.dart';
import '../../../health/presentation/pages/care_page.dart';
import '../../../medication/presentation/pages/medication_reminder_page.dart';
import '../../../medication/data/services/medication_notification_service.dart';
import '../../../profile/presentation/pages/settings_page.dart';
import 'elder_home_page.dart';

class ElderShellPage extends StatefulWidget {
  const ElderShellPage({super.key, this.userId});

  final String? userId;

  @override
  State<ElderShellPage> createState() => _ElderShellPageState();
}

class _ElderShellPageState extends State<ElderShellPage> {
  int _index = 0;
  CareTab _careTab = CareTab.medication;
  StreamSubscription<String>? _reminderOpenedSubscription;

  @override
  void initState() {
    super.initState();
    final notifications = MedicationNotificationService.instance;
    _reminderOpenedSubscription = notifications.reminderOpened.listen(
      (_) => _openMedicationReminder(),
    );
    if (notifications.consumePendingOpen()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openMedicationReminder();
      });
    }
  }

  void _openMedicationReminder() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MedicationReminderPage(),
      ),
    );
  }

  @override
  void dispose() {
    _reminderOpenedSubscription?.cancel();
    super.dispose();
  }

  void _openCare(CareTab tab) {
    setState(() {
      _careTab = tab;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 82,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        titleSpacing: 20,
        title: const AppBrand(compact: true),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                tooltip: 'Thông báo',
                icon: const Icon(Icons.notifications_none_rounded, size: 31),
              ),
              const Positioned(
                right: 10,
                top: 13,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.danger,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => setState(() => _index = 3),
            tooltip: 'Cài đặt',
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          ElderHomePage(
            userId: widget.userId,
            onViewMedication: _openMedicationReminder,
            onOpenMedication: () => _openCare(CareTab.medication),
            onOpenHealth: () => _openCare(CareTab.healthJournal),
          ),
          CarePage(initialTab: _careTab),
          ContactsPage(elderId: widget.userId),
          SettingsPage(userId: widget.userId),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 82,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        indicatorColor: AppColors.primary,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety, color: Colors.white),
            label: 'Sức khỏe',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_phone_outlined),
            selectedIcon: Icon(Icons.contact_phone, color: Colors.white),
            label: 'Liên hệ',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Colors.white),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
