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
    this.userType = 'normal_user',
    this.emailDomain,
    this.appEmailVerified = false,
    this.firebaseEmailVerified = false,
    this.verificationMode = 'firebase_email_verification',
    this.categorySelectionCompleted = false,
    this.categorySelectionSkipped = false,
    this.phoneNumber,
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
  final String userType;
  final String? emailDomain;
  final bool appEmailVerified;
  final bool firebaseEmailVerified;
  final String verificationMode;
  final bool categorySelectionCompleted;
  final bool categorySelectionSkipped;
  final String? phoneNumber;

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
    String? userType,
    String? emailDomain,
    bool? appEmailVerified,
    bool? firebaseEmailVerified,
    String? verificationMode,
    bool? categorySelectionCompleted,
    bool? categorySelectionSkipped,
    String? phoneNumber,
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
      userType: userType ?? this.userType,
      emailDomain: emailDomain ?? this.emailDomain,
      appEmailVerified: appEmailVerified ?? this.appEmailVerified,
      firebaseEmailVerified: firebaseEmailVerified ?? this.firebaseEmailVerified,
      verificationMode: verificationMode ?? this.verificationMode,
      categorySelectionCompleted: categorySelectionCompleted ?? this.categorySelectionCompleted,
      categorySelectionSkipped: categorySelectionSkipped ?? this.categorySelectionSkipped,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
      'userType': userType,
      if (emailDomain != null) 'emailDomain': emailDomain,
      'appEmailVerified': appEmailVerified,
      'firebaseEmailVerified': firebaseEmailVerified,
      'verificationMode': verificationMode,
      'categorySelectionCompleted': categorySelectionCompleted,
      'categorySelectionSkipped': categorySelectionSkipped,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
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
      userType: map['userType'] ?? 'normal_user',
      emailDomain: map['emailDomain'],
      appEmailVerified: map['appEmailVerified'] ?? false,
      firebaseEmailVerified: map['firebaseEmailVerified'] ?? false,
      verificationMode: map['verificationMode'] ?? 'firebase_email_verification',
      categorySelectionCompleted: map['categorySelectionCompleted'] ?? false,
      categorySelectionSkipped: map['categorySelectionSkipped'] ?? false,
      phoneNumber: map['phoneNumber'],
    );
  }

  factory AppUserModel.fromFirebaseUser(User user) {
    return AppUserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      provider: user.phoneNumber != null && user.phoneNumber!.isNotEmpty ? 'phone' : 'email',
      role: 'user',
      isGuest: user.isAnonymous,
      emailVerified: user.emailVerified,
      userType: 'normal_user',
      appEmailVerified: user.emailVerified,
      firebaseEmailVerified: user.emailVerified,
      verificationMode: user.phoneNumber != null && user.phoneNumber!.isNotEmpty ? 'phone_otp' : 'firebase_email_verification',
      categorySelectionCompleted: false,
      categorySelectionSkipped: false,
      phoneNumber: user.phoneNumber,
    );
  }
}
