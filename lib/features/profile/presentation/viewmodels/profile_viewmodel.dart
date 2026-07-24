import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_activity.dart';

import 'package:kutub_fm/core/stats/user_stats_tracker.dart';

enum ProfileStatus { initial, loading, loaded, updating, error }

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileStatus _status = ProfileStatus.initial;
  UserProfile? _profile;
  UserProfile? _previousProfile; // for rollback
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  ProfileViewModel({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository() {
    UserStatsTracker.instance.addListener(_onStatsChanged);
  }

  void _onStatsChanged() {
    if (_profile != null) {
      final tracker = UserStatsTracker.instance;
      _profile = _profile!.copyWith(
        totalListeningMinutes: tracker.totalListeningMinutes,
      );
      notifyListeners();
    }
  }

  static List<UserActivityGroup> get defaultActivityGroups => [
        UserActivityGroup(
          timeframe: 'قبل ساعة',
          items: [
            const UserActivityItem(
              id: 'act_1',
              type: UserActivityType.reviewPost,
              title: 'مراجعة كتاب',
              userName: 'رامي عامر',
              avatarUrl: 'assets/profile/imgAvatar.png',
              date: '24/5/2026',
              rating: 4.0,
              textContent:
                  'رواية استثنائية، أعادت تشكيل نظرتي للحياة والحب والوجود أسلوب ساحر ومترجم بشكل رائع. أنصح بها بشدة.',
              hashtags: ['#رائج', '#دراما'],
              linkedBookTitle: 'مئة عام من العزلة',
              linkedBookAuthor: 'أحمد خالد توفيق',
              linkedBookCover: 'assets/profile/imgImage26.png',
              linkedBookId: '1',
              likesCount: 35,
              commentsCount: 20,
            ),
            const UserActivityItem(
              id: 'act_2',
              type: UserActivityType.podcast,
              title: 'كيف يشكل الكتاب عقلك',
              subtitle: '12 نوفمبر • الحلقة 2',
              duration: '30:00 د',
              coverImage: 'assets/profile/imgFrame115.png',
              audioUrl: 'assets/audio_book.mp3',
            ),
          ],
        ),
        UserActivityGroup(
          timeframe: 'قبل يومين',
          items: [
            const UserActivityItem(
              id: 'act_3',
              type: UserActivityType.continueReading,
              title: 'كيف تركت العزلة',
              author: 'رجب البابورجي',
              coverImage: 'assets/profile/imgRectangle1.png',
              progress: 0.10,
              bookId: '2',
            ),
            const UserActivityItem(
              id: 'act_4',
              type: UserActivityType.reviewPost,
              title: 'مراجعة كتاب',
              userName: 'رامي عامر',
              avatarUrl: 'assets/profile/imgAvatar.png',
              date: '7/9/2026',
              rating: 4.0,
              textContent:
                  'عمل أدبي رائع يتناول قضايا الهوية والذاكرة بطريقة فلسفية وعميقة.',
              hashtags: ['#رائج', '#دراما'],
              linkedBookTitle: 'موسم الهجرة إلى الشمال',
              linkedBookAuthor: 'الطيب صالح',
              linkedBookCover: 'assets/profile/imgImage27.png',
              linkedBookId: '3',
              likesCount: 30,
              commentsCount: 17,
            ),
            const UserActivityItem(
              id: 'act_5',
              type: UserActivityType.podcast,
              title: 'العادات السبع للأسر الأكثر فعالية',
              subtitle: '6 يونيو • الحلقة 4',
              duration: '01:20 س',
              coverImage: 'assets/profile/imgFrame116.png',
              audioUrl: 'assets/audio_book.mp3',
            ),
          ],
        ),
      ];


  ProfileStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;
  bool get isSaving => _status == ProfileStatus.updating;

  List<UserActivityGroup> get activityGroups {
    if (_profile != null && _profile!.activityGroups.isNotEmpty) {
      return _profile!.activityGroups;
    }
    return defaultActivityGroups;
  }

  void toggleActivityLike(String activityId) {
    if (_profile == null) return;
    final currentGroups = activityGroups;
    final newGroups = currentGroups.map((group) {
      final newItems = group.items.map((item) {
        if (item.id == activityId) {
          final isLiked = !item.isLiked;
          final newCount = isLiked ? item.likesCount + 1 : item.likesCount - 1;
          return item.copyWith(isLiked: isLiked, likesCount: newCount < 0 ? 0 : newCount);
        }
        return item;
      }).toList();
      return UserActivityGroup(timeframe: group.timeframe, items: newItems);
    }).toList();

    _profile = _profile!.copyWith(activityGroups: newGroups);
    notifyListeners();
  }

  void toggleActivityBookmark(String activityId) {
    if (_profile == null) return;
    final currentGroups = activityGroups;
    final newGroups = currentGroups.map((group) {
      final newItems = group.items.map((item) {
        if (item.id == activityId) {
          return item.copyWith(isBookmarked: !item.isBookmarked);
        }
        return item;
      }).toList();
      return UserActivityGroup(timeframe: group.timeframe, items: newItems);
    }).toList();

    _profile = _profile!.copyWith(activityGroups: newGroups);
    notifyListeners();
  }

  @override
  void dispose() {
    UserStatsTracker.instance.removeListener(_onStatsChanged);
    _profileSub?.cancel();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Fallback default profile if not logged in
      _profile = UserProfile(
        id: 'default_1',
        name: 'رامي عامر',
        email: 'rami@example.com',
        avatarUrl: 'assets/profile/imgAvatar.png',
        totalBooksListened: 1,
        totalListeningMinutes: 90,
        followersCount: 220,
        followingCount: 520,
        activityGroups: defaultActivityGroups,
      );
      _status = ProfileStatus.loaded;
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
              name: data['name'] ?? user.displayName ?? 'رامي عامر',
              email: user.email ?? data['email'] ?? '',
              avatarUrl: data['photoUrl'] ?? user.photoURL ?? 'assets/profile/imgAvatar.png',
              bio: data['bio'] ?? '',
              favoriteCategories: List<String>.from(data['favoriteCategories'] ?? const []),
              totalBooksListened: data['totalBooksListened'] ?? 1,
              totalListeningMinutes: data['totalListeningMinutes'] ?? 90,
              favoritesCount: data['favoritesCount'] ?? 35,
              followersCount: data['followersCount'] ?? 220,
              followingCount: data['followingCount'] ?? 520,
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
              activityGroups: defaultActivityGroups,
            );
            _status = ProfileStatus.loaded;
            notifyListeners();
          }
        } else {
          _profile = UserProfile(
            id: user.uid,
            name: user.displayName ?? 'رامي عامر',
            email: user.email ?? '',
            avatarUrl: user.photoURL ?? 'assets/profile/imgAvatar.png',
            followersCount: 220,
            followingCount: 520,
            totalListeningMinutes: 90,
            activityGroups: defaultActivityGroups,
          );
          _status = ProfileStatus.loaded;
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
