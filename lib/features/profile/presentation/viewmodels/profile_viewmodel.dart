import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';

enum ProfileStatus { initial, loading, loaded, updating, error }

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileStatus _status = ProfileStatus.initial;
  UserProfile? _profile;
  UserProfile? _previousProfile; // for rollback
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  ProfileViewModel({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  ProfileStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;
  bool get isSaving => _status == ProfileStatus.updating;

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'المستخدم غير مسجل الدخول';
      _status = ProfileStatus.error;
      notifyListeners();
      return;
    }

    try {
      await _profileSub?.cancel();
      _profileSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((docSnap) {
        if (docSnap.exists) {
          final data = docSnap.data();
          if (data != null) {
            _profile = UserProfile(
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
            _status = ProfileStatus.loaded;
            notifyListeners();
          }
        } else {
          _errorMessage = 'بيانات الملف الشخصي غير موجودة';
          _status = ProfileStatus.error;
          notifyListeners();
        }
      }, onError: (e) {
        _errorMessage = 'فشل تحميل الملف الشخصي: $e';
        _status = ProfileStatus.error;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'فشل تحميل الملف الشخصي: $e';
      _status = ProfileStatus.error;
      notifyListeners();
    }
  }

  /// Applies changes optimistically and rolls back on failure.
  Future<void> updateProfile({
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
    if (_profile == null) return;

    // Snapshot for rollback
    _previousProfile = _profile;

    // Optimistic update
    _profile = _profile!.copyWith(
      name: name,
      email: email, // This might revert if verification is sent
      bio: bio,
      favoriteCategories: favoriteCategories,
      totalBooksListened: totalBooksListened,
      totalListeningMinutes: totalListeningMinutes,
      favoritesCount: favoritesCount,
      followersCount: followersCount,
      followingCount: followingCount,
      weeklyActivityMinutes: weeklyActivityMinutes,
      continueListening: continueListening,
      avatarUrl: avatarUrl,
    );
    _status = ProfileStatus.updating;
    notifyListeners();

    try {
      final saved = await _repository.updateProfile(
        name: name,
        email: email,
        bio: bio,
        favoriteCategories: favoriteCategories,
        totalBooksListened: totalBooksListened,
        totalListeningMinutes: totalListeningMinutes,
        favoritesCount: favoritesCount,
        followersCount: followersCount,
        followingCount: followingCount,
        weeklyActivityMinutes: weeklyActivityMinutes,
        continueListening: continueListening,
        avatarUrl: avatarUrl,
        profileImage: profileImage,
      );
      _profile = saved;
      _status = ProfileStatus.loaded;
    } catch (e) {
      if (e.toString().contains('email-verification-sent')) {
        // Fetch to revert email to old email since it's not verified yet
        _profile = await _repository.fetchProfile();
        _errorMessage = 'تم حفظ التغييرات. تم إرسال رابط تأكيد للبريد الجديد، ولن يتغير حتى تقوم بتأكيده.';
        _status = ProfileStatus.loaded;
      } else if (e.toString().contains('requires-recent-login')) {
        _profile = _previousProfile;
        _errorMessage = 'لتغيير البريد الإلكتروني، يرجى تسجيل الخروج والدخول مجدداً لأسباب أمنية.';
        _status = ProfileStatus.error;
      } else {
        // Rollback
        _profile = _previousProfile;
        _errorMessage = 'فشل تحديث الملف الشخصي. الرجاء المحاولة مجدداً.';
        _status = ProfileStatus.error;
      }
      notifyListeners();

      if (_status == ProfileStatus.error) {
        // Auto-recover after showing error
        await Future.delayed(const Duration(seconds: 4));
        _status = ProfileStatus.loaded;
        _errorMessage = null;
      }
    }
    notifyListeners();
  }
}
