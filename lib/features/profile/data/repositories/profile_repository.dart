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

// ─── Mock Data ─────────────────────────────────────────────────────────────

final _mockProfile = UserProfile(
  id: 'usr_001',
  name: 'عمر رجب',
  email: 'omar@example.com',
  avatarUrl: null,
  bio: 'عاشق للقراءة والاستماع • محب للتاريخ والفلسفة',
  favoriteCategories: ['تاريخ', 'فلسفة', 'رواية', 'علوم', 'تنمية'],
  totalBooksListened: 24,
  totalListeningMinutes: 9360,
  favoritesCount: 12,
  followersCount: 340,
  followingCount: 87,
  weeklyActivityMinutes: [45, 90, 120, 30, 180, 60, 75],
  continueListening: [
    ContinueListeningItem(
      id: 'b001',
      title: 'مقدمة ابن خلدون',
      author: 'ابن خلدون',
      coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBxB5ydabQuh1USFu2pTGm0SvVp0akGtBgz2qh4GtC2jclIYLdgTUr_P3INAM5NT6y6seNosB20rrIit5RDHuBI3NVpDvhDKZtgG-wWU7NWex-vCQ4SMPFaqbaoLuPR3LSTnFYIhsi4IuHgeIpi-p0iOBZ0OWKVPNeC2gItmjnVDGEcnP_VWZLrw9TnJLySUIuEzB0q6twz2UyBhDy-th-1qaVAGFo40ssKqIuGSKTpUiNznbFmwNGz9SFOGD0n6YqiMpJZzPgyK38',
      progress: 0.72,
      lastChapter: 'الفصل الرابع: في العمران البدوي',
    ),
    ContinueListeningItem(
      id: 'b002',
      title: 'كليلة ودمنة',
      author: 'ابن المقفع',
      coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAHVWjHSH0iR0hD-LdFSnQ0xjc5oaXlKGMdIGjHcZVvGVgSSCO8P5FQjDvr8YdW0AiEbx-zCiMc5mKRUxdlvpaxHxfGv5Uh4xoEGFQ2pxe3BIjB1nfRfGEKOG2jFkrgFmNLqW7OPDqdyeANz8sMWSnKRdkHpwsPFB9i88lBGME4x-MzASaynTMYCTgKNRVIe8hP0cZu5hJd-DvV0GdRkUTxqKEzgtEPiCKbNhAJIjvhS9PJtPFtVbPvZEfYlEDC-bBuolUzQhAJo',
      progress: 0.38,
      lastChapter: 'باب الأسد والثور',
    ),
    ContinueListeningItem(
      id: 'b003',
      title: 'ألف ليلة وليلة',
      author: 'مجهول',
      coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD0jdwkqgJXt_lsC5mKmV5M-iNzfU5bGBm0W6xyOqrD2W2AXAiAGO5yIy2j6BHVZWQaL9z3_3fnoSz6DdUrA3PW9gQA8pf7t45K7Q3mxk-F5Yj8Ui67-h8yJqd0YhO1Jlo93xSn7X0tnkEEA3XsD-E2F3SvpEDJVqCVeJEqSECbGLnSxh47FZQBU14xo3I0WmDEHnAeSqBEDFHCa5sWpHGBTF6Hc0T3HO7CuJN8sMiCCpGiF90sDfx9Tp28e77T2xPGABivKq8',
      progress: 0.15,
      lastChapter: 'الليلة الأولى: بداية الحكاية',
    ),
  ],
);
