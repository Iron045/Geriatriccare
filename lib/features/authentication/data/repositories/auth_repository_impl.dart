import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  ConfirmationResult? _webConfirmationResult;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<String?> watchUserId() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String> requestOtp(String phoneNumber) {
    if (kIsWeb) {
      return _requestWebOtp(phoneNumber).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw const NetworkException(
          'Quá thời gian xác minh reCAPTCHA. Vui lòng thử lại.',
        ),
      );
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const ValidationException(
        'Đăng nhập OTP hiện được hỗ trợ trên Android và Web.',
      );
    }
    final completer = Completer<String>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete('auto_verified');
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            NetworkException(error.message ?? 'Không thể gửi mã OTP', error),
          );
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 75),
      onTimeout: () => throw const NetworkException(
        'Firebase không phản hồi yêu cầu OTP. Hãy kiểm tra kết nối mạng, Phone Auth, SHA-1/SHA-256 và google-services.json.',
      ),
    );
  }

  Future<String> _requestWebOtp(String phoneNumber) async {
    try {
      await _auth.setLanguageCode('vi');
      _webConfirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
      return 'web_confirmation';
    } on FirebaseAuthException catch (error) {
      throw NetworkException(
        error.message ?? 'Không thể gửi mã OTP trên Web',
        error,
      );
    }
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (kIsWeb) {
        final confirmationResult = _webConfirmationResult;
        if (confirmationResult == null ||
            verificationId != 'web_confirmation') {
          throw const ValidationException(
            'Phiên xác thực Web đã hết hạn. Vui lòng gửi lại mã OTP.',
          );
        }
        await confirmationResult.confirm(smsCode);
        _webConfirmationResult = null;
        return;
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw ValidationException(error.message ?? 'Mã OTP không hợp lệ', error);
    }
  }

  @override
  Future<AppUser?> getProfile(String userId) async {
    final document = await _firestore.collection('users').doc(userId).get();
    final profile = document.exists
        ? AppUserModel.fromFirestore(document).toEntity()
        : null;
    if (profile != null && _auth.currentUser?.uid == userId) {
      await _firestore
          .collection('user_directory')
          .doc(profile.phoneNumber)
          .set({
            'uid': profile.id,
            'phoneNumber': profile.phoneNumber,
            'role': profile.role.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
    return profile;
  }

  @override
  Future<void> saveProfile(AppUser user) {
    final data = AppUserModel.fromEntity(user).toFirestore();
    // Remove the legacy field from existing profiles while using merge writes.
    data['dateOfBirth'] = FieldValue.delete();
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('users').doc(user.id),
      data,
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('user_directory').doc(user.phoneNumber),
      {
        'uid': user.id,
        'phoneNumber': user.phoneNumber,
        'role': user.role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return batch.commit();
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
