import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Получить профиль пользователя
  Future<ProfileModel?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return ProfileModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Ошибка загрузки профиля: $e';
    }
  }

  // Обновить профиль
  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .update(profile.toJson());
    } catch (e) {
      throw 'Ошибка обновления профиля: $e';
    }
  }

  // Загрузить фото профиля
  Future<String> uploadProfilePhoto(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_photos/$uid.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Обновить URL фото в Firebase Auth
      await _auth.currentUser?.updatePhotoURL(downloadUrl);
      
      return downloadUrl;
    } catch (e) {
      throw 'Ошибка загрузки фото: $e';
    }
  }

  // Удалить фото профиля
  Future<void> deleteProfilePhoto(String uid) async {
    try {
      final ref = _storage.ref().child('profile_photos/$uid.jpg');
      await ref.delete();
      await _auth.currentUser?.updatePhotoURL(null);
    } catch (e) {
      // Игнорируем ошибку, если файл не существует
    }
  }

  // Получить стрим профиля (для real-time обновлений)
  Stream<ProfileModel?> getProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return ProfileModel.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Обновить счетчики
  Future<void> incrementPostsCount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'postsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw 'Ошибка обновления счетчика: $e';
    }
  }

  Future<void> incrementFoundPetsCount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'foundPetsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw 'Ошибка обновления счетчика: $e';
    }
  }
}