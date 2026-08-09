# Firebase Phone Authentication setup

The application code supports Firebase Phone Authentication on Android and Web. Before testing OTP:

1. Open Firebase Console and select project `geriatriccare-2477d`.
2. In Authentication > Sign-in method, enable Phone.
3. In Project settings > Android app, ensure the package name matches `com.example.geriatriccare`.
4. Add debug and release SHA-1/SHA-256 certificate fingerprints.
5. Download the current `google-services.json` to `android/app/google-services.json` when using the standard FlutterFire Gradle setup.
6. Deploy `firestore.rules` before creating profiles.

For development, add fictional test phone numbers in Firebase Authentication. This avoids SMS quotas and allows a fixed six-digit OTP.

Production notes:

- Replace the example Android application ID before publishing.
- Configure App Check and release signing.
- iOS is not configured in `firebase_options.dart` yet.
- In Authentication > Settings > Authorized domains, add every Web domain used to host the app. `localhost` must also be authorized for local development.
- Web authentication uses Firebase's managed reCAPTCHA flow. The user may see a full-page reCAPTCHA challenge before the SMS is sent.
- Web secure PIN storage requires HTTPS in production; localhost is supported for development.
