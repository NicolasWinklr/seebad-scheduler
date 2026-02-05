// Auth service for Firebase Authentication

import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service for admin login
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Login with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Map Firebase auth exceptions to German messages
  AuthException _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('Benutzer nicht gefunden');
      case 'wrong-password':
        return AuthException('Falsches Passwort');
      case 'invalid-email':
        return AuthException('Ungültige E-Mail-Adresse');
      case 'user-disabled':
        return AuthException('Benutzer deaktiviert');
      case 'too-many-requests':
        return AuthException('Zu viele Anmeldeversuche. Bitte später erneut versuchen.');
      case 'invalid-credential':
        return AuthException('Ungültige Anmeldedaten');
      default:
        return AuthException('Anmeldung fehlgeschlagen: ${e.message}');
    }
  }
}

/// Custom auth exception with German messages
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
