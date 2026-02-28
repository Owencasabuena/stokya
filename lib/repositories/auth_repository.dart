import 'package:firebase_auth/firebase_auth.dart';

/// Repository wrapping Firebase Authentication operations.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes (user login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently authenticated user, or null.
  User? get currentUser => _auth.currentUser;

  /// Signs in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Registers a new user with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
