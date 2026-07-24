import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/core/routes/app_routes.dart';
import 'package:kutub_fm/core/audio/audio_provider.dart';
import 'package:kutub_fm/features/profile/domain/entities/user_profile.dart';
import 'package:kutub_fm/features/profile/domain/entities/user_activity.dart';
import 'package:kutub_fm/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:kutub_fm/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:kutub_fm/features/podcast/domain/entities/podcast_episode.dart';
import 'package:kutub_fm/core/stats/user_stats_tracker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProfileViewModel>();
      if (vm.profile == null && !vm.isLoading) {
        vm.fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _ProfileView();
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final profile = viewModel.profile;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF040707),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, viewModel, profile),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  children: [
                    _buildProfileInfo(profile),
                    const SizedBox(height: 24),
                    _buildStatsRow(profile),
                    const SizedBox(height: 24),
                    _buildPremiumBanner(context),
                    const SizedBox(height: 24),
                    _buildActivityTimeline(context, viewModel),
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProfileViewModel viewModel,
    UserProfile? profile,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right side: Edit Profile Button ("تعديل")
          GestureDetector(
            onTap: () {
              final activeProfile =
                  profile ??
                  const UserProfile(
                    id: '1',
                    name: 'رامي عامر',
                    email: 'example@gmail.com',
                    followersCount: 220,
                    followingCount: 520,
                  );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    profile: activeProfile,
                    onSave:
                        (
                          name,
                          email,
                          bio,
                          categories,
                          bListened,
                          lMins,
                          favs,
                          followers,
                          following,
                          weekly,
                          continueList,
                          img,
                        ) async {
                          await viewModel.updateProfile(
                            name: name,
                            email: email,
                            bio: bio,
                            favoriteCategories: categories,
                            totalBooksListened: bListened,
                            totalListeningMinutes: lMins,
                            favoritesCount: favs,
                            followersCount: followers,
                            followingCount: following,
                            weeklyActivityMinutes: weekly,
                            continueListening: continueList,
                            profileImage: img,
                          );
                        },
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  Text(
                    'تعديل',
                    style: TextStyle(
                      fontFamily: 'ThmanyahSans',
                      color: const Color(0xFFF4F4F4),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 6.7,
                          top: 2.5,
                          width: 10.8,
                          height: 10.8,
                          child: SvgPicture.asset(
                            'assets/profile/imgVector13.svg',
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFF4F4F4),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 2.5,
                          top: 4.2,
                          width: 13.3,
                          height: 13.3,
                          child: SvgPicture.asset(
                            'assets/profile/imgVector14.svg',
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFF4F4F4),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Left side: Moon mode & Back chevron
          Row(
            children: [
              // Moon mode toggle button
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تفعيل الوضع الليلي الداكن'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/profile/imgVector2.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Back button (chevron)
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                  }
                },
                child: Container(
                  width: 41,
                  height: 41,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: SvgPicture.asset(
                    'assets/profile/imgVector12.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(UserProfile? profile) {
    final name = profile?.name.isNotEmpty == true ? profile!.name : 'رامي عامر';
    final avatar = profile?.avatarUrl;
    final followers = profile?.followersCount ?? 0;
    final following = profile?.followingCount ?? 0;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFF675),
          ),
          child: ClipOval(
            child: avatar != null && avatar.startsWith('http')
                ? Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/profile/imgAvatar.png',
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    avatar ?? 'assets/profile/imgAvatar.png',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontFamily: 'ThmanyahSans',
            color: const Color(0xFFF4F4F4),
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFollowLabel('يتابعك $followers'),
            const SizedBox(width: 8),
            _buildFollowLabel('تتابع $following'),
          ],
        ),
      ],
    );
  }

  Widget _buildFollowLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'ThmanyahSans',
          color: const Color(0xFFF4F4F4),
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildStatsRow(UserProfile? profile) {
    return AnimatedBuilder(
      animation: UserStatsTracker.instance,
      builder: (context, _) {
        final tracker = UserStatsTracker.instance;
        final listeningHours = tracker.listeningHoursFormatted;
        final pagesRead = '${tracker.totalPagesRead}';
        final streak = '${tracker.streakDays}';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatWidget(
              value: listeningHours,
              label: 'ساعات استماع',
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  children: [
                    Positioned(
                      left: 3.0,
                      top: 3.0,
                      width: 18.0,
                      height: 14.0,
                      child: SvgPicture.asset(
                        'assets/profile/imgVector3.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: 4.0,
                      top: 14.0,
                      width: 5.0,
                      height: 7.0,
                      child: SvgPicture.asset(
                        'assets/profile/imgVector4.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: 15.0,
                      top: 14.0,
                      width: 5.0,
                      height: 7.0,
                      child: SvgPicture.asset(
                        'assets/profile/imgVector5.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildDivider(),
            _buildStatWidget(
              value: pagesRead,
              label: 'صفحات قراءة',
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  children: [
                    Positioned(
                      left: 12.0,
                      top: 2.0,
                      width: 7.0,
                      height: 20.0,
                      child: SvgPicture.asset(
                        'assets/profile/imgVector9.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: 2.0,
                      top: 5.0,
                      width: 10.0,
                      height: 17.0,
                      child: SvgPicture.asset(
                        'assets/profile/imgVector10.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: 12.0,
                      top: 5.0,
                      width: 10.0,
                      height: 17.0,
                      child: SvgPicture.asset(
                        'assets/profile/imgVector11.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildDivider(),
            _buildStatWidget(
              value: streak,
              label: 'أيام حماسة',
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  children: [
                    Positioned(
                      left: 4.0,
                      top: 2.5,
                      width: 16.0,
                      height: 19.0,
                      child: SvgPicture.asset(
                        'assets/profile/imgVector6.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: 8.0,
                      top: 9.5,
                      width: 8.0,
                      height: 9.0,
                      child: SvgPicture.asset(
                        'assets/profile/imgVector7.svg',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 48, color: const Color(0xFF333333));
  }

  Widget _buildStatWidget({
    required String value,
    required String label,
    required Widget icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'ThmanyahSans',
                color: const Color(0xFFF4F4F4),
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ThmanyahSans',
            color: const Color(0xFFBDBDBD),
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الانتقال إلى باقات اشتراك كتب Premium'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF040707),
          border: Border.all(color: const Color(0xFF333333)),
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF040707), Color(0xFFFFBD10)],
            stops: [0.36, 2.04],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Right side: Subscription button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFBD10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'اشترك في كتب Premium',
                style: TextStyle(
                  fontFamily: 'ThmanyahSans',
                  color: const Color(0xFF1F1F1F),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Left side: Badge Logo
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 60,
                    height: 60,
                    child: SvgPicture.asset(
                      'assets/profile/imgBadge.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: 15.5,
                    top: 15.5,
                    width: 29,
                    height: 29,
                    child: Image.asset(
                      'assets/profile/imgKotob141.png',
                      fit: BoxFit.fill,
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

  Widget _buildActivityTimeline(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    final groups = viewModel.activityGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineSectionHeader(group.timeframe),
            const SizedBox(height: 8),
            ...group.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildActivityItemCard(context, viewModel, item),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTimelineSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'ThmanyahSans',
        color: const Color(0xFFBDBDBD),
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildActivityItemCard(
    BuildContext context,
    ProfileViewModel viewModel,
    UserActivityItem item,
  ) {
    switch (item.type) {
      case UserActivityType.reviewPost:
        return _buildReviewPostCard(context, viewModel, item);
      case UserActivityType.podcast:
        return _buildPodcastCard(context, viewModel, item);
      case UserActivityType.continueReading:
        return _buildContinueReadingCard(context, viewModel, item);
      case UserActivityType.radio:
        return _buildPodcastCard(context, viewModel, item);
    }
  }

  // 1. Review / Post Activity Card
  Widget _buildReviewPostCard(
    BuildContext context,
    ProfileViewModel viewModel,
    UserActivityItem item,
  ) {
    return GestureDetector(
      onTap: () {
        // Open Post details screen
        Navigator.pushNamed(
          context,
          AppRoutes.postDetails,
          arguments: {
            'id': item.id,
            'title': item.linkedBookTitle ?? item.title,
            'author': item.linkedBookAuthor ?? item.userName,
            'content': item.textContent,
            'user': item.userName,
            'date': item.date,
            'avatar': item.avatarUrl,
            'bookCover': item.linkedBookCover,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header & Rating
            Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    item.avatarUrl ?? 'assets/profile/imgAvatar.png',
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/profile/imgAvatar.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.userName ?? 'رامي عامر',
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFFF4F4F4),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.date ?? '24/5/2026',
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFFBDBDBD),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Star Rating
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final isFilled = i < item.rating.floor();
                    return Padding(
                      padding: const EdgeInsets.only(left: 1.0),
                      child: SvgPicture.asset(
                        isFilled
                            ? 'assets/community/imgVector.svg'
                            : 'assets/community/imgVector1.svg',
                        width: 18,
                        height: 18,
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review Content Text
            if (item.textContent != null)
              Text(
                item.textContent!,
                style: TextStyle(
                  fontFamily: 'ThmanyahSans',
                  color: const Color(0xFFF4F4F4),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),

            // Hashtags
            if (item.hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: item.hashtags.map((tag) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFFFBD10),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Linked Book Box (Clickable to open Book Details)
            if (item.linkedBookTitle != null)
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.bookDetails,
                    arguments: item.linkedBookId ?? '1',
                  );
                },
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF808080)),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF141414),
                  ),
                  child: Row(
                    children: [
                      // Book Cover
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.asset(
                          item.linkedBookCover ??
                              'assets/profile/imgImage26.png',
                          width: 31,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                            'assets/profile/imgImage26.png',
                            width: 31,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.linkedBookTitle!,
                              style: TextStyle(
                                fontFamily: 'ThmanyahSans',
                                color: const Color(0xFFF4F4F4),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.linkedBookAuthor != null)
                              Text(
                                item.linkedBookAuthor!,
                                style: TextStyle(
                                  fontFamily: 'ThmanyahSans',
                                  color: const Color(0xFFBDBDBD),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/nav_books.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Action Icons Bar: Bookmark, Share, Comment, Like
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right Action Icons (Likes & Comments)
                Row(
                  children: [
                    // Like Button
                    GestureDetector(
                      onTap: () => viewModel.toggleActivityLike(item.id),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/community/imgVector5.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              item.isLiked
                                  ? const Color(0xFFFF4D4D)
                                  : const Color(0xFFBDBDBD),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.likesCount}',
                            style: TextStyle(
                              fontFamily: 'ThmanyahSans',
                              color: const Color(0xFFBDBDBD),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Comment Button
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.postDetails,
                          arguments: {'id': item.id},
                        );
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/community/imgVector6.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFBDBDBD),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.commentsCount}',
                            style: TextStyle(
                              fontFamily: 'ThmanyahSans',
                              color: const Color(0xFFBDBDBD),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Share Button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ رابط المنشور'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.share_outlined,
                        color: const Color(0xFFBDBDBD),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                // Bookmark Icon (Left)
                GestureDetector(
                  onTap: () => viewModel.toggleActivityBookmark(item.id),
                  child: SvgPicture.asset(
                    'assets/community/imgVector11.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      item.isBookmarked
                          ? const Color(0xFFFFBD10)
                          : const Color(0xFFBDBDBD),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. Podcast Activity Card
  Widget _buildPodcastCard(
    BuildContext context,
    ProfileViewModel viewModel,
    UserActivityItem item,
  ) {
    return GestureDetector(
      onTap: () {
        // Open podcast detail page or start playing
        if (item.audioUrl != null && item.audioUrl!.isNotEmpty) {
          final audioProvider = context.read<AudioProvider>();
          audioProvider.playPodcast(
            PodcastEpisode(
              id: item.id,
              title: item.title,
              description: item.subtitle ?? 'بودكاست كتب FM',
              audioUrl: item.audioUrl!,
              imageUrl: item.coverImage ?? 'assets/profile/imgFrame115.png',
              duration: item.duration ?? '30:00',
              category: 'بودكاست',
              views: 1200,
            ),
          );
        }
        Navigator.pushNamed(
          context,
          AppRoutes.podcastDetail,
          arguments: item.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          children: [
            // Cover Image (Right)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.coverImage ?? 'assets/profile/imgFrame115.png',
                width: 77,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/profile/imgFrame115.png',
                  width: 77,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFBDBDBD),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'ThmanyahSans',
                      color: const Color(0xFFF4F4F4),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Duration Pill with Play Button
                  GestureDetector(
                    onTap: () {
                      final audioProvider = context.read<AudioProvider>();
                      audioProvider.playPodcast(
                        PodcastEpisode(
                          id: item.id,
                          title: item.title,
                          description: item.subtitle ?? 'بودكاست كتب FM',
                          audioUrl: item.audioUrl ?? 'assets/audio_book.mp3',
                          imageUrl:
                              item.coverImage ??
                              'assets/profile/imgFrame115.png',
                          duration: item.duration ?? '30:00',
                          category: 'بودكاست',
                          views: 1200,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFBD10),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/profile/imgVector26.svg',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.duration ?? '30:00 د',
                            style: TextStyle(
                              fontFamily: 'ThmanyahSans',
                              color: const Color(0xFF1F1F1F),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Heart Icon (Left)
            GestureDetector(
              onTap: () => viewModel.toggleActivityLike(item.id),
              child: SvgPicture.asset(
                'assets/profile/imgVector25.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  item.isLiked
                      ? const Color(0xFFFF4D4D)
                      : const Color(0xFFBDBDBD),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Continue Reading Activity Card
  Widget _buildContinueReadingCard(
    BuildContext context,
    ProfileViewModel viewModel,
    UserActivityItem item,
  ) {
    final progressPercent = (item.progress * 100).toInt();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.bookReader);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          children: [
            // Book Cover Image (Right)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.coverImage ?? 'assets/profile/imgRectangle1.png',
                width: 113,
                height: 129,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/profile/imgRectangle1.png',
                  width: 113,
                  height: 129,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Content & Action Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: 'ThmanyahSans',
                                color: const Color(0xFFF4F4F4),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.author != null)
                              Text(
                                item.author!,
                                style: TextStyle(
                                  fontFamily: 'ThmanyahSans',
                                  color: const Color(0xFFBDBDBD),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => viewModel.toggleActivityLike(item.id),
                        child: SvgPicture.asset(
                          'assets/profile/imgVector27.svg',
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            item.isLiked
                                ? const Color(0xFFFF4D4D)
                                : const Color(0xFFBDBDBD),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar & Percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$progressPercent%',
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFFBDBDBD),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: LinearProgressIndicator(
                          value: item.progress > 0 ? item.progress : 0.1,
                          backgroundColor: const Color(0xFF393939),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFC5C5C5),
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // "إكمال القراءة" Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.bookReader);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFBD10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'إكمال القراءة',
                            style: TextStyle(
                              fontFamily: 'ThmanyahSans',
                              color: const Color(0xFF1F1F1F),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 10.0,
                                  top: 1.7,
                                  width: 5.8,
                                  height: 16.6,
                                  child: SvgPicture.asset(
                                    'assets/profile/imgVector28.svg',
                                    fit: BoxFit.fill,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF1F1F1F),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 1.7,
                                  top: 4.2,
                                  width: 8.3,
                                  height: 14.1,
                                  child: SvgPicture.asset(
                                    'assets/profile/imgVector29.svg',
                                    fit: BoxFit.fill,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF1F1F1F),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 10.0,
                                  top: 4.2,
                                  width: 8.3,
                                  height: 14.1,
                                  child: SvgPicture.asset(
                                    'assets/profile/imgVector30.svg',
                                    fit: BoxFit.fill,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF1F1F1F),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ],
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
}
