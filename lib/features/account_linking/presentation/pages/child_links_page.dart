import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/account_link_request.dart';
import '../providers/account_link_providers.dart';

class ChildLinksPage extends ConsumerWidget {
  const ChildLinksPage({super.key, required this.user});
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
            'Xác nhận lời mời và quản lý tài khoản Elder đã liên kết.',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 26),
            const Text(
              'Yêu cầu đang chờ',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...pending.map((link) => _RequestCard(link: link, user: user)),
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
                  'Chưa có tài khoản Elder nào được liên kết.',
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
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.link, required this.user});
  final AccountLinkRequest link;
  final AppUser user;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool loading = false;

  Future<void> respond(bool accept) async {
    setState(() => loading = true);
    try {
      await ref
          .read(accountLinkRepositoryProvider)
          .respondToRequest(
            requestId: widget.link.id,
            accept: accept,
            childId: widget.user.id,
            childName: widget.user.fullName,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể phản hồi yêu cầu: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFE4F5EA),
              child: Icon(
                Icons.elderly_rounded,
                size: 40,
                color: AppColors.success,
              ),
            ),
            title: Text(
              widget.link.elderName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${_elderRelationship(widget.link)} • ${widget.link.elderPhone}',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: loading ? null : () => respond(false),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: loading ? null : () => respond(true),
                  child: loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Chấp nhận'),
                ),
              ),
            ],
          ),
        ],
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

String _elderRelationship(AccountLinkRequest link) =>
    userGenderFromName(link.elderGender).parentRelationship;
