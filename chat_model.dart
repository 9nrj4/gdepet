import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> users;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
  final Map<String, String> userNames;
  final Map<String, String?> userPhotos;


  ChatModel({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.userNames,
    required this.userPhotos,
  });

  factory ChatModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      users: List<String>.from(data['users'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
      userNames: Map<String, String>.from(data['userNames'] ?? {}),
      userPhotos: Map<String, String?>.from(data['userPhotos'] ?? {}),
    );
  }
}
