import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet_model.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addSighting(String petId, GeoPoint location, String userId) async {
    try {
      print('PetService: Adding sighting for pet $petId');
      print('Location: ${location.latitude}, ${location.longitude}');
      print('User ID: $userId');
      
      // Создаем данные для отметки с реальным timestamp
      final now = DateTime.now();
      final sightingData = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'userId': userId,
        'timestamp': now.toIso8601String(), // Используем ISO строку вместо FieldValue
        'googleMapsUrl': 'https://maps.google.com/?q=${location.latitude},${location.longitude}',
      };
      
      print('Sighting data: $sightingData');
      
      // Получаем текущий документ
      final petDoc = await _firestore.collection('pets').doc(petId).get();
      
      if (!petDoc.exists) {
        throw 'Объявление не найдено';
      }
      
      // Получаем текущий массив отметок
      final currentData = petDoc.data();
      List<dynamic> currentSightings = List.from(currentData?['sightings'] ?? []);
      
      print('Current sightings count: ${currentSightings.length}');
      
      // Добавляем новую отметку
      currentSightings.add(sightingData);
      
      // Обновляем документ
      await _firestore.collection('pets').doc(petId).update({
        'sightings': currentSightings,
        'updatedAt': now.toIso8601String(),
      });
      
      print('PetService: Sighting added successfully');
      
      // Отправляем уведомление владельцу через создание чата
      await _sendSightingNotification(petId, userId, location, currentData);
      
    } catch (e) {
      print('PetService (addSighting) error: $e');
      print('Error type: ${e.runtimeType}');
      throw 'Ошибка добавления отметки: $e';
    }
  }

  Future<void> _sendSightingNotification(
    String petId, 
    String sighterId, 
    GeoPoint location,
    Map<String, dynamic>? petData,
  ) async {
    try {
      if (petData == null) return;
      
      final ownerId = petData['userId'] as String?;
      final petName = petData['petName'] as String? ?? 'питомца';
      
      if (ownerId == null || ownerId == sighterId) return;
      
      // Получаем данные пользователя, который видел питомца
      final sighterDoc = await _firestore.collection('users').doc(sighterId).get();
      final sighterData = sighterDoc.data();
      final sighterName = sighterData?['firstName'] ?? 'Пользователь';
      
      // Создаем ID чата
      List<String> ids = [ownerId, sighterId];
      ids.sort();
      final chatId = ids.join('_');
      
      // Проверяем существование чата
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Получаем данные владельца для создания чата
        final ownerDoc = await _firestore.collection('users').doc(ownerId).get();
        final ownerData = ownerDoc.data();
        
        if (ownerData != null) {
          await _firestore.collection('chats').doc(chatId).set({
            'users': [ownerId, sighterId],
            'lastMessage': '',
            'lastMessageTimestamp': Timestamp.now(),
            'userNames': {
              ownerId: ownerData['firstName'] ?? 'Владелец',
              sighterId: sighterName,
            },
            'userPhotos': {
              ownerId: ownerData['photoURL'],
              sighterId: sighterData?['photoURL'],
            },
          });
        }
      }
      
      // Формируем сообщение
      final googleMapsUrl = 'https://maps.google.com/?q=${location.latitude},${location.longitude}';
      final message = '👀 Я видел(а) вашего питомца "$petName"!\n\n'
          '📍 Местоположение:\n'
          'Широта: ${location.latitude.toStringAsFixed(6)}\n'
          'Долгота: ${location.longitude.toStringAsFixed(6)}\n\n'
          '🗺️ Открыть на карте: $googleMapsUrl\n\n'
          '⏰ ${_formatDateTime(DateTime.now())}';
      
      // Отправляем сообщение
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': sighterId,
        'receiverId': ownerId,
        'text': message,
        'timestamp': Timestamp.now(),
        'sightingLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        }
      });
      await _createNotification(
        userId: ownerId,
        type: 'sighting',
        title: '👀 Кто-то видел вашего питомца!',
        message: '$sighterName видел(а) "$petName". Проверьте чат для подробностей.',
        petId: petId,
      );
      
      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '👀 Видели вашего питомца!',
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      print('PetService: Notification sent successfully');
    } catch (e) {
      print('PetService (_sendSightingNotification) error: $e');
      // Не прерываем выполнение, если не удалось отправить уведомление
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  Future<String> createPet(PetModel pet) async {
    try {
      final docRef = await _firestore.collection('pets').add(pet.toJson());
      return docRef.id;
    } catch (e) {
      print('PetService (createPet) error: $e');
      throw 'Ошибка создания объявления: $e';
    }
  }
  Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? petId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'petId': petId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      print('Notification created successfully');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Загрузить фотографии питомца
  Future<List<String>> uploadPetPhotos(String petId, List<XFile> images) async {
    try {
      List<String> urls = [];
      
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('pets/$petId/photo_$i.jpg');
        
        // Используем readAsBytes() и putData() для кроссплатформенной загрузки
        final bytes = await images[i].readAsBytes();
        final uploadTask = await ref.putData(bytes);
        
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      print('PetService (uploadPetPhotos) error: $e');
      throw 'Ошибка загрузки фотографий: $e';
    }
  }


  Future<void> updatePetField(String id, Map<String, dynamic> fields) async {
  try {
    print('PetService: Updating pet fields for ID: $id');
    print('Fields: $fields');
    await _firestore.collection('pets').doc(id).update(fields);
    print('PetService: Pet fields updated successfully');
  } catch (e) {
    print('PetService (updatePetField) error: $e');
    throw 'Ошибка обновления объявления: $e';
  }
}

// Удалить объявление
Future<void> deletePet(String id) async {
  try {
    print('PetService: Deleting pet with ID: $id');
    
    final pet = await getPetById(id);
    
    if (pet != null && pet.imageUrls.isNotEmpty) {
      for (String imageUrl in pet.imageUrls) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
          print('PetService: Deleted image: $imageUrl');
        } catch (e) {
          print('PetService: Failed to delete image $imageUrl: $e');
        }
      }
    }
    
    await _firestore.collection('pets').doc(id).delete();
    print('PetService: Pet deleted successfully');
  } catch (e) {
    print('PetService (deletePet) error: $e');
    throw 'Ошибка удаления объявления: $e';
  }
}

  // Получить все активные объявления
  Future<List<PetModel>> getAllActivePets() async {
    try {
      final snapshot = await _firestore
          .collection('pets')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PetModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('PetService (getAllActivePets) error: $e');
      throw 'Ошибка загрузки объявлений: $e';
    }
  }

  // Получить объявления по статусу
  Future<List<PetModel>> getPetsByStatus(PetStatus status) async {
    try {
      final statusString = status.toString().split('.').last;
      
      final snapshot = await _firestore
          .collection('pets')
          .where('status', isEqualTo: statusString)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PetModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('PetService (getPetsByStatus) error: $e');
      throw 'Ошибка загрузки объявлений: $e';
    }
  }

  // Получить объявления пользователя
  Future<List<PetModel>> getUserPets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PetModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('PetService (getUserPets) error: $e');
      throw 'Ошибка загрузки объявлений пользователя: $e';
    }
  }

  // Получить объявление по ID
  Future<PetModel?> getPetById(String id) async {
    try {
      final doc = await _firestore.collection('pets').doc(id).get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      return PetModel.fromJson({...doc.data()!, 'id': doc.id});
      
    } catch (e) {
      print('PetService (getPetById) error: $e');
      throw 'Ошибка загрузки объявления: $e';
    }
  }

  // Обновить объявление
  Future<void> updatePet(String id, PetModel pet) async {
    try {
      await _firestore.collection('pets').doc(id).update(pet.toJson());
    } catch (e) {
      print('PetService (updatePet) error: $e');
      throw 'Ошибка обновления объявления: $e';
    }
  }

  // Деактивировать объявление
  Future<void> deactivatePet(String id) async {
    try {
      await _firestore.collection('pets').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('PetService (deactivatePet) error: $e');
      throw 'Ошибка деактивации объявления: $e';
    }
  }

  // Поиск объявлений рядом с координатами (используя GeoHash)
  Future<List<PetModel>> searchNearbyPets({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final center = GeoFirePoint(GeoPoint(latitude, longitude));
      final collectionRef = _firestore.collection('pets');
      
      final geoQuery = GeoCollectionReference(collectionRef)
          .subscribeWithin(
            center: center,
            radiusInKm: radiusKm,
            field: 'geohash',
            geopointFrom: (data) {
              final lat = data['latitude'] as double?;
              final lon = data['longitude'] as double?;
              
              if (lat != null && lon != null) {
                return GeoPoint(lat, lon);
              }
              throw Exception('Invalid GeoPoint data in document. Document will be skipped.');
            },
            strictMode: true,
          );
      
      final querySnapshot = await geoQuery.first;
      
      final pets = querySnapshot
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['isActive'] == true;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return PetModel.fromJson({...data, 'id': doc.id});
          })
          .toList();
      
      return pets;
    } catch (e) {
      print('PetService (searchNearbyPets) error: $e');
      throw 'Ошибка поиска объявлений: $e';
    }
  }

  // Альтернативный метод для синхронного поиска
  Stream<List<PetModel>> streamNearbyPets({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    try {
      final center = GeoFirePoint(GeoPoint(latitude, longitude));
      final collectionRef = _firestore.collection('pets');
      
      return GeoCollectionReference(collectionRef)
          .subscribeWithin(
            center: center,
            radiusInKm: radiusKm,
            field: 'geohash',
            geopointFrom: (data) {
              final lat = data['latitude'] as double?;
              final lon = data['longitude'] as double?;
              
              if (lat != null && lon != null) {
                return GeoPoint(lat, lon);
              }
              throw Exception('Invalid GeoPoint data in document. Document will be skipped.');
            },
            strictMode: true,
          )
          .map((querySnapshot) {
            return querySnapshot
                .where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  return data?['isActive'] == true;
                })
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return PetModel.fromJson({...data, 'id': doc.id});
                })
                .toList();
          });
    } catch (e) {
      print('PetService (streamNearbyPets) error: $e');
      rethrow; 
    }
  }
}

