import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/account_link_request.dart';
import '../providers/account_link_providers.dart';
import '../widgets/emergency_phone_card.dart';

class ElderAccountLinkingPage extends ConsumerWidget {
  const ElderAccountLinkingPage({super.key, this.elderId});

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
            'Xác nhận yêu cầu từ con cái để họ có thể theo dõi và hỗ trợ bạn.',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          const EmergencyPhoneCard(),
          const SizedBox(height: 24),
          if (accepted.isNotEmpty) _PrimaryContact(link: accepted.first),
          const SizedBox(height: 28),
          const Text(
            'Người thân đã liên kết',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (accepted.isEmpty)
            const _EmptyLinks(
              message: 'Chưa có tài khoản con cái nào được liên kết.',
            )
          else
            ...accepted.map((link) => _AcceptedLinkCard(link: link)),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 26),
            const Text(
              'Yêu cầu liên kết đang chờ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...pending.map(
              (link) => _PendingLinkCard(link: link, elderId: elderId),
            ),
          ],
        ],
      ),
    );
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

class _PendingLinkCard extends ConsumerStatefulWidget {
  const _PendingLinkCard({required this.link, required this.elderId});
  final AccountLinkRequest link;
  final String elderId;

  @override
  ConsumerState<_PendingLinkCard> createState() => _PendingLinkCardState();
}

class _PendingLinkCardState extends ConsumerState<_PendingLinkCard> {
  bool loading = false;

  Future<void> respond(bool accept) async {
    setState(() => loading = true);
    try {
      await ref.read(accountLinkRepositoryProvider).respondToRequest(
        requestId: widget.link.id,
        accept: accept,
        elderId: widget.elderId,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text(widget.link.childName ?? widget.link.childPhone),
            subtitle: Text('${widget.link.relationship} • ${widget.link.childPhone}'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: loading ? null : () => respond(false),
                    style: OutlinedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: loading ? null : () => respond(true),
                    style: FilledButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
              ),
            ],
          ),
        ],
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

void _showContactMessage(BuildContext context, String phone) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Số điện thoại: $phone')));
}
