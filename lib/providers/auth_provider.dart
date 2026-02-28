import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

/// Manages authentication state using ChangeNotifier (Provider pattern).
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  User? _user;
  bool _isLoading = false;
  String? _error;

  /// Currently logged-in user.
  User? get user => _user;

  /// Whether an auth operation is in progress.
  bool get isLoading => _isLoading;

  /// Last error message, or null if no error.
  String? get error => _error;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Listen to Firebase auth state changes.
    _authRepository.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
    // Set initial user.
    _user = _authRepository.currentUser;
  }

  /// Attempts to sign in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Attempts to register a new user.
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.register(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  /// Clears the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Maps Firebase error codes to user-friendly messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
