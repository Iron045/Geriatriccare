import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/account_link_request.dart';
import '../providers/account_link_providers.dart';
import '../widgets/emergency_phone_card.dart';

class ChildAccountLinkingPage extends ConsumerWidget {
  const ChildAccountLinkingPage({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(childAccountLinksProvider(user.phoneNumber));
    return SafeArea(
      child: links.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không thể tải yêu cầu liên kết:\n$error'),
          ),
        ),
        data: (items) => _ChildLinksContent(user: user, links: items),
      ),
    );
  }
}

class _ChildLinksContent extends ConsumerWidget {
  const _ChildLinksContent({required this.user, required this.links});
  final AppUser user;
  final List<AccountLinkRequest> links;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = links
        .where((link) => link.status == LinkRequestStatus.pending)
        .toList();
    final accepted = links
        .where(
          (link) =>
              link.status == LinkRequestStatus.accepted &&
              link.childId == user.id,
        )
        .toList();
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(childAccountLinksProvider(user.phoneNumber)),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Người thân của tôi',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Gửi yêu cầu liên kết và theo dõi tài khoản cha mẹ của bạn.',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          const EmergencyPhoneCard(),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => _showLinkDialog(context, ref),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
              side: const BorderSide(color: AppColors.primary, width: 2),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text(
              'Gửi yêu cầu cho cha mẹ',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 26),
            const Text(
              'Yêu cầu đang chờ',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...pending.map((link) => _OutgoingRequestCard(link: link)),
          ],
          const SizedBox(height: 28),
          const Text(
            'Đã liên kết',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (accepted.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có tài khoản người cao tuổi nào được liên kết.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...accepted.map((link) => _ElderLinkCard(link: link)),
        ],
      ),
    );
  }

  Future<void> _showLinkDialog(BuildContext context, WidgetRef ref) async {
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Liên kết với cha mẹ'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại của cha/mẹ',
              prefixIcon: Icon(Icons.phone_rounded),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.replaceAll(RegExp(r'\D'), '').length < 9
                ? 'Số điện thoại chưa hợp lệ'
                : null,
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
      return;
    }
    final elderPhone = _normalizePhone(phone.text);
    final duplicate = links.any(
      (link) =>
          link.elderPhone == elderPhone &&
          (link.status == LinkRequestStatus.pending ||
              link.status == LinkRequestStatus.accepted),
    );
    if (duplicate) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tài khoản này đã liên kết hoặc đang chờ xác nhận.'),
          ),
        );
      }
      phone.dispose();
      return;
    }
    try {
      await ref.read(accountLinkRepositoryProvider).createRequest(
        AccountLinkRequest(
          id: '',
          elderId: '',
          elderName: '',
          elderPhone: elderPhone,
          childPhone: user.phoneNumber,
          childId: user.id,
          childName: user.fullName,
          relationship: 'Con',
          status: LinkRequestStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu. Vui lòng chờ cha/mẹ xác nhận.'),
          ),
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
    }
  }
}

class _OutgoingRequestCard extends ConsumerWidget {
  const _OutgoingRequestCard({required this.link});
  final AccountLinkRequest link;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE4F5EA),
        child: Icon(Icons.elderly_rounded, color: AppColors.success),
      ),
      title: Text(
        link.elderName.isEmpty ? link.elderPhone : link.elderName,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      subtitle: Text('Đang chờ cha/mẹ xác nhận • ${link.elderPhone}'),
      trailing: IconButton(
        tooltip: 'Hủy yêu cầu',
        onPressed: () =>
            ref.read(accountLinkRepositoryProvider).cancelRequest(link.id),
        icon: const Icon(Icons.close_rounded, color: AppColors.danger),
      ),
    ),
  );
}

class _ElderLinkCard extends ConsumerWidget {
  const _ElderLinkCard({required this.link});
  final AccountLinkRequest link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider(link.elderId));
    final gender =
        profile.asData?.value?.gender ?? userGenderFromName(link.elderGender);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: const CircleAvatar(
          radius: 32,
          backgroundColor: Color(0xFFE4F5EA),
          child: Icon(Icons.elderly, size: 40, color: AppColors.success),
        ),
        title: Text(
          link.elderName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${gender.parentRelationship} • ${link.elderPhone}'),
        trailing: const Icon(Icons.check_circle, color: AppColors.success),
      ),
    );
  }
}

String _normalizePhone(String value) {
  final compact = value.replaceAll(RegExp(r'[^\d+]'), '');
  if (compact.startsWith('0')) return '+84${compact.substring(1)}';
  return compact.startsWith('+') ? compact : '+84$compact';
}
