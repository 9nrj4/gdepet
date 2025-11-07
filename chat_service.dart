import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/profile_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Stream<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
  
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    // Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toJson());

    // Update last message on the chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.text,
      'lastMessageTimestamp': message.timestamp,
    });
  }

  Future<String> createOrGetChat(String currentUserId, String receiverId) async {
    String chatId = getChatId(currentUserId, receiverId);
    
    DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // Get user profiles to store names and photos for the chat list
      DocumentSnapshot currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      DocumentSnapshot receiverUserDoc = await _firestore.collection('users').doc(receiverId).get();
      
      if (!currentUserDoc.exists || !receiverUserDoc.exists) {
        throw Exception("User profile not found");
      }
      
      // ИСПРАВЛЕНИЕ: Безопасное получение данных и проверка createdAt
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final receiverUserData = receiverUserDoc.data() as Map<String, dynamic>;

      // Добавляем проверку на createdAt, если он null 
      if (currentUserData['createdAt'] == null) {
        currentUserData['createdAt'] = DateTime.now().toIso8601String();
      }
      if (receiverUserData['createdAt'] == null) {
        receiverUserData['createdAt'] = DateTime.now().toIso8601String();
      }

      ProfileModel currentUserProfile = ProfileModel.fromJson(currentUserData);
      ProfileModel receiverUserProfile = ProfileModel.fromJson(receiverUserData);

      await _firestore.collection('chats').doc(chatId).set({
        'users': [currentUserId, receiverId],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'userNames': {
          currentUserId: currentUserProfile.displayName,
          receiverId: receiverUserProfile.displayName,
        },
        'userPhotos': {
          currentUserId: currentUserProfile.photoURL,
          receiverId: receiverUserProfile.photoURL,
        },
      });
    }
    
    return chatId;
  }
}
