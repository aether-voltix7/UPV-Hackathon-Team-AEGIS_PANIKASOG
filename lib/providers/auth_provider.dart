import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    _init();
  }

  // ─── State ────────────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  // Multi-step signup temp data
  String _signupEmail = '';
  String _signupPhone = '';
  String _signupPassword = '';

  // ─── Getters ──────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  String get signupEmail => _signupEmail;
  String get signupPhone => _signupPhone;
  String get signupPassword => _signupPassword;

  // ─── Init ─────────────────────────────────────────────────────────────────
  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        final model = await _authService.getCurrentUserModel();
        if (model != null) {
          _user = model;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      }
      notifyListeners();
    });
  }

  // ─── Save Step 1 Data ─────────────────────────────────────────────────────
  void saveSignupStep1({
    required String email,
    required String phone,
    required String password,
  }) {
    _signupEmail = email;
    _signupPhone = phone;
    _signupPassword = password;
    clearError();
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String name,
    required String username,
    required String address,
    required List<String> skills,
    required List<String> preferredTasks,
    String? referralCode,
  }) async {
    _setLoading();
    try {
      final user = await _authService.signUpWithEmail(
        email: _signupEmail,
        password: _signupPassword,
        phoneNumber: _signupPhone,
        name: name,
        username: username,
        address: address,
        skills: skills,
        preferredTasks: preferredTasks,
        usedReferralCode: referralCode,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      final user = await _authService.signInWithGoogle();
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'sign-in-cancelled') {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      return false;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ─── Refresh User ─────────────────────────────────────────────────────────
Future<void> refreshUser() async {
  final model = await _authService.getCurrentUserModel();
  if (model != null) {
    _user = model;
    notifyListeners();
  }
}

  // ─── Password Reset ───────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _authService.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'username-already-in-use':
        return e.message ?? 'This username is already taken.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
