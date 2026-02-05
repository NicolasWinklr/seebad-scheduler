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
    apiKey: 'AIzaSyDfmhS47f-RRRKMB6txTZtG5zTZD0yapas',
    appId: '1:773476876004:web:97b111981a71cdfad776f1',
    messagingSenderId: '773476876004',
    projectId: 'seebad-scheduler-d531c',
    authDomain: 'seebad-scheduler-d531c.firebaseapp.com',
    storageBucket: 'seebad-scheduler-d531c.firebasestorage.app',
  );

}