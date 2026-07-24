import 'dart:ui';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kutub_fm/core/navigation/app_bottom_nav_tab.dart';
import 'package:kutub_fm/core/navigation/app_navigation_state.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/features/profile/presentation/pages/profile_screen.dart';
import 'package:kutub_fm/features/book_reader/presentation/pages/book_reader_screen.dart';
import "../../../../core/audio/audio_provider.dart";
import "../../../../core/routes/app_routes.dart";
import "../viewmodels/home_view_model.dart";
import 'package:kutub_fm/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:kutub_fm/features/auth/presentation/providers/auth_provider.dart';
import 'package:kutub_fm/features/audio_library/presentation/pages/audio_library_screen.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/category_entity.dart';

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

class _QuickCardImageSpec {
  final double size;
  final double left;
  final double bottom;
  final double angleDeg;

  const _QuickCardImageSpec({
    required this.size,
    required this.left,
    required this.bottom,
    required this.angleDeg,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryId = 'for_you';
  final Set<String> _likedBookIds = {};

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

    return Container(
      color: const Color(0xFF040707),
      child: CustomScrollView(
        slivers: [
          // Custom App Bar
          _buildSliverAppBar(profileViewModel, authProvider, theme, context),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, hasMiniPlayer ? 140 : 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Search Field
                _buildSearchBar(context),
                const SizedBox(height: 16),

                // 2. Bento Grid (2x2 Category Cards)
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'بودكاست',
                        backgroundColor: const Color(0xFFEA5455),
                        imagePath: 'assets/podcast.png',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.podcastList),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'كتب',
                        backgroundColor: const Color(0xFFEA7C54),
                        imagePath: 'assets/books_icon.png',
                        onTap: () => context
                            .read<AppNavigationState>()
                            .setSelectedTab(AppBottomNavTab.library),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'مجتمع',
                        backgroundColor: const Color(0xFF54A1EA),
                        imagePath: 'assets/coumnity.png',
                        onTap: () => context
                            .read<AppNavigationState>()
                            .setSelectedTab(AppBottomNavTab.community),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'إذاعة',
                        backgroundColor: const Color(0xFF2D9F9F),
                        imagePath: 'assets/radio.png',
                        onTap: () => context
                            .read<AppNavigationState>()
                            .setSelectedTab(AppBottomNavTab.radio),
                      ),
                    ),
                  ],
                ),
                // 3. Wide Banner (Listen to your favorite channel)
                const SizedBox(
                  height: 32,
                ), // Add top spacing to match the bottom spacing
                _buildPodcastBanner(context),
                const SizedBox(height: 32),

                // 4. Continue Reading Header
                _buildSectionHeader(
                  theme,
                  'تابع القراءة',
                  'متابعة الكل',
                  onActionPressed: () {
                    Navigator.pushNamed(context, AppRoutes.continueReading);
                  },
                ),
                const SizedBox(height: 16),

                // 5. Continue Reading Book Card
                _buildContinueReadingCard(
                  theme,
                  context,
                  viewModel,
                  profileViewModel,
                ),
                const SizedBox(height: 20),

                // 6. Discover a New World Header
                _buildSectionHeader(
                  theme,
                  'اكتشف عالم جديد',
                  'عرض الجميع',
                  onActionPressed: () {
                    Navigator.pushNamed(context, AppRoutes.bookWorld);
                  },
                ),
                const SizedBox(height: 16),

                // 7. Discover Categories Tab List
                _buildDiscoverCategories(theme, viewModel),
                const SizedBox(height: 16),

                // 8. Discover Books Carousel list
                _buildDiscoverBooksList(theme, context, viewModel),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.search),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/search_01.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFFBDBDBD),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ابحث عن ما تريد...',
              style: TextStyle(
                color: Color(0xFFBDBDBD),
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, _QuickCardImageSpec> _quickCardSpecs = {
    'بودكاست': _QuickCardImageSpec(
      size: 100,
      left: -35,
      bottom: -28,
      angleDeg: -30,
    ),
    'كتب': _QuickCardImageSpec(size: 82, left: -6, bottom: -16, angleDeg: 5),
    'مجتمع': _QuickCardImageSpec(
      size: 90,
      left: -24,
      bottom: -22,
      angleDeg: 12,
    ),
    'إذاعة': _QuickCardImageSpec(
      size: 86,
      left: -8,
      bottom: -18,
      angleDeg: 12,
    ),
  };

  Widget _buildCategoryCard({
    required String title,
    required Color backgroundColor,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    final spec = _quickCardSpecs[title] ??
        const _QuickCardImageSpec(size: 90, left: -10, bottom: -10, angleDeg: 0);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: spec.left,
                bottom: spec.bottom,
                child: Transform.rotate(
                  angle: spec.angleDeg * 3.14159265 / 180,
                  child: Image.asset(
                    imagePath,
                    height: spec.size,
                    width: spec.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodcastBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 172,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
        image: const DecorationImage(
          image: AssetImage('assets/podcasst.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 170,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'استمع الى برامجك\nالمفضلة',
                style: TextStyle(
                  color: Color(0xFFF4F4F4),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'حلقات حصرية على تطبيق كتب FM',
                style: TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.podcastList),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBD10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/nav_radio.svg',
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF1F1F1F),
                          BlendMode.srcIn,
                        ),
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'تشغيل البودكاست',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required String assetPath,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1F1F1F),
        ),
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            width: 24,
            height: 24,
          ),
        ),
      ),
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
      expandedHeight: 60,
      backgroundColor: const Color(0xFF040707),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right side (RTL): Avatar + Name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: _buildAvatarWidget(
                  profileViewModel,
                  authProvider,
                  theme,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                profileViewModel.profile?.name ?? 'سامي عامر',
                style: const TextStyle(
                  color: Color(0xFFF4F4F4),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                ),
              ),
            ],
          ),

          // Left side (RTL): Actions (Notification on right, Library on far left)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCircleActionButton(
                assetPath: 'assets/notifiaction.svg',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'لا توجد إشعارات جديدة حالياً.',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildCircleActionButton(
                assetPath: 'assets/libraries.svg',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AudioLibraryScreen(),
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
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Error or Guest / Unauthenticated State
    final profile = profileViewModel.profile;
    if (profile == null || profileViewModel.status == ProfileStatus.error) {
      final name = authProvider.isGuest
          ? 'زائر'
          : (authProvider.user?.displayName ?? 'مستخدم');
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
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
          style: const TextStyle(
            color: Color(0xFFF4F4F4),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: onActionPressed ?? () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFFBDBDBD),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSingleContinueReadingCard({
    required BuildContext context,
    required String bookId,
    required String title,
    required String author,
    required String coverUrl,
    required double progress,
    required String chapterId,
    required String buttonText,
  }) {
    final hasProgress = progress > 0;
    final displayProgress = hasProgress ? progress : 0.75;
    final isLiked = _likedBookIds.contains(bookId);
    final cardWidth =
        (MediaQuery.sizeOf(context).width - 32).clamp(280.0, 400.0);

    return Container(
      width: cardWidth,
      height: 145,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image (right in RTL) - Put it first so it is laid out on the right
            Container(
              width: 113,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: DecorationImage(
                  image: _getImageProvider(coverUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Details (left in RTL)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Align to right (start of RTL is right)
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Author on the right (RTL) - Put it first so it is laid out on the right
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align right in RTL
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFF4F4F4),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBDBDBD),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      // Love / Favorite button on the left (RTL) - Put it second so it is laid out on the left
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (isLiked) {
                              _likedBookIds.remove(bookId);
                            } else {
                              _likedBookIds.add(bookId);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isLiked
                                ? Colors.red
                                : const Color(0xFFBDBDBD),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Progress and percentage
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align right in RTL
                    children: [
                      Text(
                        '${(displayProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          height: 3,
                          child: LinearProgressIndicator(
                            value: displayProgress,
                            backgroundColor: const Color(0xFF393939),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFC5C5C5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ), // Spacer replaced by SizedBox of 5 as requested
                  // Yellow Button
                  GestureDetector(
                    onTap: () {
                      if (chapterId.isEmpty) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.bookDetails,
                          arguments: bookId,
                        );
                        return;
                      }
                      Navigator.pushNamed(
                        context,
                        AppRoutes.bookReader,
                        arguments: BookReaderScreenArgs(
                          pdfAssetPath: bookId,
                          bookTitle: title,
                          audioUrl: '',
                          chapterId: chapterId,
                          transcript: null,
                          bookCoverUrl: coverUrl,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFBD10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/nav_books.svg',
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF1F1F1F),
                              BlendMode.srcIn,
                            ),
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildContinueReadingCard(
    ThemeData theme,
    BuildContext context,
    HomeViewModel viewModel,
    ProfileViewModel profileViewModel,
  ) {
    final continueListening = profileViewModel.profile?.continueListening ?? [];
    final List<Map<String, dynamic>> items = [];

    if (continueListening.isNotEmpty) {
      for (final item in continueListening) {
        items.add({
          'bookId': item.id,
          'title': item.title,
          'author': item.author,
          'coverUrl': item.coverUrl,
          'progress': item.progress,
          'chapterId': item.lastChapter.trim(),
          'buttonText': 'إكمال القراءة',
        });
      }
    } else if (viewModel.recommendedBooks.isNotEmpty) {
      final count = viewModel.recommendedBooks.length >= 3
          ? 3
          : viewModel.recommendedBooks.length;
      for (var i = 0; i < count; i++) {
        final item = viewModel.recommendedBooks[i];
        items.add({
          'bookId': item.id,
          'title': item.title,
          'author': item.author,
          'coverUrl': item.coverUrl,
          'progress': 0.65 - (i * 0.2),
          'chapterId': item.id,
          'buttonText': 'إكمال القراءة',
        });
      }
    }

    if (items.isEmpty) {
      items.addAll([
        {
          'bookId': 'book_isolation',
          'title': 'كيف تركت العزلة',
          'author': 'رجب البابورجي',
          'coverUrl': 'assets/profile/imgRectangle1.png',
          'progress': 0.10,
          'chapterId': '1',
          'buttonText': 'إكمال القراءة',
        },
        {
          'bookId': 'book_100_years',
          'title': 'مئة عام من العزلة',
          'author': 'أحمد خالد توفيق',
          'coverUrl': 'assets/profile/imgImage26.png',
          'progress': 0.45,
          'chapterId': '2',
          'buttonText': 'إكمال القراءة',
        },
        {
          'bookId': 'book_season_migration',
          'title': 'موسم الهجرة إلى الشمال',
          'author': 'الطيب صالح',
          'coverUrl': 'assets/profile/imgImage27.png',
          'progress': 0.70,
          'chapterId': '3',
          'buttonText': 'إكمال القراءة',
        },
      ]);
    }

    return SizedBox(
      height: 145, // increased height to 145 to match card
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildSingleContinueReadingCard(
            context: context,
            bookId: item['bookId'],
            title: item['title'],
            author: item['author'],
            coverUrl: item['coverUrl'],
            progress: item['progress'],
            chapterId: item['chapterId'],
            buttonText: item['buttonText'],
          );
        },
      ),
    );
  }

  Widget _buildDiscoverCategories(ThemeData theme, HomeViewModel viewModel) {
    final categories = [
      HomeCategory(id: 'for_you', title: 'مخصص لك', icon: ''),
      ...viewModel.categories,
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategoryId == cat.id;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategoryId = cat.id;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFBD10)
                    : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFBD10)
                      : const Color(0xFF333333),
                ),
              ),
              child: Center(
                child: Text(
                  cat.title,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF1F1F1F)
                        : const Color(0xFFF4F4F4),
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverBooksList(
    ThemeData theme,
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    final List<BookEntity> books;
    if (_selectedCategoryId == 'for_you') {
      final favoriteCategoryIds = viewModel.categories.map((c) => c.id).toSet();
      if (favoriteCategoryIds.isNotEmpty) {
        books = viewModel.recommendedBooks
            .where((book) => book.categoryIds.any((id) => favoriteCategoryIds.contains(id)))
            .toList();
      } else {
        books = viewModel.recommendedBooks;
      }
    } else {
      books = viewModel.recommendedBooks
          .where((book) => book.categoryIds.contains(_selectedCategoryId))
          .toList();
    }

    if (books.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'لا توجد كتب في هذا القسم حالياً',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final book = books[index];
          final isLiked = _likedBookIds.contains(book.id);

          final imageProvider = _getImageProvider(book.coverUrl);

          return SizedBox(
            width: 107,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.bookDetails,
                  arguments: book.id,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image with Glassmorphic Heart icon
                  Stack(
                    children: [
                      Container(
                        width: 107,
                        height: 148,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: imageProvider,
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 2.5,
                                sigmaY: 2.5,
                              ),
                              child: Container(
                                width: 27,
                                height: 27,
                                color: Colors.white.withValues(alpha: 0.2),
                                child: Center(
                                  child: Icon(
                                    isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isLiked ? Colors.red : Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
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
                    style: const TextStyle(
                      color: Color(0xFFF4F4F4),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Author
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
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

  ImageProvider _getImageProvider(String url) {
    if (url.isEmpty) {
      return const AssetImage('assets/book.png');
    }
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    if (url.startsWith('file://')) {
      debugPrint('Invalid file URL passed to image loader: $url');
      return const AssetImage('assets/book.png');
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    debugPrint('Unknown URL format: $url');
    return const AssetImage('assets/book.png');
  }
}
