import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? photoURL;
  final String? telegramTag;
  final String? bio;
  final String? city;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int postsCount;
  final int foundPetsCount;

  ProfileModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.photoURL,
    this.telegramTag,
    this.bio,
    this.city,
    this.isEmailVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.postsCount = 0,
    this.foundPetsCount = 0,
  });

  String get displayName {
    // ИСПРАВЛЕНИЕ: Улучшенная логика для displayName
    final fName = (firstName?.trim().isNotEmpty == true) ? firstName!.trim() : null;
    final lName = (lastName?.trim().isNotEmpty == true) ? lastName!.trim() : null;

    if (fName != null && lName != null) {
      return '$fName $lName';
    }
    return fName ?? lName ?? 'Пользователь';
  }

  String get initials {
    String first = firstName?.isNotEmpty == true ? firstName![0] : '';
    String last = lastName?.isNotEmpty == true ? lastName![0] : '';
    
    if (first.isEmpty && last.isEmpty) {
      return 'П'; // "Пользователь"
    }
    return (first + last).toUpperCase();
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      uid: json['uid'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      photoURL: json['photoURL'],
      telegramTag: json['telegramTag'],
      bio: json['bio'],
      city: json['city'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      // ИСПРАВЛЕНИЕ: Обрабатываем Timestamp ИЛИ String
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()), // Запасной вариант
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] is Timestamp
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt']))
          : null,
      postsCount: json['postsCount'] ?? 0,
      foundPetsCount: json['foundPetsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'photoURL': photoURL,
      'telegramTag': telegramTag,
      'bio': bio,
      'city': city,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'postsCount': postsCount,
      'foundPetsCount': foundPetsCount,
    };
  }

  ProfileModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? photoURL,
    String? telegramTag,
    String? bio,
    String? city,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? postsCount,
    int? foundPetsCount,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoURL: photoURL ?? this.photoURL,
      telegramTag: telegramTag ?? this.telegramTag,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postsCount: postsCount ?? this.postsCount,
      foundPetsCount: foundPetsCount ?? this.foundPetsCount,
    );
  }
}