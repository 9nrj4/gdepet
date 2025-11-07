import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet_model.dart';
import '../services/pet_service.dart';

class PetProvider extends ChangeNotifier {
  final PetService _petService = PetService();
  
  List<PetModel> _pets = [];
  List<PetModel> _userPets = [];
  bool _isLoading = false;
  String? _error;

  List<PetModel> get pets => _pets;
  List<PetModel> get userPets => _userPets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Замените метод addSighting в pet_provider.dart на этот:

  Future<bool> addSighting({
    required String petId,
    required double latitude,
    required double longitude,
    required String userId,
  }) async {
    try {
      print('PetProvider: Starting addSighting');
      print('PetId: $petId');
      print('Location: $latitude, $longitude');
      print('UserId: $userId');
      
      _error = null;
      
      final location = GeoPoint(latitude, longitude);
      
      await _petService.addSighting(petId, location, userId);
      
      print('PetProvider: Sighting added successfully');
      
      // Обновляем список питомцев
      await loadPets();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('PetProvider (addSighting) error: $e');
      print('Error stack trace: ${StackTrace.current}');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  // Создать объявление
  Future<bool> createPet({
    required String userId,
    required String ownerName,
    required String petName,
    required String description,
    required List<XFile> images,
    required PetType type,
    required PetStatus status,
    double? latitude,
    double? longitude,
    String? address,
    String? contactPhone,
    String? contactTelegram,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      String? geohash;
      if (latitude != null && longitude != null) {
        final geoPoint = GeoFirePoint(GeoPoint(latitude, longitude));
        geohash = geoPoint.geohash;
      }

      final tempPet = PetModel(
        id: '',
        userId: userId,
        ownerName: ownerName,
        petName: petName,
        description: description,
        imageUrls: [],
        type: type,
        status: status,
        latitude: latitude,
        longitude: longitude,
        geohash: geohash,
        address: address,
        contactPhone: contactPhone,
        contactTelegram: contactTelegram,
        createdAt: DateTime.now(),
      );

      final petId = await _petService.createPet(tempPet);

      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _petService.uploadPetPhotos(petId, images);
      }

      final updatedPet = PetModel(
        id: petId,
        userId: userId,
        ownerName: ownerName,
        petName: petName,
        description: description,
        imageUrls: imageUrls,
        type: type,
        status: status,
        latitude: latitude,
        longitude: longitude,
        geohash: geohash,
        address: address,
        contactPhone: contactPhone,
        contactTelegram: contactTelegram,
        createdAt: tempPet.createdAt,
      );

      await _petService.updatePet(petId, updatedPet);

      _setLoading(false);
      return true;
    } catch (e) {
      print('PetProvider (createPet) error: $e');
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadPets() async {
    try {
      _setLoading(true);
      _error = null;
      _pets = await _petService.getAllActivePets();
      _setLoading(false);
    } catch (e) {
      print('PetProvider (loadPets) error: $e');
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> loadPetsByStatus(PetStatus status) async {
    try {
      _setLoading(true);
      _error = null;
      _pets = await _petService.getPetsByStatus(status);
      _setLoading(false);
    } catch (e) {
      print('PetProvider (loadPetsByStatus) error: $e');
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> loadUserPets(String userId) async {
    try {
      _setLoading(true);
      _error = null;
      _userPets = await _petService.getUserPets(userId);
      _setLoading(false);
    } catch (e) {
      print('PetProvider (loadUserPets) error: $e');
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> deactivatePet(String id) async {
    try {
      _setLoading(true);
      _error = null;
      await _petService.deactivatePet(id);
      _setLoading(false);
      return true;
    } catch (e) {
      print('PetProvider (deactivatePet) error: $e');
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> searchNearbyPets({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      _pets = await _petService.searchNearbyPets(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      _setLoading(false);
    } catch (e) {
      print('PetProvider (searchNearbyPets) error: $e');
      _error = e.toString();
      _setLoading(false);
    }
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
    _pets = [];
    _userPets = [];
    _error = null;
    notifyListeners();
  }
  
  Future<bool> togglePetActive(String petId, bool isActive) async {
  try {
    _setLoading(true);
    _error = null;
    await _petService.updatePetField(petId, {'isActive': isActive});
    _setLoading(false);
    return true;
  } catch (e) {
    print('PetProvider (togglePetActive) error: $e');
    _error = e.toString();
    _setLoading(false);
    return false;
  }
}

Future<bool> updatePetStatus(String petId, PetStatus newStatus) async {
  try {
    _setLoading(true);
    _error = null;
    final statusString = newStatus.toString().split('.').last;
    await _petService.updatePetField(petId, {
      'status': statusString,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _setLoading(false);
    return true;
  } catch (e) {
    print('PetProvider (updatePetStatus) error: $e');
    _error = e.toString();
    _setLoading(false);
    return false;
  }
}

Future<bool> markPetAsFound(String petId) async {
  try {
    _setLoading(true);
    _error = null;
    await _petService.updatePetField(petId, {
      'status': 'found',
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _setLoading(false);
    return true;
  } catch (e) {
    print('PetProvider (markPetAsFound) error: $e');
    _error = e.toString();
    _setLoading(false);
    return false;
  }
}

Future<bool> deletePet(String petId) async {
  try {
    _setLoading(true);
    _error = null;
    await _petService.deletePet(petId);
    _setLoading(false);
    return true;
  } catch (e) {
    print('PetProvider (deletePet) error: $e');
    _error = e.toString();
    _setLoading(false);
    return false;
  }
}

Future<bool> updatePetData({
  required String petId,
  required String petName,
  required String description,
  required List<String> existingImageUrls,
  required List<XFile> newImages,
  required PetType type,
  required PetStatus status,
  double? latitude,
  double? longitude,
  String? address,
  String? contactPhone,
  String? contactTelegram,
}) async {
  try {
    _setLoading(true);
    _error = null;

    List<String> newImageUrls = [];
    if (newImages.isNotEmpty) {
      newImageUrls = await _petService.uploadPetPhotos(petId, newImages);
    }

    final allImageUrls = [...existingImageUrls, ...newImageUrls];

    String? geohash;
    if (latitude != null && longitude != null) {
      final geoPoint = GeoFirePoint(GeoPoint(latitude, longitude));
      geohash = geoPoint.geohash;
    }

    await _petService.updatePetField(petId, {
      'petName': petName,
      'description': description,
      'imageUrls': allImageUrls,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'address': address,
      'contactPhone': contactPhone,
      'contactTelegram': contactTelegram,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    _setLoading(false);
    return true;
  } catch (e) {
    print('PetProvider (updatePetData) error: $e');
    _error = e.toString();
    _setLoading(false);
    return false;
  }
  }
}

