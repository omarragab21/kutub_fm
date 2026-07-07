import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/routes/app_routes.dart';
import 'collection_details_screen.dart';

class BookWorldScreen extends StatefulWidget {
  const BookWorldScreen({super.key});

  @override
  State<BookWorldScreen> createState() => _BookWorldScreenState();
}

class _BookWorldScreenState extends State<BookWorldScreen> {
  String _selectedCategory = 'الكل';
  final Set<String> _likedBookIds = {};

  final List<String> _categories = [
    'الكل',
    'خيال علمي',
    'تشويق',
    'رومانسي',
    'اقتصاد',
  ];

  // Mock books for Book World Screen
  final List<Map<String, dynamic>> _allBooks = [
    {
      'id': 'w_1',
      'title': 'تطوير المهارات القيادية',
      'author': 'خالد العتيبي',
      'cover': 'assets/generated/lion_cover.png',
      'category': 'خيال علمي', // For filtering purpose
      'rating': 4.9,
    },
    {
      'id': 'w_2',
      'title': 'فن التفاوض في العلاقات',
      'author': 'ليلى الكردي',
      'cover': 'assets/generated/negotiation_cover.png',
      'category': 'تشويق',
      'rating': 4.8,
    },
    {
      'id': 'w_3',
      'title': 'استراتيجيات بناء الوقت',
      'author': 'أحمد الحسين',
      'cover': 'assets/generated/time_cover.png',
      'category': 'رومانسي',
      'rating': 4.7,
    },
    {
      'id': 'w_4',
      'title': 'رحلة في عالم الفلك',
      'author': 'سامر عبد الله',
      'cover': 'assets/generated/scooter_cover.png',
      'category': 'اقتصاد',
      'rating': 4.6,
    },
  ];

  // Best this month books (Image 1 display)
  final List<Map<String, dynamic>> _bestBooks = [
    {
      'id': 'best_5',
      'title': 'النبض الرقمي',
      'author': 'ليلى مصطفى',
      'cover': 'assets/generated/knight_cover.png',
    },
    {
      'id': 'best_4',
      'title': 'رحلة في عالم الفلك',
      'author': 'سامر عبد الله',
      'cover': 'assets/generated/scooter_cover.png',
    },
    {
      'id': 'best_8',
      'title': 'فن الإقناع والتأثير',
      'author': 'نورهان عبد الرحمن',
      'cover': 'assets/generated/black_box_cover.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredBooks = _selectedCategory == 'الكل'
        ? _allBooks
        : _allBooks.where((b) => b['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar / Title
                _buildHeader(),
                const SizedBox(height: 16),

                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 16),

                // Categories Row
                _buildCategoriesList(),
                const SizedBox(height: 20),

                // Top books list
                _buildHorizontalBookList(filteredBooks),
                const SizedBox(height: 28),

                // Best This Month Section
                _buildSectionHeader(
                  title: 'الأفضل هذا الشهر',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.bestThisMonth),
                ),
                const SizedBox(height: 16),
                _buildHorizontalBookList(
                  _bestBooks,
                  height: 230,
                  isSmall: true,
                ),
                const SizedBox(height: 28),

                // Curated Collections Section
                _buildSectionHeader(
                  title: 'تجميعات خاصة ⭐',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.specialCollections,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCollectionCard(
                  title: 'إدارة الأموال والغنى',
                  subtitle: 'كيف تصبح غنياً في عالم يزداد فقراً',
                  count: 12,
                  covers: [
                    'assets/generated/lion_cover.png',
                    'assets/generated/black_box_cover.png',
                    'assets/generated/investing_cover.png',
                  ],
                ),
                const SizedBox(height: 16),
                _buildCollectionCard(
                  title: 'قصص وأساطير',
                  subtitle: 'دعنا نترك هذا العالم ولنغادر لعالم يسحرنا !',
                  count: 4,
                  covers: [
                    'assets/generated/scooter_cover.png',
                    'assets/generated/negotiation_cover.png',
                    'assets/generated/knight_cover.png',
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title
        const Text(
          'عالم الكتب',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Back Button on left (circular)
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/arrow_back.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                width: 18,
                height: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Search placeholder
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن عالمك الخاص',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.6),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
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
                    ? const Color(0xFFFFC00E)
                    : const Color(0xFF1D1D1C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFC00E)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : Colors.white.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalBookList(
    List<Map<String, dynamic>> books, {
    double height = 240,
    bool isSmall = false,
  }) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final book = books[index];
          final isLiked = _likedBookIds.contains(book['id']);
          final isAsset = book['cover'].toString().startsWith('assets/');
          final imageProvider = isAsset
              ? AssetImage(book['cover']) as ImageProvider
              : NetworkImage(book['cover']) as ImageProvider;

          return SizedBox(
            width: 104.w,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.bookDetails,
                  arguments: book['id'],
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover
                  Stack(
                    children: [
                      Container(
                        width: 104.w,
                        height: 148.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Favorite
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isLiked) {
                                _likedBookIds.remove(book['id']);
                              } else {
                                _likedBookIds.add(book['id']);
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
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked
                                  ? const Color(0xFFFF5252)
                                  : Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    book['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Author
                  Text(
                    book['author'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
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

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onTap,
  }) {
    final showStar = title.contains('⭐');
    final cleanTitle = title.replaceAll('⭐', '').trim();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cleanTitle,
              style: const TextStyle(
                color: Color(0xFFF4F4F4),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showStar) ...[
              const SizedBox(width: 6),
              SvgPicture.asset(
                'assets/prumuim_icon.svg',
                width: 20,
                height: 20,
              ),
            ],
          ],
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard({
    required String title,
    required String subtitle,
    required int count,
    required List<String> covers,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.collectionDetails,
        arguments: CollectionDetailsArgs(title: title),
      ),
      child: Container(
        width: double.infinity,
        height: 260.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF131312),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top row: chip on the LEFT (end) under RTL
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox.shrink(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2CA50),
                                borderRadius: BorderRadius.circular(999.r),
                              ),
                              child: Text(
                                '$count كتب',
                                style: TextStyle(
                                  color: const Color(0xFF11110F),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.sp,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Centered title and description
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFFF7F4E8),
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.58),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildFannedCovers(covers),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFannedCovers(List<String> covers) {
    return SizedBox(
      height: 145.h,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = constraints.maxWidth / 2;

          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 6.h,
                left: center - 120.w,
                child: _buildCoverShadow(width: 240.w),
              ),
              // Left cover (rotated left, positioned further left and lower)
              if (covers.isNotEmpty)
                Positioned(
                  left: -10.w,
                  bottom: -15.h,
                  child: Transform.rotate(
                    angle: -0.15,
                    child: _buildCoverItem(covers[0]),
                  ),
                ),
              // Right cover (rotated right)
              if (covers.length > 2)
                Positioned(
                  right: -10.w,
                  bottom: 8.h,
                  child: Transform.rotate(
                    angle: 0.15,
                    child: _buildCoverItem(covers[2]),
                  ),
                ),
              // Middle cover (straight, on top)
              if (covers.length > 1)
                Positioned(
                  bottom: 0,
                  left: center - 60.w,
                  child: _buildCoverItem(covers[1], isMiddle: true),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoverShadow({required double width}) {
    return Container(
      width: width,
      height: 24.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.52),
            blurRadius: 28,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverItem(String coverAsset, {bool isMiddle = false}) {
    return Container(
      width: (isMiddle ? 120 : 110).w,
      height: (isMiddle ? 160 : 145).h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        image: DecorationImage(
          image: AssetImage(coverAsset),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isMiddle ? 0.48 : 0.36),
            blurRadius: isMiddle ? 18 : 10,
            offset: Offset(0, isMiddle ? 10 : 6),
          ),
        ],
      ),
    );
  }
}
