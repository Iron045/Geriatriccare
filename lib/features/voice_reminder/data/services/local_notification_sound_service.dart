import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class LocalNotificationSoundService {
  LocalNotificationSoundService._();

  static final instance = LocalNotificationSoundService._();
  static const _channel = MethodChannel(
    'com.example.geriatriccare/notification_sound',
  );

  Future<String?> getSelectedSoundUri() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return _channel.invokeMethod<String>('getSelectedSoundUri');
  }

  Future<String> saveAndSelect({
    required Uint8List audioBytes,
    required String title,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Âm báo tự ghi hiện chỉ được hỗ trợ trên điện thoại Android.',
      );
    }
    final uri = await _channel.invokeMethod<String>('saveAndSelectSound', {
      'bytes': audioBytes,
      'title': title,
    });
    if (uri == null || uri.isEmpty) {
      throw StateError('Thiết bị không trả về đường dẫn âm thanh.');
    }
    return uri;
  }
}
