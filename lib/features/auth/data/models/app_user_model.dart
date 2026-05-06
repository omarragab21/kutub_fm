import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUserModel {
  AppUserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
    required this.role,
    required this.isGuest,
    required this.emailVerified,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String provider;
  final String role;
  final bool isGuest;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? provider,
    String? role,
    bool? isGuest,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      role: role ?? this.role,
      isGuest: isGuest ?? this.isGuest,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'role': role,
      'isGuest': isGuest,
      'emailVerified': emailVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      provider: map['provider'] ?? 'email',
      role: map['role'] ?? 'user',
      isGuest: map['isGuest'] ?? false,
      emailVerified: map['emailVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AppUserModel.fromFirebaseUser(User user) {
    return AppUserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      provider: 'email',
      role: 'user',
      isGuest: user.isAnonymous,
      emailVerified: user.emailVerified,
    );
  }
}
