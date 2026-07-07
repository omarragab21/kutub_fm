import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/routes/app_routes.dart';

class CollectionDetailsArgs {
  final String title;

  CollectionDetailsArgs({required this.title});
}

class CollectionDetailsScreen extends StatefulWidget {
  final CollectionDetailsArgs args;

  const CollectionDetailsScreen({super.key, required this.args});

  @override
  State<CollectionDetailsScreen> createState() =>
      _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  final Set<String> _likedBookIds = {};

  // Mock collections with books
  final Map<String, List<Map<String, dynamic>>> _collectionBooks = {
    'إدارة الأموال والغنى': [
      {
        'id': 'col_1',
        'title': 'التفكير السريع والبطيء',
        'author': 'دانيال كانمان',
        'cover': 'assets/cover_salt_cities.png',
      },
      {
        'id': 'col_2',
        'title': 'الأب الغني والأب الفقير',
        'author': 'روبرت كيوساكي',
        'cover': 'assets/cover_barefoot_bread.png',
      },
      {
        'id': 'col_3',
        'title': 'فن الحرب',
        'author': 'سون تزو',
        'cover': 'assets/cover_men_in_sun.png',
      },
      {
        'id': 'col_4',
        'title': 'قواعد العمل',
        'author': 'ريتشارد تمبلر',
        'cover': 'assets/cover_memory_body.png',
      },
      {
        'id': 'col_5',
        'title': 'مئة عام من العزلة',
        'author': 'غابرييل غارسيا ماركيز',
        'cover': 'assets/cover_jewish_girl.png',
      },
    ],
    'قصص وأساطير': [
      {
        'id': 'col_6',
        'title': 'ألف ليلة وليلة',
        'author': 'غير معروف',
        'cover': 'assets/cover_thousand_nights.png',
      },
      {
        'id': 'col_7',
        'title': 'مدن الملح',
        'author': 'عبد الرحمن منيف',
        'cover': 'assets/cover_salt_cities.png',
      },
      {
        'id': 'col_8',
        'title': 'الخبز الحافي',
        'author': 'محمد شكري',
        'cover': 'assets/cover_barefoot_bread.png',
      },
    ],
    'أدب عربي': [
      {
        'id': 'col_9',
        'title': 'رجال في الشمس',
        'author': 'غسان كنفاني',
        'cover': 'assets/cover_men_in_sun.png',
      },
      {
        'id': 'col_10',
        'title': 'ذاكرة الجسد',
        'author': 'أحلام مستغانمي',
        'cover': 'assets/cover_memory_body.png',
      },
      {
        'id': 'col_11',
        'title': 'في قلبي أنثى عبرية',
        'author': 'خولة حمدي',
        'cover': 'assets/cover_jewish_girl.png',
      },
    ],
  };

  // Subtitle/Description mapping
  String _getSubtitle(String title) {
    if (title.contains('أموال') || title.contains('الأموال')) {
      return 'كيف تصبح غنياً في عالم يزداد فقراً.';
    } else if (title.contains('قصص')) {
      return 'دعنا نترك هذا العالم ولنغادر لعالم يسحرنا !';
    } else {
      return 'حيث تحكي الكلمات ما عجز الزمن عن روايته.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.args.title;
    final subtitle = _getSubtitle(title);

    // Normalize mapping keys
    String normalizedKey = _collectionBooks.keys.firstWhere(
      (k) => k.replaceAll(' ', '') == title.replaceAll(' ', ''),
      orElse: () => 'إدارة الأموال والغنى',
    );
    final books = _collectionBooks[normalizedKey] ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: _buildHeader(),
              ),
              const SizedBox(height: 8),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 24),

              // Title and Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFBD10),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$subtitle ترشيحات منتقاة بعناية من فريقنا لتجد ما يستحق وقتك.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grid List of Books
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final isLiked = _likedBookIds.contains(book['id']);

                    return GestureDetector(
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
                          AspectRatio(
                            aspectRatio: 114 / 148,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    book['cover']!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
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
                                      width: 27,
                                      height: 27,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 2.5,
                                            sigmaY: 2.5,
                                          ),
                                          child: Center(
                                            child: SvgPicture.asset(
                                              'assets/heart.svg',
                                              width: 14,
                                              height: 14,
                                              colorFilter: ColorFilter.mode(
                                                isLiked
                                                    ? const Color(0xFFFF4B4B)
                                                    : Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Title
                          Text(
                            book['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Author
                          Text(
                            book['author']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'عالم الكتب',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن عالمك الخاص...',
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
}
