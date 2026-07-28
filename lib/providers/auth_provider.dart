// lib/providers/auth_provider.dart -- Firebase Auth: Email, Phone, Google, Anonymous
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;
  bool get isAnonymous => user?.isAnonymous ?? false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  // ── Email / Password ──────────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
      await cred.user?.updateDisplayName(name.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      return _fail(_friendlyError(e.code));
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      return _fail(_friendlyError(e.code));
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled
        _setLoading(false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // If currently anonymous, link account instead of creating new
      if (isAnonymous) {
        await _auth.currentUser?.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      return _fail(_friendlyError(e.code));
    } catch (e) {
      return _fail('Google Sign-In gagal. Pastikan koneksi internet aktif.');
    }
  }

  // ── Anonymous ─────────────────────────────────────────────────────────

  Future<bool> signInAnonymously() async {
    _setLoading(true);
    try {
      await _auth.signInAnonymously();
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      return _fail(_friendlyError(e.code));
    }
  }

  /// Link anonymous account to email/password
  Future<bool> linkEmailToAnonymous({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final credential = EmailAuthProvider.credential(
          email: email.trim(), password: password);
      final result = await _auth.currentUser?.linkWithCredential(credential);
      await result?.user?.updateDisplayName(name.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      return _fail(_friendlyError(e.code));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _googleSignIn.signOut().catchError((_) {});
    await _auth.signOut();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    if (v) _errorMessage = null;
    notifyListeners();
  }

  bool _fail(String msg) {
    _errorMessage = msg;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email sudah digunakan. Coba login.';
      case 'invalid-email': return 'Format email tidak valid.';
      case 'weak-password': return 'Password minimal 6 karakter.';
      case 'user-not-found': return 'Akun tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential': return 'Email atau password salah.';
      case 'too-many-requests': return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'account-exists-with-different-credential':
        return 'Akun sudah terdaftar dengan metode login lain.';
      case 'credential-already-in-use':
        return 'Akun Google ini sudah terhubung ke akun lain.';
      default: return 'Terjadi kesalahan. Coba lagi.';
    }
  }
}
