import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/book_collection_entity.dart';
import '../viewmodels/home_view_model.dart';
import 'collection_details_screen.dart';

class SpecialCollectionsScreen extends StatefulWidget {
  const SpecialCollectionsScreen({super.key});

  @override
  State<SpecialCollectionsScreen> createState() =>
      _SpecialCollectionsScreenState();
}

class _SpecialCollectionsScreenState extends State<SpecialCollectionsScreen> {
  List<String> _getCollectionCovers(BookCollectionEntity collection, List<BookEntity> allBooks) {
    final covers = <String>[];
    for (final id in collection.bookIds) {
      final BookEntity? book = allBooks.cast<BookEntity?>().firstWhere(
        (b) => b?.id == id,
        orElse: () => null,
      );
      if (book != null && book.coverUrl.isNotEmpty) {
        covers.add(book.coverUrl);
      }
      if (covers.length >= 3) break;
    }
    while (covers.length < 3) {
      covers.add('');
    }
    return covers;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final collections = viewModel.bookCollections;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 6),
                    Text(
                      'ترشيحات منتقاة بعناية من فريقنا لتجد ما يستحق وقتك.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Collections List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: collections.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    final covers = _getCollectionCovers(collection, viewModel.recommendedBooks);
                    return _buildCollectionCard(
                      id: collection.id,
                      title: collection.title,
                      subtitle: collection.miniDescription,
                      count: collection.bookIds.length,
                      covers: covers,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تجميعات خاصة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/prumuim_icon.svg',
              width: 24,
              height: 24,
            ),
          ],
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

  Widget _buildCollectionCard({
    required String id,
    required String title,
    required String subtitle,
    required int count,
    required List<String> covers,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.collectionDetails,
          arguments: CollectionDetailsArgs(id: id, title: title),
        );
      },
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
    final ImageProvider imageProvider;
    if (coverAsset.isEmpty) {
      imageProvider = const AssetImage('assets/book.png');
    } else if (coverAsset.startsWith('assets/')) {
      imageProvider = AssetImage(coverAsset);
    } else {
      imageProvider = NetworkImage(coverAsset);
    }

    return Container(
      width: (isMiddle ? 120 : 110).w,
      height: (isMiddle ? 160 : 145).h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        image: DecorationImage(
          image: imageProvider,
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
