import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userFavoritesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  Future<Set<String>> getFavoritePetIds(String userId) async {
    final snapshot = await _userFavoritesCollection(userId).get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  Future<void> addFavorite(String userId, String petId) async {
    await _userFavoritesCollection(userId).doc(petId).set({
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite(String userId, String petId) async {
    await _userFavoritesCollection(userId).doc(petId).delete();
  }

  Future<bool> isFavorite(String userId, String petId) async {
    final doc = await _userFavoritesCollection(userId).doc(petId).get();
    return doc.exists;
  }
}


