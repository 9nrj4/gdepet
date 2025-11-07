import 'dart:io';
import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'dart:async';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _profileSubscription;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Обновить профиль
  Future<bool> updateProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? telegramTag,
    String? bio,
    String? city,
  }) async {
    if (_profile == null) return false;

    try {
      _setLoading(true);
      _error = null;

      final updatedProfile = _profile!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        telegramTag: telegramTag,
        bio: bio,
        city: city,
        updatedAt: DateTime.now(),
      );

      await _profileService.updateProfile(updatedProfile);
      _profile = updatedProfile;

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Загрузить фото профиля
  Future<bool> uploadProfilePhoto(String uid, File imageFile) async {
    try {
      _setLoading(true);
      _error = null;

      final photoUrl = await _profileService.uploadProfilePhoto(uid, imageFile);

      if (_profile != null) {
        final updatedProfile = _profile!.copyWith(
          photoURL: photoUrl,
          updatedAt: DateTime.now(),
        );
        await _profileService.updateProfile(updatedProfile);
        _profile = updatedProfile;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Удалить фото профиля
  Future<bool> deleteProfilePhoto(String uid) async {
    try {
      _setLoading(true);
      _error = null;

      await _profileService.deleteProfilePhoto(uid);

      if (_profile != null) {
        final updatedProfile = _profile!.copyWith(
          photoURL: null,
          updatedAt: DateTime.now(),
        );
        await _profileService.updateProfile(updatedProfile);
        _profile = updatedProfile;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ИСПРАВЛЕНИЕ: Подписаться на обновления профиля
  void subscribeToProfile(String uid) {
    // Отменяем предыдущую подписку, если есть
    _profileSubscription?.cancel();
    
    // Если уже подписаны на этого пользователя и профиль загружен, выходим
    if (_profile != null && _profile!.uid == uid && !_isLoading) {
      print("ProfileProvider: Already subscribed to profile $uid");
      return;
    }
    
    print("ProfileProvider: Subscribing to profile for UID: $uid");
    _setLoading(true);
    _error = null;
    
    // ИСПРАВЛЕНИЕ: Добавляем таймаут на загрузку
    Timer? timeoutTimer = Timer(const Duration(seconds: 4), () {
      if (_isLoading && _profile == null) {
        print("ProfileProvider: Loading timeout reached, profile may not exist");
        _isLoading = false;
        _error = 'Профиль не найден';
        notifyListeners();
      }
    });
    
    _profileSubscription = _profileService.getProfileStream(uid).listen(
      (profile) {
        timeoutTimer.cancel();
        print("ProfileProvider: Profile stream update received");
        
        // Всегда обновляем профиль и выключаем загрузку
        _profile = profile;
        _isLoading = false;
        _error = null;
        notifyListeners();
        
        if (profile != null) {
          print("ProfileProvider: Profile loaded - ${profile.displayName}");
        } else {
          print("ProfileProvider: Profile is null, document may not exist yet");
        }
      },
      onError: (e) {
        timeoutTimer.cancel();
        print("ProfileProvider: Error in profile stream: $e");
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _profileSubscription?.cancel();
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}