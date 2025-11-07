import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Получить текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Поток изменений авторизации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ИСПРАВЛЕНИЕ: Регистрация через email и пароль
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      print("AuthService: Starting signUpWithEmail");
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("AuthService: User created in Firebase Auth: ${credential.user?.uid}");

      // Формируем полное имя для Firebase Auth
      final displayName = '$firstName $lastName';
      
      // Обновляем профиль Firebase Auth
      await credential.user?.updateDisplayName(displayName);
      print("AuthService: DisplayName updated to: $displayName");

      // Отправляем письмо для верификации
      await credential.user?.sendEmailVerification();
      print("AuthService: Verification email sent");

      // ВАЖНО: Сохраняем данные в Firestore СРАЗУ после регистрации
      await _saveUserToFirestore(
        credential.user!,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      
      print("AuthService: User data saved to Firestore");

      return credential;
    } on FirebaseAuthException catch (e) {
      print("AuthService: FirebaseAuthException - ${e.code}: ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      print("AuthService: Unexpected error - $e");
      rethrow;
    }
  }

  // Вход через email и пароль
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print("AuthService: Starting signInWithEmail");
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("AuthService: User signed in: ${credential.user?.uid}");
      
      // ИСПРАВЛЕНИЕ: Обновляем данные в Firestore при каждом входе
      // Это гарантирует, что isEmailVerified будет актуален
      if (credential.user != null) {
        await _updateUserVerificationStatus(credential.user!);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      print("AuthService: FirebaseAuthException - ${e.code}: ${e.message}");
      throw _handleAuthException(e);
    }
  }

  // ДОБАВЛЕНО: Обновление статуса верификации
  Future<void> _updateUserVerificationStatus(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isEmailVerified': user.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("AuthService: Email verification status updated: ${user.emailVerified}");
    } catch (e) {
      print("AuthService: Error updating verification status: $e");
    }
  }

  // Вход через Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print("AuthService: Starting Google sign-in");
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("AuthService: Google sign-in cancelled by user");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      print("AuthService: Google sign-in successful: ${userCredential.user?.uid}");

      // Сохраняем данные в Firestore
      await _saveUserToFirestore(userCredential.user!);

      return userCredential;
    } catch (e) {
      print("AuthService: Google sign-in error: $e");
      throw 'Ошибка входа через Google: $e';
    }
  }

  // Вход через телефон (первый шаг - отправка SMS)
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException error) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // Вход через телефон (второй шаг - проверка кода)
  Future<UserCredential?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Сохраняем данные в Firestore
      await _saveUserToFirestore(userCredential.user!);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Выход
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Удалить аккаунт
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  // Отправить письмо для сброса пароля
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Повторно отправить письмо для верификации
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Обновить пароль
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ИСПРАВЛЕНИЕ: Сохранить данные пользователя в Firestore
  Future<void> _saveUserToFirestore(
    User user, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    try {
      print("AuthService: Saving user to Firestore - UID: ${user.uid}");
      
      // Проверяем, существует ли уже документ пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      // Обрабатываем имя и фамилию
      String? fName = firstName;
      String? lName = lastName;
      
      // Если firstName и lastName не переданы, пробуем получить из displayName
      if (fName == null && lName == null && user.displayName != null && user.displayName!.isNotEmpty) {
        final nameParts = user.displayName!.trim().split(RegExp(r'\s+'));
        fName = nameParts.isNotEmpty ? nameParts[0] : null;
        lName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;
      }

      print("AuthService: Parsed names - firstName: $fName, lastName: $lName");

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'phoneNumber': phoneNumber ?? user.phoneNumber,
        'firstName': fName,
        'lastName': lName,
        'photoURL': user.photoURL,
        'isEmailVerified': user.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
        'postsCount': 0,
        'foundPetsCount': 0,
      };

      // Если документ не существует, добавляем createdAt
      if (!userDoc.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
        print("AuthService: Creating new user document");
      } else {
        print("AuthService: Updating existing user document");
      }
      
      // Используем set с merge: true для обновления только новых полей
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
          
      print("AuthService: User data saved successfully");
    } catch (e) {
      print("AuthService: Error saving user to Firestore: $e");
      // Не пробрасываем ошибку, чтобы не блокировать регистрацию
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'weak-password':
        return 'Слишком простой пароль (минимум 6 символов)';
      case 'user-disabled':
        return 'Пользователь отключен';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-verification-code':
        return 'Неверный код подтверждения';
      case 'invalid-verification-id':
        return 'Неверный ID верификации';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      default:
        return 'Произошла ошибка: ${e.message ?? e.code}';
    }
  }
}