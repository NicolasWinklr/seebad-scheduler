// Firebase options placeholder
// Replace with actual Firebase configuration from Firebase Console

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration placeholder
/// 
/// To configure Firebase:
/// 1. Go to Firebase Console (https://console.firebase.google.com)
/// 2. Create a new project or select existing
/// 3. Add a Web app
/// 4. Copy the configuration values below
/// 5. Enable Authentication (Email/Password)
/// 6. Enable Cloud Firestore
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_AUTH_DOMAIN',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}
