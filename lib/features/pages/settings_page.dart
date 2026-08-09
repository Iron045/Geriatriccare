import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../voice_reminder/presentation/pages/voice_recorder_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool emergencyAlerts = true;
  bool medicationReminders = true;
  bool signingOut = false;

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout, color: AppColors.danger, size: 42),
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn sẽ cần xác thực lại số điện thoại bằng OTP trong lần đăng nhập tiếp theo.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => signingOut = true);
    try {
      await performSignOut(ref);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() => signingOut = false);
    }
  }

  Future<void> _editProfile(AppUser user) async {
    final name = TextEditingController(text: user.fullName);
    var gender = user.gender;
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Vui lòng nhập họ và tên'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserGender>(
                initialValue: gender,
                decoration: const InputDecoration(
                  labelText: 'Giới tính',
                  prefixIcon: Icon(Icons.wc_rounded),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: UserGender.male, child: Text('Nam')),
                  DropdownMenuItem(value: UserGender.female, child: Text('Nữ')),
                  DropdownMenuItem(
                    value: UserGender.other,
                    child: Text('Khác'),
                  ),
                ],
                onChanged: (value) => gender = value,
                validator: (value) =>
                    value == null ? 'Vui lòng chọn giới tính' : null,
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
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
    if (save == true) {
      try {
        await ref
            .read(authRepositoryProvider)
            .saveProfile(
              AppUser(
                id: user.id,
                phoneNumber: user.phoneNumber,
                fullName: name.text.trim(),
                role: user.role,
                createdAt: user.createdAt,
                gender: gender,
              ),
            );
        ref.invalidate(currentProfileProvider(user.id));
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không thể cập nhật: $error')));
        }
      }
    }
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    if (userId == null) {
      return _buildContent(
        AppUser(
          id: '',
          phoneNumber: '',
          fullName: 'Người dùng',
          role: UserRole.elder,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    }
    final profile = ref.watch(currentProfileProvider(userId));
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Không thể tải hồ sơ:\n$error')),
      data: (user) => _buildContent(
        user ??
            AppUser(
              id: userId,
              phoneNumber: '',
              fullName: 'Người dùng',
              role: UserRole.elder,
              createdAt: DateTime.now(),
            ),
      ),
    );
  }

  Widget _buildContent(AppUser user) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      children: [
        Text(
          'Cài đặt',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.primary,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: 32),
        const _SectionTitle('Hồ sơ của bạn'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFE2EAF8),
                  child: Text(
                    user.fullName.isEmpty
                        ? 'N'
                        : user.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (user.phoneNumber.isNotEmpty)
                        Text(
                          user.phoneNumber,
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppColors.textMuted,
                          ),
                        ),
                      if (user.gender != null)
                        Text(
                          _genderLabel(user.gender!),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: user.id.isEmpty ? null : () => _editProfile(user),
                  tooltip: 'Chỉnh sửa hồ sơ',
                  icon: const Icon(Icons.edit_rounded, size: 30),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Divider(height: 1),
        ),
        const _SectionTitle('Cấu hình thông báo'),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.emergency_rounded,
                iconColor: AppColors.danger,
                iconBackground: const Color(0xFFFFD9D9),
                title: 'Cảnh báo khẩn cấp',
                subtitle: 'Nhận thông báo ngay lập tức',
                trailing: Switch(
                  value: emergencyAlerts,
                  onChanged: (value) => setState(() => emergencyAlerts = value),
                ),
              ),
              const Divider(height: 1, indent: 82),
              _SettingsTile(
                icon: Icons.medication_rounded,
                iconColor: AppColors.primary,
                iconBackground: const Color(0xFFDCE8FF),
                title: 'Nhắc nhở uống thuốc',
                subtitle: 'Cảnh báo khi bỏ lỡ liều',
                trailing: Switch(
                  value: medicationReminders,
                  onChanged: (value) =>
                      setState(() => medicationReminders = value),
                ),
              ),
              const Divider(height: 1, indent: 82),
              _SettingsTile(
                icon: Icons.graphic_eq_rounded,
                iconColor: Colors.white,
                iconBackground: AppColors.primary,
                title: 'Ghi âm lời nhắc',
                subtitle: 'Gửi lời nhắn giọng nói cho người thân',
                trailing: const Icon(Icons.chevron_right_rounded, size: 32),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const VoiceRecorderPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        const _SectionTitle('Hỗ trợ'),
        const SizedBox(height: 16),
        Card(
          child: _SettingsTile(
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.textMuted,
            iconBackground: Colors.white,
            title: 'Trung tâm trợ giúp',
            trailing: const Icon(Icons.chevron_right_rounded, size: 32),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trung tâm trợ giúp GeriatricCare')),
            ),
          ),
        ),
        const SizedBox(height: 34),
        Center(
          child: OutlinedButton.icon(
            onPressed: signingOut ? null : _signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.5),
              minimumSize: const Size(280, 54),
            ),
            icon: signingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(signingOut ? 'Đang đăng xuất...' : 'Đăng xuất'),
          ),
        ),
      ],
    ),
  );
}

String _genderLabel(UserGender gender) => switch (gender) {
  UserGender.male => 'Nam',
  UserGender.female => 'Nữ',
  UserGender.other => 'Khác',
};

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
    leading: CircleAvatar(
      radius: 27,
      backgroundColor: iconBackground,
      child: Icon(icon, color: iconColor, size: 30),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle!,
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
    trailing: trailing,
  );
}
