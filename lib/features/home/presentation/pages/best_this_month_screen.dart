import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../viewmodels/home_view_model.dart';

class BestThisMonthScreen extends StatefulWidget {
  final bool isMostSelling;

  const BestThisMonthScreen({super.key, this.isMostSelling = false});

  @override
  State<BestThisMonthScreen> createState() => _BestThisMonthScreenState();
}

class _BestThisMonthScreenState extends State<BestThisMonthScreen> {
  final Set<String> _likedBookIds = {};

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final books = widget.isMostSelling
        ? viewModel.recommendedBooks.where((b) => b.isBestseller).toList()
        : viewModel.recommendedBooks.where((b) => b.isBestOfMonth).toList();

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
                child: books.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد كتب متوفرة حالياً',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.52, 
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          final isLiked = _likedBookIds.contains(book.id);
                          final isAsset = book.coverUrl.startsWith('assets/');
                          final imageProvider = isAsset
                              ? AssetImage(book.coverUrl) as ImageProvider
                              : NetworkImage(book.coverUrl) as ImageProvider;
                          
                          return GestureDetector(
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
                                  book.title,
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
                                  book.author,
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
        Text(
          widget.isMostSelling ? 'الأكثر مبيعاً' : 'الأفضل هذا الشهر',
          style: const TextStyle(
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
