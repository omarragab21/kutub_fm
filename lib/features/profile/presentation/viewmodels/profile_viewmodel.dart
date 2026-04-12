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
    required String bio,
    required List<String> favoriteCategories,
    String? avatarUrl,
  }) async {
    if (_profile == null) return;

    // Snapshot for rollback
    _previousProfile = _profile;

    // Optimistic update
    _profile = _profile!.copyWith(
      name: name,
      bio: bio,
      favoriteCategories: favoriteCategories,
      avatarUrl: avatarUrl,
    );
    _status = ProfileStatus.updating;
    notifyListeners();

    try {
      final saved = await _repository.updateProfile(
        name: name,
        bio: bio,
        favoriteCategories: favoriteCategories,
        avatarUrl: avatarUrl,
      );
      _profile = saved;
      _status = ProfileStatus.loaded;
    } catch (e) {
      // Rollback
      _profile = _previousProfile;
      _errorMessage = 'فشل تحديث الملف الشخصي. الرجاء المحاولة مجدداً.';
      _status = ProfileStatus.error;
      notifyListeners();

      // Auto-recover after showing error
      await Future.delayed(const Duration(seconds: 2));
      _status = ProfileStatus.loaded;
      _errorMessage = null;
    }
    notifyListeners();
  }
}
