import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<String?> watchUserId();
  String? get currentUserId;
  Future<String> requestOtp(String phoneNumber);
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<AppUser?> getProfile(String userId);
  Future<void> saveProfile(AppUser user);
  Future<void> signOut();
}
