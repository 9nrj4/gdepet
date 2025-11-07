import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isGuest = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _isGuest;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Регистрация через email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.signUpWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Вход через email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Вход через Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;

      final result = await _authService.signInWithGoogle();
      
      _setLoading(false);
      return result != null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Отправить код на телефон
  String? _verificationId;
  
  Future<bool> sendPhoneCode(String phoneNumber) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.signInWithPhone(
        phoneNumber: phoneNumber,
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _setLoading(false);
        },
        verificationFailed: (FirebaseAuthException e) {
          _error = e.message ?? 'Ошибка верификации телефона';
          _setLoading(false);
        },
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _authService.verifyPhoneCode(
            verificationId: _verificationId!,
            smsCode: credential.smsCode!,
          );
          _setLoading(false);
        },
      );

      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Проверить код из SMS
  Future<bool> verifyPhoneCode(String smsCode) async {
    if (_verificationId == null) {
      _error = 'Сначала отправьте код';
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      await _authService.verifyPhoneCode(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Выход
  Future<void> signOut() async {
    await _authService.signOut();
    _isGuest = false;
    notifyListeners();
  }

  // Войти как гость
  void continueAsGuest() {
    _isGuest = true;
    notifyListeners();
  }

  // Удалить аккаунт
  Future<void> deleteAccount() async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.deleteAccount();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Отправить письмо для сброса пароля
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.sendPasswordResetEmail(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Повторно отправить письмо для верификации email
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _error = null;

      await _authService.sendEmailVerification();

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Проверить верификацию email
  Future<bool> checkEmailVerification() async {
    try {
      await _user?.reload();
      _user = _authService.currentUser;
      notifyListeners();
      return _user?.emailVerified ?? false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Сбросить пароль (алиас для sendPasswordResetEmail)
  Future<bool> resetPassword(String email) async {
    return await sendPasswordResetEmail(email);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}