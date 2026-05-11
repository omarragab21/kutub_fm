import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';

enum ProfileStatus { initial, loading, loaded, updating, error }

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileStatus _status = ProfileStatus.initial;
  UserProfile? _profile;
  UserProfile? _previousProfile; // for rollback
  String? _errorMessage;

  ProfileViewModel({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  ProfileStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;
  bool get isSaving => _status == ProfileStatus.updating;

  Future<void> fetchProfile() async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.fetchProfile();
      _status = ProfileStatus.loaded;
    } catch (e) {
      _errorMessage = 'فشل تحميل الملف الشخصي: $e';
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  /// Applies changes optimistically and rolls back on failure.
  Future<void> updateProfile({
    required String name,
    required String email,
    required String bio,
    required List<String> favoriteCategories,
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
