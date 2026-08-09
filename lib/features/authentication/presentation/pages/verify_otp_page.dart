import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    required this.gender,
    required this.createProfile,
  });
  final String verificationId;
  final String phoneNumber;
  final String fullName;
  final UserRole role;
  final UserGender gender;
  final bool createProfile;

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final otpController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> verify() async {
    if (otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mã OTP phải gồm 6 số')));
      return;
    }
    setState(() => loading = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );
      final userId = repository.currentUserId;
      if (widget.createProfile && userId != null) {
        await repository.saveProfile(
          AppUser(
            id: userId,
            phoneNumber: widget.phoneNumber,
            fullName: widget.fullName,
            role: widget.role,
            createdAt: DateTime.now(),
            gender: widget.gender,
          ),
        );
        ref.invalidate(currentProfileProvider(userId));
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const Icon(Icons.sms_outlined, size: 72),
                const SizedBox(height: 22),
                Text(
                  'Nhập mã xác thực',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mã OTP đã được gửi đến\n${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '------',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : verify,
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Xác nhận OTP'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
