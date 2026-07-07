import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/routes/app_routes.dart';

class BestThisMonthScreen extends StatefulWidget {
  const BestThisMonthScreen({super.key});

  @override
  State<BestThisMonthScreen> createState() => _BestThisMonthScreenState();
}

class _BestThisMonthScreenState extends State<BestThisMonthScreen> {
  final Set<String> _likedBookIds = {};

  final List<Map<String, dynamic>> _books = [
    {
      'id': 'best_5',
      'title': 'النبض الرقمي',
      'author': 'ليلى مصطفى',
      'cover': 'assets/generated/knight_cover.png',
    },
    {
      'id': 'best_6',
      'title': 'رحلة الاستثمار الناجح',
      'author': 'سارة المارديني',
      'cover': 'assets/generated/investing_cover.png',
    },
    {
      'id': 'best_3',
      'title': 'استراتيجيات بناء الوقت',
      'author': 'أحمد الحسين',
      'cover': 'assets/generated/time_cover.png',
    },
    {
      'id': 'best_2',
      'title': 'فن التفاوض في العلاقات',
      'author': 'ليلى الكردي',
      'cover': 'assets/generated/negotiation_cover.png',
    },
    {
      'id': 'best_1',
      'title': 'تطوير المهارات القيادية',
      'author': 'خالد العتيبي',
      'cover': 'assets/generated/lion_cover.png',
    },
    {
      'id': 'best_4',
      'title': 'رحلة في عالم الفلك',
      'author': 'سامر عبد الله',
      'cover': 'assets/generated/scooter_cover.png',
    },
    {
      'id': 'best_7',
      'title': 'الصندوق الأسود',
      'author': 'حسن عز الدين',
      'cover': 'assets/generated/black_box_cover.png',
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: _buildHeader(),
              ),
              const SizedBox(height: 8),

              // Grid List of Books
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.52, 
                  ),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
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
                          // Cover with Heart Favoriting
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
                                      image: AssetImage(book['cover']),
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
                                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isLiked ? const Color(0xFFFF5252) : Colors.white,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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
                              fontSize: 11.sp,
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
        // Title
        const Text(
          'الأفضل هذا الشهر',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Back Button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
