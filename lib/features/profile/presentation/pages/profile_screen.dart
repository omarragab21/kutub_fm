import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kutub_fm/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:kutub_fm/features/profile/domain/entities/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileView();
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF040707),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  children: [
                    _buildProfileInfo(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildPremiumBanner(),
                    const SizedBox(height: 24),
                    _buildActivityTimeline(context),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right side: Edit Profile Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    profile: const UserProfile(
                      id: '1',
                      name: 'رامي عامر',
                      email: 'example@gmail.com',
                      favoriteCategories: [],
                    ),
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
                        ) async {},
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
                  const SizedBox(width: 4),
                  Text(
                    'تعديل',
                    style: TextStyle(
                      fontFamily: 'ThmanyahSans',
                      color: const Color(0xFFF4F4F4),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Left side: Moon & Back (chevron on far left)
          Row(
            children: [
              // Moon toggle
              Container(
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
              const SizedBox(width: 8),
              // Back Button (chevron_left)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
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

  Widget _buildProfileInfo() {
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
            child: Image.asset(
              'assets/profile/imgAvatar.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'رامي عامر',
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
            _buildFollowLabel('يتابعك 220'),
            const SizedBox(width: 4),
            _buildFollowLabel('تتابع 520'),
          ],
        ),
      ],
    );
  }

  Widget _buildFollowLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatWidget(
          value: '1.5',
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
          value: '35',
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
          value: '3',
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

  Widget _buildPremiumBanner() {
    return Container(
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
          // Right side: Button
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
          // Left side: Logo Stack (smaller than container height of 70)
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
    );
  }

  Widget _buildActivityTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineSectionHeader('قبل ساعة'),
        const SizedBox(height: 8),
        _buildReviewCard(),
        const SizedBox(height: 8),
        _buildPodcastCard(
          title: 'كيف يشكل الكتاب عقلك',
          subtitle: '12 نوفمبر • الحلقة 2',
          duration: '30:00 د',
          coverImage: 'assets/profile/imgFrame115.png',
        ),
        const SizedBox(height: 24),
        _buildTimelineSectionHeader('قبل يومين'),
        const SizedBox(height: 8),
        _buildContinueReadingCard(),
        const SizedBox(height: 8),
        _buildReviewCard2(),
        const SizedBox(height: 8),
        _buildPodcastCard(
          title: 'العادات السبع للأسر الأكثر فعالية',
          subtitle: '6 يونيو • الحلقة 4',
          duration: '01:20 س',
          coverImage: 'assets/profile/imgFrame116.png',
        ),
      ],
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

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/profile/imgAvatar.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رامي عامر',
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFF4F4F4),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '24/5/2026',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBD10),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  'مراجعة',
                  style: TextStyle(
                    fontFamily: 'ThmanyahSans',
                    color: const Color(0xFF1F1F1F),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.only(left: 1.0),
                child: SvgPicture.asset(
                  i < 4
                      ? 'assets/community/imgVector.svg'
                      : 'assets/community/imgVector1.svg',
                  width: 18,
                  height: 18,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'رواية استثنائية، أعادت تشكيل نظرتي للحياة والحب والوجود أسلوب ساحر ومترجم بشكل رائع. أنصح بها بشدة.',
            style: TextStyle(
              fontFamily: 'ThmanyahSans',
              color: const Color(0xFFF4F4F4),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 58,
            padding: const EdgeInsets.only(
              right: 16,
              left: 8,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF808080)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(
                    'assets/profile/imgImage26.png',
                    width: 31,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'مئة عام من العزلة',
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFFF4F4F4),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'أحمد خالد توفيق',
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
          const SizedBox(height: 16),
          Row(
            children: [
              SvgPicture.asset(
                'assets/community/imgVector11.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFBDBDBD),
                  BlendMode.srcIn,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.share_outlined,
                color: const Color(0xFFBDBDBD),
                size: 20,
              ),
              const SizedBox(width: 16),
              _buildActionIcon('assets/community/imgVector6.svg', '20'),
              const SizedBox(width: 16),
              _buildActionIcon('assets/community/imgVector5.svg', '35'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard2() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/profile/imgAvatar.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رامي عامر',
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFF4F4F4),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '7/9/2026',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBD10),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  'مراجعة',
                  style: TextStyle(
                    fontFamily: 'ThmanyahSans',
                    color: const Color(0xFF1F1F1F),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.only(left: 1.0),
                child: SvgPicture.asset(
                  i < 4
                      ? 'assets/community/imgVector.svg'
                      : 'assets/community/imgVector1.svg',
                  width: 18,
                  height: 18,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'عمل أدبي رائع يتناول قضايا الهوية والذاكرة بطريقة فلسفية وعميقة.',
            style: TextStyle(
              fontFamily: 'ThmanyahSans',
              color: const Color(0xFFF4F4F4),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 58,
            padding: const EdgeInsets.only(
              right: 16,
              left: 8,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF808080)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(
                    'assets/profile/imgImage27.png',
                    width: 31,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'موسم الهجرة إلى الشمال',
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFFF4F4F4),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'الطيب صالح',
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
          const SizedBox(height: 16),
          Row(
            children: [
              SvgPicture.asset(
                'assets/community/imgVector11.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFBDBDBD),
                  BlendMode.srcIn,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.share_outlined,
                color: const Color(0xFFBDBDBD),
                size: 20,
              ),
              const SizedBox(width: 16),
              _buildActionIcon('assets/community/imgVector6.svg', '17'),
              const SizedBox(width: 16),
              _buildActionIcon('assets/community/imgVector5.svg', '30'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastCard({
    required String title,
    required String subtitle,
    required String duration,
    required String coverImage,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              coverImage,
              width: 77,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'ThmanyahSans',
                    color: const Color(0xFFBDBDBD),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'ThmanyahSans',
                    color: const Color(0xFFF4F4F4),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
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
                        duration,
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          SvgPicture.asset(
            'assets/profile/imgVector25.svg',
            width: 18,
            height: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/profile/imgRectangle1.png',
              width: 113,
              height: 129,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كيف تركت العزلة',
                          style: TextStyle(
                            fontFamily: 'ThmanyahSans',
                            color: const Color(0xFFF4F4F4),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'رجب البابورجي',
                          style: TextStyle(
                            fontFamily: 'ThmanyahSans',
                            color: const Color(0xFFBDBDBD),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SvgPicture.asset(
                      'assets/profile/imgVector27.svg',
                      width: 18,
                      height: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '10%',
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
                      child: const LinearProgressIndicator(
                        value: 0.1,
                        backgroundColor: Color(0xFF393939),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFC5C5C5),
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(String iconPath, String count) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Color(0xFFBDBDBD),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontFamily: 'ThmanyahSans',
            color: const Color(0xFFBDBDBD),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
