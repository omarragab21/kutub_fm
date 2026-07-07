import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../audio_player/presentation/pages/audio_player_screen.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';
import 'creator_details_page.dart';

class BookDetailsPage extends StatefulWidget {
  final String? bookId;
  const BookDetailsPage({super.key, this.bookId});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  int _selectedTabIndex = 2; // Active tab is Info/Details by default

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0C0C),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header with Cover and Gradients
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Blurred Background Image
                  ClipRect(
                    child: Container(
                      height: 350,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/miah_aam_cover.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                const Color(0xFF0C0C0C).withOpacity(0.8),
                                const Color(0xFF0C0C0C),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SafeArea(
                    child: Column(
                      children: [
                        // Top Bar Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Action icons on the right in RTL (swap position to follow Figma layout directions)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.share_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              // Back button on the left in RTL (swap position to follow Figma layout directions)
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Book Cover
                        const SizedBox(height: 20),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 180,
                              height: 270,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/miah_aam_cover.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -14,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 72),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: const Color(0x331F1F1F),
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 1,
                                        color: Colors.white.withValues(
                                          alpha: 0.04,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'دراما',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'ThmanyahSans',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Title & Author
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'مئة عام من العزلة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ThmanyahSans',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildPremiumBadge(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreatorDetailsPage(
                                  args: CreatorDetailsArgs(
                                    creatorId: '1',
                                    displayName: 'أحمد خالد توفيق',
                                    roleLabel: 'مؤلف',
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'أحمد خالد توفيق',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '4.8',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ...List.generate(5, (index) {
                              if (index == 4) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1.0,
                                  ),
                                  child: Stack(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/community/imgVector1.svg',
                                        width: 16,
                                        height: 16,
                                      ),
                                      ClipRect(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: 0.5,
                                          child: SvgPicture.asset(
                                            'assets/community/imgVector.svg',
                                            width: 16,
                                            height: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              bool isFilled = index < 4;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1.0,
                                ),
                                child: SvgPicture.asset(
                                  isFilled
                                      ? 'assets/community/imgVector.svg'
                                      : 'assets/community/imgVector1.svg',
                                  width: 16,
                                  height: 16,
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Metadata (Gold highlighted labels to match Figma design)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMetadataItem('فريق بوفو', 'مؤلف', () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreatorDetailsPage(
                                        args: CreatorDetailsArgs(
                                          creatorId: '1',
                                          displayName: 'فريق بوفو',
                                          roleLabel: 'مؤلف',
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                _buildMetadataDivider(),
                                _buildMetadataItem(
                                  'دار الكتب العربية',
                                  'ناشر',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreatorDetailsPage(
                                              args: CreatorDetailsArgs(
                                                creatorId: '2',
                                                displayName: 'فريق بوفو',
                                                roleLabel: 'ناشر',
                                              ),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMetadataItem('نورهان فوزي', 'راوي', () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreatorDetailsPage(
                                        args: CreatorDetailsArgs(
                                          creatorId: '3',
                                          displayName: 'نورهان فوزي',
                                          roleLabel: 'راوي',
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                _buildMetadataDivider(),
                                _buildMetadataItem('بوفو استوديوز', 'منتج', () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreatorDetailsPage(
                                        args: CreatorDetailsArgs(
                                          creatorId: '4',
                                          displayName: 'فريق بوفو',
                                          roleLabel: 'منتج',
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AudioPlayerScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFC00E),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/play.svg',
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                        width: 24,
                                        height: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'استمع إلى عينة',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'ThmanyahSans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const BookReaderScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white54,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/nav_books.svg',
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                        width: 24,
                                        height: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'اقرأ عينة',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'ThmanyahSans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF333333), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTextTab(4, 'مراجعة الكتاب'),
                    _buildTextTab(1, 'الفصول'),
                    _buildTextTab(2, 'عن الكتاب'),
                  ],
                ),
              ),
            ),

            // Dynamic Tab Views
            if (_selectedTabIndex == 2) ...[
              // Description
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'استكشف عالمًا من العزلة الساحرة في "مئة عام من العزلة". حيث تتشابك الأجيال والأحداث في ملحمة فريدة.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // About Author
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عن الكاتب',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 25,
                              backgroundImage: AssetImage(
                                'assets/profile/ahmed_khaled_towfik.png',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'أحمد خالد توفيق',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'كاتب وأديب مصري، اشتهر بالبراعة في الكتابة',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
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
              ),

              // Book Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفاصيل الكتاب',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('عدد الصفحات', '256 صفحة'),
                      _buildDetailRow('المؤلف', 'أحمد خالد توفيق'),
                      _buildDetailRow('تاريخ النشر', '2018'),
                      _buildDetailRow('نوع الكتاب', 'رواية خيال علمي'),
                      _buildDetailRow('الناشر', 'الدار العربية للعلوم'),
                      _buildDetailRow('اللغة', 'العربية'),
                    ],
                  ),
                ),
              ),

              // More from Publisher
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'كتب لنفس دار النشر',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white54),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 195,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildPublisherBookCard(
                              'assets/generated/negotiation_cover.png',
                              'فن الإقناع والتأثير',
                              'نورهان عبد الرحمن',
                            ),
                            const SizedBox(width: 12),
                            _buildPublisherBookCard(
                              'assets/generated/time_cover.png',
                              'رحلة في عالم الفلك',
                              'سامر عبد الله',
                            ),
                            const SizedBox(width: 12),
                            _buildPublisherBookCard(
                              'assets/generated/investing_cover.png',
                              'النبض الرقمي',
                              'ليلى مصطفى',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_selectedTabIndex == 1) ...[
              // Chapters List Tab view matching 19069-11501
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildChapterListItem(
                      'الفصل الأول',
                      '45 دقيقة',
                      '1',
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildChapterListItem(
                      'الفصل الثاني',
                      '50 دقيقة',
                      '2',
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildChapterListItem(
                      'الفصل الثالث',
                      '40 دقيقة',
                      '3',
                      true,
                    ), // Currently playing
                    const SizedBox(height: 12),
                    _buildChapterListItem(
                      'الفصل الرابع',
                      '55 دقيقة',
                      '4',
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildChapterListItem(
                      'الفصل الخامس',
                      '35 دقيقة',
                      '5',
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildChapterListItem(
                      'الفصل السادس',
                      '60 دقيقة',
                      '6',
                      false,
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ] else if (_selectedTabIndex == 4) ...[
              // Reviews Tab view matching community posts
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildReviewCard(
                      'أحمد علي',
                      'من أفضل الكتب التي قرأتها مؤخراً، أسلوب الكاتب مشوق جداً والتفاصيل رائعة.',
                      '5',
                      'قبل يومين',
                    ),
                    const SizedBox(height: 12),
                    _buildReviewCard(
                      'سارة محمد',
                      'رواية خيالية ممتازة، لكن بعض الفصول كانت طويلة جداً. أنصح بقراءتها.',
                      '4',
                      'قبل أسبوع',
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ] else ...[
              // Placeholder for Play and Soundwave tabs
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _selectedTabIndex == 0
                        ? 'محتوى البث الصوتي'
                        : 'مشغل الصوت المدمج',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return SvgPicture.asset(
      'assets/prumuim_icon.svg',
      width: 30,
      height: 30,
      fit: BoxFit.contain,
    );
  }

  Widget _buildTextTab(int index, String label) {
    final isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFFFFBD10) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFFF4F4F4)
                  : const Color(0xFFBDBDBD),
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'ThmanyahSans',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterListItem(
    String title,
    String duration,
    String index,
    bool isPlaying,
  ) {
    return Opacity(
      opacity: isPlaying ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF333333),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Left side: Buttons (Play/Pause + Read Book)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AudioPlayerScreen(),
                      ),
                    );
                  },
                  child: isPlaying
                      ? SvgPicture.asset(
                          'assets/pause.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/play.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white54,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookReaderScreen(),
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/nav_books.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white54,
                      BlendMode.srcIn,
                    ),
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Middle side: Chapter Title and duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Right side: Index circle or Audio Wave
            if (isPlaying)
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/audio_wave.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF333333),
                    width: 1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    index,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(
    String userName,
    String content,
    String rating,
    String time,
  ) {
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
              const ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.person, color: Colors.white54),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final isFilled = index < int.parse(rating);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: SvgPicture.asset(
                      isFilled
                          ? 'assets/community/imgVector.svg'
                          : 'assets/community/imgVector1.svg',
                      width: 14,
                      height: 14,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'ThmanyahSans',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'ThmanyahSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublisherBookCard(
    String imagePath,
    String title,
    String author,
  ) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 120,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 140,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(String value, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 15,
              fontFamily: 'ThmanyahSans',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFBD10),
              fontSize: 15,
              fontFamily: 'ThmanyahSans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataDivider() {
    return const Text(
      ' • ',
      style: TextStyle(color: Color(0xFF616161), fontSize: 14),
    );
  }
}
