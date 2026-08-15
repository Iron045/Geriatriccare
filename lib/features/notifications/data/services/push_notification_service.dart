import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registers notification tokens only for Child accounts.
///
/// The SOS itself is still delivered through Firestore in the foreground;
/// FCM makes it visible when the app is in the background or terminated.
final class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;
  final _sosOpenedController = StreamController<String>.broadcast();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;
  StreamSubscription<String>? _tokenSubscription;
  String? _registeredUserId;
  String? _registeredToken;
  String? _pendingSosAlertId;

  Stream<String> get sosNotificationOpened => _sosOpenedController.stream;

  String? consumePendingSosAlertId() {
    final value = _pendingSosAlertId;
    _pendingSosAlertId = null;
    return value;
  }

  Future<void> initialize() async {
    await _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleOpenedMessage(initialMessage);
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (message.data['type'] != 'sos') return;
    final alertId = message.data['alertId'];
    if (alertId is! String || alertId.isEmpty) return;
    _pendingSosAlertId = alertId;
    _sosOpenedController.add(alertId);
  }

  Future<void> _handleAuthChanged(User? user) async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    if (user == null) {
      await _removePreviousToken(invalidateDeviceToken: true);
      return;
    }

    _profileSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((profile) async {
          if (profile.data()?['role'] == 'child') {
            await _activateForChild(user.uid);
          } else {
            await _removePreviousToken(invalidateDeviceToken: true);
          }
        });
  }

  Future<void> _activateForChild(String userId) async {
    if (_registeredUserId == userId && _registeredToken != null) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    if (kIsWeb && _webVapidKey.isEmpty) {
      debugPrint(
        'FCM Web chưa đăng ký: hãy truyền '
        '--dart-define=FCM_WEB_VAPID_KEY=<PUBLIC_VAPID_KEY>.',
      );
      return;
    }

    final token = await _messaging.getToken(
      vapidKey: kIsWeb ? _webVapidKey : null,
    );
    if (token == null || token.isEmpty) return;
    await _saveToken(userId, token);

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (newToken) => _saveToken(userId, newToken),
    );
  }

  Future<void> _saveToken(String userId, String token) async {
    if (_registeredUserId != null &&
        (_registeredUserId != userId || _registeredToken != token)) {
      await _removePreviousToken();
    }
    final tokenId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    await _firestore.collection('fcm_tokens').doc(tokenId).set({
      'userId': userId,
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _registeredUserId = userId;
    _registeredToken = token;
  }

  Future<void> _removePreviousToken({bool invalidateDeviceToken = false}) async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    final token = _registeredToken;
    if (token != null) {
      final tokenId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
      try {
        await _firestore.collection('fcm_tokens').doc(tokenId).delete();
      } on FirebaseException {
        // A stale token is harmless and will also be removed by Cloud Functions.
      }
    }
    if (invalidateDeviceToken) {
      try {
        await _messaging.deleteToken();
      } on FirebaseException {
        // Token invalidation will be retried when the next session changes.
      }
    }
    _registeredUserId = null;
    _registeredToken = null;
  }
}
