import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/presentation/pages/child_navigation_page.dart';
import '../../../navigation/presentation/pages/elder_navigation_page.dart';
import '../../../medication/presentation/widgets/medication_notification_sync.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';
import 'phone_auth_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authUserIdProvider);
    return authState.when(
      loading: () => const _LoadingPage(),
      error: (error, _) => _ErrorPage(message: error.toString()),
      data: (userId) {
        if (userId == null) return const PhoneAuthPage();
        final profile = ref.watch(currentProfileProvider(userId));
        return profile.when(
          loading: () => const _LoadingPage(),
          error: (error, _) => _ErrorPage(message: error.toString()),
          data: (user) {
            if (user == null) return const PhoneAuthPage();
            if (user.role == UserRole.elder) {
              return MedicationNotificationSync(
                elderId: user.id,
                child: ElderNavigationPage(userId: user.id),
              );
            }
            return ChildNavigationPage(user: user);
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Không thể tải tài khoản:\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
