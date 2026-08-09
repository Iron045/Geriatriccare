import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';
import 'verify_otp_page.dart';

class PhoneAuthPage extends ConsumerStatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  ConsumerState<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends ConsumerState<PhoneAuthPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  UserRole role = UserRole.elder;
  UserGender gender = UserGender.male;
  bool isRegister = false;
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String normalizePhone(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    if (compact.startsWith('0')) return '+84${compact.substring(1)}';
    return compact.startsWith('+') ? compact : '+84$compact';
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final phone = normalizePhone(phoneController.text);
      final verificationId = await ref
          .read(authRepositoryProvider)
          .requestOtp(phone);
      if (!mounted) return;
      if (verificationId == 'auto_verified') {
        await _saveProfileIfNeeded(phone);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VerifyOtpPage(
            verificationId: verificationId,
            phoneNumber: phone,
            fullName: nameController.text.trim(),
            role: role,
            gender: gender,
            createProfile: isRegister,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveProfileIfNeeded(String phone) async {
    if (!isRegister) return;
    final repository = ref.read(authRepositoryProvider);
    final userId = repository.currentUserId;
    if (userId == null) return;
    await repository.saveProfile(
      AppUser(
        id: userId,
        phoneNumber: phone,
        fullName: nameController.text.trim(),
        role: role,
        createdAt: DateTime.now(),
        gender: gender,
      ),
    );
    ref.invalidate(currentProfileProvider(userId));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned(
          right: -120,
          bottom: -150,
          child: IgnorePointer(
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4BE37D).withValues(alpha: .16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4BE37D).withValues(alpha: .25),
                    blurRadius: 70,
                    spreadRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 570),
                child: Column(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 28,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.monitor_heart_rounded,
                        color: AppColors.primary,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const _AppBrandName(),
                    const SizedBox(height: 14),
                    const Text(
                      'Luôn có người thân bên cạnh\nbạn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        height: 1.35,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 54),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 34,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(34, 34, 34, 28),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isRegister ? 'Đăng ký tài khoản' : 'Đăng nhập',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRegister
                                  ? 'Tạo tài khoản để bắt đầu sử dụng'
                                  : 'Nhập số điện thoại để nhận mã OTP',
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1.35,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (isRegister) ...[
                              const _FieldLabel('Họ và tên'),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: nameController,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  hint: 'Nhập họ và tên của bạn',
                                  icon: Icons.person_outline,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().length < 2
                                    ? 'Vui lòng nhập họ và tên'
                                    : null,
                              ),
                              const SizedBox(height: 22),
                            ],
                            const _FieldLabel('Số điện thoại'),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _fieldDecoration(
                                hint: '090 123 4567',
                                icon: Icons.phone_outlined,
                              ),
                              validator: (value) =>
                                  value == null ||
                                      value
                                              .replaceAll(RegExp(r'\D'), '')
                                              .length <
                                          9
                                  ? 'Số điện thoại chưa hợp lệ'
                                  : null,
                            ),
                            if (isRegister) ...[
                              const SizedBox(height: 22),
                              const _FieldLabel('Vai trò của bạn'),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<UserRole>(
                                initialValue: role,
                                decoration: _fieldDecoration(
                                  hint: 'Chọn vai trò',
                                  icon: Icons.badge_outlined,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: UserRole.elder,
                                    child: Text('Người cao tuổi'),
                                  ),
                                  DropdownMenuItem(
                                    value: UserRole.child,
                                    child: Text('Con cái'),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => role = value ?? UserRole.elder,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const _FieldLabel('Giới tính'),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<UserGender>(
                                initialValue: gender,
                                decoration: _fieldDecoration(
                                  hint: 'Chọn giới tính',
                                  icon: Icons.wc_rounded,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: UserGender.male,
                                    child: Text('Nam'),
                                  ),
                                  DropdownMenuItem(
                                    value: UserGender.female,
                                    child: Text('Nữ'),
                                  ),
                                  DropdownMenuItem(
                                    value: UserGender.other,
                                    child: Text('Khác'),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => gender = value ?? UserGender.male,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Text(
                              'Mã OTP sẽ được gửi qua SMS để xác thực số điện thoại.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 30),
                            FilledButton(
                              onPressed: loading ? null : submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(66),
                              ),
                              child: loading
                                  ? const SizedBox.square(
                                      dimension: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isRegister ? 'Đăng ký' : 'Đăng nhập',
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.login_rounded),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isRegister
                                      ? 'Đã có tài khoản? '
                                      : 'Chưa có tài khoản? ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                TextButton(
                                  onPressed: loading
                                      ? null
                                      : () => setState(
                                          () => isRegister = !isRegister,
                                        ),
                                  child: Text(
                                    isRegister ? 'Đăng nhập' : 'Đăng ký',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF7D8393)),
    prefixIcon: Icon(icon, color: const Color(0xFF7D8393), size: 28),
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.border, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.danger, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.danger, width: 2),
    ),
  );
}

class _AppBrandName extends StatelessWidget {
  const _AppBrandName();

  @override
  Widget build(BuildContext context) => const Text(
    'GeriatricCare',
    style: TextStyle(
      color: AppColors.primary,
      fontSize: 38,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.text,
    ),
  );
}
