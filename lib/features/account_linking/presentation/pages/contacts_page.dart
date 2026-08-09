import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/account_link_request.dart';
import '../providers/account_link_providers.dart';

class ContactsPage extends ConsumerWidget {
  const ContactsPage({super.key, this.elderId});

  final String? elderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = elderId;
    if (userId == null) return const SizedBox.shrink();
    final links = ref.watch(elderAccountLinksProvider(userId));
    return SafeArea(
      child: links.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không thể tải liên kết:\n$error'),
          ),
        ),
        data: (items) => _ElderContactsContent(elderId: userId, links: items),
      ),
    );
  }
}

class _ElderContactsContent extends ConsumerWidget {
  const _ElderContactsContent({required this.elderId, required this.links});
  final String elderId;
  final List<AccountLinkRequest> links;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accepted = links
        .where((link) => link.status == LinkRequestStatus.accepted)
        .toList();
    final pending = links
        .where((link) => link.status == LinkRequestStatus.pending)
        .toList();
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(elderAccountLinksProvider(elderId)),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Liên hệ khẩn cấp',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kết nối với con cái để họ có thể theo dõi và hỗ trợ bạn.',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          if (accepted.isNotEmpty) _PrimaryContact(link: accepted.first),
          const SizedBox(height: 28),
          const Text(
            'Người thân đã liên kết',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (accepted.isEmpty)
            const _EmptyLinks(message: 'Chưa có tài khoản Child nào liên kết.')
          else
            ...accepted.map((link) => _AcceptedLinkCard(link: link)),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 26),
            const Text(
              'Đang chờ xác nhận',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...pending.map((link) => _PendingLinkCard(link: link)),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showLinkDialog(context, ref),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(68),
              side: const BorderSide(color: AppColors.primary, width: 2),
            ),
            icon: const Icon(Icons.person_add_alt),
            label: const Text(
              'Thêm liên kết mới',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkDialog(BuildContext context, WidgetRef ref) async {
    final phone = TextEditingController();
    final relationship = TextEditingController(text: 'Con');
    final formKey = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm liên kết mới'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại của con',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ||
                        value.replaceAll(RegExp(r'\D'), '').length < 9
                    ? 'Số điện thoại chưa hợp lệ'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: relationship,
                decoration: const InputDecoration(
                  labelText: 'Mối quan hệ',
                  prefixIcon: Icon(Icons.family_restroom_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
    if (submit != true) {
      phone.dispose();
      relationship.dispose();
      return;
    }
    final normalizedPhone = _normalizePhone(phone.text);
    final duplicate = links.any(
      (link) =>
          link.childPhone == normalizedPhone &&
          (link.status == LinkRequestStatus.pending ||
              link.status == LinkRequestStatus.accepted),
    );
    if (duplicate) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Số điện thoại này đã được liên kết hoặc đang chờ xác nhận.',
            ),
          ),
        );
      }
      phone.dispose();
      relationship.dispose();
      return;
    }
    try {
      final profile = await ref.read(currentProfileProvider(elderId).future);
      if (profile == null) throw StateError('Không tìm thấy hồ sơ Elder');
      await ref
          .read(accountLinkRepositoryProvider)
          .createRequest(
            AccountLinkRequest(
              id: '',
              elderId: elderId,
              elderName: profile.fullName,
              elderPhone: profile.phoneNumber,
              elderGender: profile.gender?.name,
              childPhone: normalizedPhone,
              relationship: relationship.text.trim().isEmpty
                  ? 'Con'
                  : relationship.text.trim(),
              status: LinkRequestStatus.pending,
              createdAt: DateTime.now(),
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu liên kết.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi yêu cầu: $error')),
        );
      }
    } finally {
      phone.dispose();
      relationship.dispose();
    }
  }
}

class _PrimaryContact extends StatelessWidget {
  const _PrimaryContact({required this.link});
  final AccountLinkRequest link;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 54,
            backgroundColor: Color(0xFFE2F4E8),
            child: Icon(Icons.person, size: 70, color: AppColors.success),
          ),
          const SizedBox(height: 14),
          Text(
            link.childName ?? 'Người thân',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          Text(
            link.relationship,
            style: const TextStyle(fontSize: 21, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _showContactMessage(context, link.childPhone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Gọi'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      _showContactMessage(context, link.childPhone),
                  icon: const Icon(Icons.message),
                  label: const Text('Nhắn tin'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AcceptedLinkCard extends StatelessWidget {
  const _AcceptedLinkCard({required this.link});
  final AccountLinkRequest link;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const CircleAvatar(
        radius: 30,
        child: Icon(Icons.person, size: 36),
      ),
      title: Text(
        link.childName ?? link.childPhone,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${link.relationship} • ${link.childPhone}'),
      trailing: const Icon(Icons.check_circle, color: AppColors.success),
    ),
  );
}

class _PendingLinkCard extends ConsumerWidget {
  const _PendingLinkCard({required this.link});
  final AccountLinkRequest link;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const CircleAvatar(child: Icon(Icons.hourglass_top_rounded)),
      title: Text(link.childPhone),
      subtitle: const Text('Đang chờ Child xác nhận'),
      trailing: IconButton(
        tooltip: 'Hủy yêu cầu',
        onPressed: () =>
            ref.read(accountLinkRepositoryProvider).cancelRequest(link.id),
        icon: const Icon(Icons.close_rounded, color: AppColors.danger),
      ),
    ),
  );
}

class _EmptyLinks extends StatelessWidget {
  const _EmptyLinks({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17, color: AppColors.textMuted),
      ),
    ),
  );
}

String _normalizePhone(String value) {
  final compact = value.replaceAll(RegExp(r'[^\d+]'), '');
  if (compact.startsWith('0')) return '+84${compact.substring(1)}';
  return compact.startsWith('+') ? compact : '+84$compact';
}

void _showContactMessage(BuildContext context, String phone) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Số điện thoại: $phone')));
}
