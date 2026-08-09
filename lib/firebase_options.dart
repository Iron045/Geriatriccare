// File cấu hình thủ công hỗ trợ đa nền tảng (Android & Web)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Cấu hình Web (Lấy thông số từ Firebase Console -> Web App)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC62FKZk-sKyZtEC8ub_Pc_JkacX54tuyg',
    appId: '1:687836303569:web:dc600def426fc5a12875f0',
    messagingSenderId: '687836303569',
    projectId: 'geriatriccare-2477d',
    authDomain: 'geriatriccare-2477d.firebaseapp.com',
    storageBucket: 'geriatriccare-2477d.firebasestorage.app',
  );

  // Cấu hình Android (Lấy thông số tương ứng từ file google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:
        'AIzaSyDYLXsv8hEnFKKvRdjWdsNl63J4laid6Ho', // apiKey trong google-services.json (mục current_key)
    appId:
        '1:687836303569:android:220311f7acebdfbd2875f0', // mobilesdk_app_id trong google-services.json
    messagingSenderId: '687836303569', // project_number
    projectId: 'geriatriccare-2477d', // project_id
    storageBucket: 'geriatriccare-2477d.firebasestorage.app', // storage_bucket
  );
}
