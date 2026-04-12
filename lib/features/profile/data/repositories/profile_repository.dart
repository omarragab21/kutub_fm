import '../../domain/entities/user_profile.dart';

/// Repository providing profile data.
/// In production, replace the mock methods with real API calls.
class ProfileRepository {
  // Simulate network delay
  Future<UserProfile> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockProfile;
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String bio,
    required List<String> favoriteCategories,
    String? avatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // In production: PUT /user/profile
    return _mockProfile.copyWith(
      name: name,
      bio: bio,
      favoriteCategories: favoriteCategories,
      avatarUrl: avatarUrl,
    );
  }
}

// ─── Mock Data ─────────────────────────────────────────────────────────────

final _mockProfile = UserProfile(
  id: 'usr_001',
  name: 'عمر رجب',
  avatarUrl: null, // Will show initials avatar
  bio: 'عاشق للقراءة والاستماع • محب للتاريخ والفلسفة',
  favoriteCategories: ['تاريخ', 'فلسفة', 'رواية', 'علوم', 'تنمية'],
  totalBooksListened: 24,
  totalListeningMinutes: 9360, // 156 hours
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
