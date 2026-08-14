import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_brand.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../account_linking/presentation/pages/child_account_linking_page.dart';
import '../../../account_linking/domain/entities/account_link_request.dart';
import '../../../account_linking/presentation/providers/account_link_providers.dart';
import '../../../profile/presentation/pages/settings_page.dart';
import '../../../medication/presentation/widgets/medication_notification_sync.dart';
import '../../../medication/data/services/medication_notification_service.dart';
import '../../../notifications/data/services/push_notification_service.dart';
import '../../../sos/presentation/providers/sos_providers.dart';
import '../../../sos/domain/entities/sos_alert.dart';
import '../../../sos/presentation/pages/child_sos_alert_page.dart';
import '../../../care/presentation/pages/child_care_page.dart';
import '../../../home/presentation/pages/child_home_page.dart';

class ChildNavigationPage extends ConsumerStatefulWidget {
  const ChildNavigationPage({super.key, required this.user});
  final AppUser user;

  @override
  ConsumerState<ChildNavigationPage> createState() =>
      _ChildNavigationPageState();
}

class _ChildNavigationPageState extends ConsumerState<ChildNavigationPage> {
  int _index = 0;
  int _healthTab = 0;
  final Set<String> _presentedSosIds = <String>{};
  bool _sosScreenOpen = false;
  StreamSubscription<String>? _notificationOpenedSubscription;
  StreamSubscription<String>? _medicationReminderSubscription;

  @override
  void initState() {
    super.initState();
    final notifications = PushNotificationService.instance;
    _notificationOpenedSubscription = notifications.sosNotificationOpened
        .listen(_handleSosNotificationOpened);
    final medicationNotifications = MedicationNotificationService.instance;
    _medicationReminderSubscription = medicationNotifications.reminderOpened
        .listen((_) => _openHealth(0));
    if (medicationNotifications.consumePendingOpen()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openHealth(0));
    }
    if (notifications.consumePendingSosAlertId() != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSosNotificationOpened('pending');
      });
    }
  }

  void _handleSosNotificationOpened(String _) {
    if (!mounted) return;
    setState(() => _index = 0);
  }

  @override
  void dispose() {
    _notificationOpenedSubscription?.cancel();
    _medicationReminderSubscription?.cancel();
    super.dispose();
  }

  void _presentSosAlert({
    required SosAlert alert,
    required String elderDisplayName,
    required String? elderPhone,
  }) {
    if (_sosScreenOpen ||
        _presentedSosIds.contains(alert.id) ||
        alert.status != SosStatus.active) {
      return;
    }
    _sosScreenOpen = true;
    _presentedSosIds.add(alert.id);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ChildSosAlertPage(
            alert: alert,
            childId: widget.user.id,
            elderDisplayName: elderDisplayName,
            elderPhone: elderPhone,
          ),
        ),
      );
      _sosScreenOpen = false;
    });
  }

  void _openHealth(int tab) {
    setState(() {
      _healthTab = tab;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final links = ref.watch(childAccountLinksProvider(widget.user.phoneNumber));
    final acceptedLinks =
        links.asData?.value
            .where(
              (link) =>
                  link.status == LinkRequestStatus.accepted &&
                  link.childId == widget.user.id,
            )
            .toList() ??
        const <AccountLinkRequest>[];
    final accepted = acceptedLinks.isEmpty ? null : acceptedLinks.first;
    final sosAlerts = accepted == null
        ? null
        : ref.watch(activeSosAlertsProvider(accepted.elderId));
    final elderProfile = accepted == null
        ? null
        : ref.watch(currentProfileProvider(accepted.elderId)).asData?.value;
    final elderRelationship =
        (elderProfile?.gender ?? userGenderFromName(accepted?.elderGender))
            .parentRelationship;
    final elderDisplayName = accepted == null
        ? 'Chưa liên kết người thân'
        : '$elderRelationship ${accepted.elderName}';
    if (accepted != null) {
      ref.listen(activeSosAlertsProvider(accepted.elderId), (_, next) {
        final alerts = next.asData?.value ?? const <SosAlert>[];
        final activeAlerts = alerts.where(
          (alert) => alert.status == SosStatus.active,
        );
        if (activeAlerts.isNotEmpty) {
          _presentSosAlert(
            alert: activeAlerts.first,
            elderDisplayName: elderDisplayName,
            elderPhone: accepted.elderPhone,
          );
        }
      });
      final currentAlerts = sosAlerts?.asData?.value ?? const <SosAlert>[];
      final currentActive = currentAlerts.where(
        (alert) => alert.status == SosStatus.active,
      );
      if (currentActive.isNotEmpty) {
        _presentSosAlert(
          alert: currentActive.first,
          elderDisplayName: elderDisplayName,
          elderPhone: accepted.elderPhone,
        );
      }
    }
    final shell = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 82,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        titleSpacing: 20,
        title: const AppBrand(compact: true),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          ChildHomePage(
            childName: widget.user.fullName,
            elderDisplayName: elderDisplayName,
            elderId: accepted?.elderId,
            elderPhone: accepted?.elderPhone,
            onOpenMedication: () => _openHealth(0),
            onOpenHealth: () => _openHealth(1),
            onOpenLinks: () => setState(() => _index = 2),
          ),
          ChildCarePage(
            key: ValueKey(_healthTab),
            user: widget.user,
            initialTab: _healthTab,
          ),
          ChildAccountLinkingPage(user: widget.user),
          SettingsPage(userId: widget.user.id),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 82,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        indicatorColor: AppColors.primary,
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
            label: 'Liên kết',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Colors.white),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
    return accepted == null
        ? shell
        : MedicationNotificationSync(elderId: accepted.elderId, child: shell);
  }
}
