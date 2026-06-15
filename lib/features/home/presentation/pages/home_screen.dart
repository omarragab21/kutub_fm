import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:kutub_fm/core/navigation/app_navigation_state.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/features/profile/presentation/pages/profile_screen.dart';
import 'package:kutub_fm/features/book_reader/presentation/pages/book_reader_screen.dart';
import "../../../../core/audio/audio_provider.dart";
import "../../../../core/routes/app_routes.dart";
import "../viewmodels/home_view_model.dart";
import 'package:kutub_fm/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:kutub_fm/features/auth/presentation/providers/auth_provider.dart';

class DiscoverBook {
  final String id;
  final String title;
  final String author;
  final String imageUrl;

  const DiscoverBook({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'مخصص لك';
  final Set<String> _likedBookIds = {};

  final Map<String, List<DiscoverBook>> _discoverBooks = {
    'مخصص لك': [
      const DiscoverBook(
        id: 'disc_1',
        title: 'تطوير المهارات القيادية',
        author: 'خالد العتيبي',
        imageUrl: 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?q=80&w=300&auto=format&fit=crop',
      ),
      const DiscoverBook(
        id: 'disc_2',
        title: 'فن التفاوض في الأعمال',
        author: 'ليلى الكردي',
        imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=300&auto=format&fit=crop',
      ),
      const DiscoverBook(
        id: 'disc_3',
        title: 'استراتيجيات بناء الثروة',
        author: 'أحمد الحسين',
        imageUrl: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?q=80&w=300&auto=format&fit=crop',
      ),
    ],
    'خيال علمي': [
      const DiscoverBook(
        id: 'disc_4',
        title: 'رحلة إلى المريخ',
        author: 'سارة الناجي',
        imageUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?q=80&w=300&auto=format&fit=crop',
      ),
      const DiscoverBook(
        id: 'disc_5',
        title: 'الذكاء الخارق',
        author: 'ياسر كمال',
        imageUrl: 'https://images.unsplash.com/photo-1507146426996-ef05306b995a?q=80&w=300&auto=format&fit=crop',
      ),
    ],
    'تشويق': [
      const DiscoverBook(
        id: 'disc_6',
        title: 'خلف الكواليس',
        author: 'محمد عبد الله',
        imageUrl: 'https://images.unsplash.com/photo-1509281373149-e957c6296406?q=80&w=300&auto=format&fit=crop',
      ),
    ],
    'رومانسي': [
      const DiscoverBook(
        id: 'disc_7',
        title: 'عهد الحب',
        author: 'منى فريد',
        imageUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?q=80&w=300&auto=format&fit=crop',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<HomeViewModel>();
    final profileViewModel = context.watch<ProfileViewModel>();
    final authProvider = context.watch<AuthProvider>();
    final hasMiniPlayer = context.watch<AudioProvider>().shouldShowMiniPlayer;

    // Trigger profile fetch if it is in initial state
    if (profileViewModel.status == ProfileStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        profileViewModel.fetchProfile();
      });
    }

    return _buildBody(
      viewModel,
      profileViewModel,
      authProvider,
      theme,
      context,
      hasMiniPlayer,
    );
  }

  Widget _buildBody(
    HomeViewModel viewModel,
    ProfileViewModel profileViewModel,
    AuthProvider authProvider,
    ThemeData theme,
    BuildContext context,
    bool hasMiniPlayer,
  ) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Text(
          viewModel.error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Custom App Bar
        _buildSliverAppBar(profileViewModel, authProvider, theme, context),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, hasMiniPlayer ? 140 : 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Search Field
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ابحث عن ما تريد...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.search,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Bento Grid (2x2)
              Row(
                children: [
                  Expanded(
                    child: _buildBentoItem(
                      title: 'راديو',
                      icon: Icons.radio_rounded,
                      primaryColor: theme.colorScheme.primary,
                      onTap: () => context.read<AppNavigationState>().setSelectedIndex(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBentoItem(
                      title: 'ريلز',
                      icon: Icons.play_circle_outline_rounded,
                      primaryColor: const Color(0xFFE57373),
                      onTap: () => context.read<AppNavigationState>().setSelectedIndex(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildBentoItem(
                      title: 'بودكاست',
                      icon: Icons.mic_external_on_rounded,
                      primaryColor: const Color(0xFF64B5F6),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.podcastList),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBentoItem(
                      title: 'مجتمع',
                      icon: Icons.people_outline_rounded,
                      primaryColor: const Color(0xFF81C784),
                      onTap: () => context.read<AppNavigationState>().setSelectedIndex(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Wide Banner (Listen to your favorite channel)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.85),
                      const Color(0xFFE5A93B).withValues(alpha: 0.65),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'استمع الى قناتك المفضلة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<AppNavigationState>().setSelectedIndex(2);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text(
                              'تشغيل الراديو',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Opacity(
                      opacity: 0.15,
                      child: Icon(
                        Icons.radio_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Continue Reading Header
              _buildSectionHeader(
                theme,
                'تابع القراءة',
                'متابعة الكل >',
                onActionPressed: () {
                  Navigator.pushNamed(context, AppRoutes.search);
                },
              ),
              const SizedBox(height: 16),

              // 5. Continue Reading Book Card
              _buildContinueReadingCard(theme, context),
              const SizedBox(height: 32),

              // 6. Discover a New World Header
              _buildSectionHeader(
                theme,
                'اكتشف عالم جديد',
                'عرض الجميع >',
                onActionPressed: () {
                  Navigator.pushNamed(context, AppRoutes.search);
                },
              ),
              const SizedBox(height: 16),

              // 7. Discover Categories Tab List
              _buildDiscoverCategories(theme),
              const SizedBox(height: 16),

              // 8. Discover Books Carousel list
              _buildDiscoverBooksList(theme, context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(
    ProfileViewModel profileViewModel,
    AuthProvider authProvider,
    ThemeData theme,
    BuildContext context,
  ) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.6),
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Avatar + KutubFM Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: _buildAvatarWidget(profileViewModel, authProvider, theme),
              ),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    const TextSpan(text: 'Kutub'),
                    TextSpan(
                      text: 'FM',
                      style: TextStyle(
                        color: theme.colorScheme.primary, // Gold/primary color
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Right side: Stats + Notifications Bell
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary, size: 24),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('إحصائيات القراءة ستتوفر قريباً!', textDirection: TextDirection.rtl),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.primary, size: 24),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا توجد إشعارات جديدة حالياً.', textDirection: TextDirection.rtl),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(
    ProfileViewModel profileViewModel,
    AuthProvider authProvider,
    ThemeData theme,
  ) {
    // 1. Loading State
    if (profileViewModel.isLoading ||
        (profileViewModel.status == ProfileStatus.initial)) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2C2C2B),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ),
      );
    }

    // 2. Error or Guest / Unauthenticated State
    final profile = profileViewModel.profile;
    if (profile == null || profileViewModel.status == ProfileStatus.error) {
      final name = authProvider.isGuest ? 'زائر' : (authProvider.user?.displayName ?? 'مستخدم');
      return _buildFallbackAvatar(name, theme);
    }

    // 3. Loaded State
    final avatarUrl = profile.avatarUrl;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return _buildFallbackAvatar(profile.name, theme);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: const Color(0xFF2C2C2B),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(profile.name, theme);
          },
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name, ThemeData theme) {
    final initials = _getInitials(name);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2C2C2B),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      if (parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}';
      }
    }
    return parts[0].isNotEmpty ? parts[0][0] : '?';
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    String actionText, {
    VoidCallback? onActionPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: onActionPressed ?? () {},
            child: Text(
              actionText,
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildBentoItem({
    required String title,
    required IconData icon,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Stack(
          children: [
            // Abstract shape
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.18),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: primaryColor,
                    size: 26,
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueReadingCard(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cover Image (on the right in RTL)
          Container(
            width: 80,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              image: const DecorationImage(
                image: AssetImage('assets/miah_aam_cover.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. Details (on the left in RTL)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مئة عام من العزلة',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أحمد خالد توفيق',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Indicator
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '٧٥٪',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Resume Reading Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.bookReader,
                        arguments: const BookReaderScreenArgs(
                          pdfAssetPath: 'miah_aam',
                          bookTitle: 'مئة عام من العزلة',
                          audioUrl: '',
                          chapterId: 'ch1',
                          transcript: 'الفصل الأول من رواية مئة عام من العزلة...',
                          bookCoverUrl: 'assets/miah_aam_cover.png',
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text(
                      'استكمال القراءة',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverCategories(ThemeData theme) {
    final categories = ['مخصص لك', 'خيال علمي', 'تشويق', 'رومانسي'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : const Color(0xFF2C2C2B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverBooksList(ThemeData theme, BuildContext context) {
    final books = _discoverBooks[_selectedCategory] ?? [];
    if (books.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('لا توجد كتب في هذا القسم حالياً'),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final book = books[index];
          final isLiked = _likedBookIds.contains(book.id);
          return SizedBox(
            width: 120,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.bookDetails,
                  arguments: 'miah_aam',
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image with Heart icon
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(book.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isLiked) {
                                _likedBookIds.remove(book.id);
                              } else {
                                _likedBookIds.add(book.id);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            child: Icon(
                              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isLiked ? Colors.red : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Author
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
