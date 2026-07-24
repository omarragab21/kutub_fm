import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/services/firebase_storage_service.dart';
import '../../domain/entities/user_profile.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserProfile> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docSnap = await _firestore.collection('users').doc(user.uid).get();
    
    if (!docSnap.exists) {
      throw Exception('User profile not found');
    }

    final data = docSnap.data()!;
    
    return UserProfile(
      id: user.uid,
      name: data['name'] ?? user.displayName ?? '',
      email: user.email ?? data['email'] ?? '',
      avatarUrl: data['photoUrl'] ?? user.photoURL,
      bio: data['bio'] ?? '',
      favoriteCategories: List<String>.from(data['favoriteCategories'] ?? const []),
      totalBooksListened: data['totalBooksListened'] ?? 0,
      totalListeningMinutes: data['totalListeningMinutes'] ?? 0,
      favoritesCount: data['favoritesCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      weeklyActivityMinutes: data['weeklyActivityMinutes'] != null
          ? List<int>.from(data['weeklyActivityMinutes'])
          : const [0, 0, 0, 0, 0, 0, 0],
      continueListening: data['continueListening'] != null
          ? (data['continueListening'] as List)
              .map((item) => ContinueListeningItem(
                    id: item['id'] ?? '',
                    title: item['title'] ?? '',
                    author: item['author'] ?? '',
                    coverUrl: item['coverUrl'] ?? '',
                    progress: ((item['progress'] ?? 0.0) as num).toDouble(),
                    lastChapter: item['lastChapter'] ?? '',
                  ))
              .toList()
          : const [],
      achievements: data['achievements'] != null
          ? (data['achievements'] as List)
              .map((item) => UserAchievement.fromMap(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String email,
    required String bio,
    required List<String> favoriteCategories,
    required int totalBooksListened,
    required int totalListeningMinutes,
    required int favoritesCount,
    required int followersCount,
    required int followingCount,
    required List<int> weeklyActivityMinutes,
    required List<ContinueListeningItem> continueListening,
    String? avatarUrl,
    File? profileImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String? finalAvatarUrl = avatarUrl;
    if (profileImage != null) {
      final storageService = FirebaseStorageService();
      finalAvatarUrl = await storageService.uploadProfileImage(
        imageFile: profileImage,
        uid: user.uid,
      );
    }

    final Map<String, dynamic> updates = {
      'name': name,
      'bio': bio,
      'favoriteCategories': favoriteCategories,
      'totalBooksListened': totalBooksListened,
      'totalListeningMinutes': totalListeningMinutes,
      'favoritesCount': favoritesCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'weeklyActivityMinutes': weeklyActivityMinutes,
      'continueListening': continueListening
          .map((item) => {
                'id': item.id,
                'title': item.title,
                'author': item.author,
                'coverUrl': item.coverUrl,
                'progress': item.progress,
                'lastChapter': item.lastChapter,
              })
          .toList(),
      'categorySelectionCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (finalAvatarUrl != null) {
      updates['photoUrl'] = finalAvatarUrl;
    }

    bool emailChanged = false;
    final newEmail = email.trim().toLowerCase();
    if (newEmail.isNotEmpty && newEmail != user.email?.trim().toLowerCase()) {
      try {
        await user.verifyBeforeUpdateEmail(newEmail);
        emailChanged = true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('requires-recent-login');
        } else {
          throw Exception(e.message ?? 'فشل تحديث البريد الإلكتروني');
        }
      }
    }

    await _firestore.collection('users').doc(user.uid).update(updates);
    
    final updatedProfile = await fetchProfile();
    
    if (emailChanged) {
      throw Exception('email-verification-sent');
    }

    return updatedProfile;
  }
}
