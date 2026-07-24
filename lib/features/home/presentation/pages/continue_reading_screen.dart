import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/core/routes/app_routes.dart';
import 'package:kutub_fm/features/book_reader/presentation/pages/book_reader_screen.dart';
import 'package:kutub_fm/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:kutub_fm/features/profile/domain/entities/user_profile.dart';

class ContinueReadingScreen extends StatefulWidget {
  const ContinueReadingScreen({super.key});

  @override
  State<ContinueReadingScreen> createState() => _ContinueReadingScreenState();
}

class _ContinueReadingScreenState extends State<ContinueReadingScreen> {
  final Set<String> _likedBookIds = {};

  static const List<ContinueListeningItem> _defaultContinueItems = [
    ContinueListeningItem(
      id: 'book_isolation',
      title: 'كيف تركت العزلة',
      author: 'رجب البابورجي',
      coverUrl: 'assets/profile/imgRectangle1.png',
      progress: 0.10,
      lastChapter: 'الفصل الأول',
    ),
    ContinueListeningItem(
      id: 'book_100_years',
      title: 'مئة عام من العزلة',
      author: 'أحمد خالد توفيق',
      coverUrl: 'assets/profile/imgImage26.png',
      progress: 0.45,
      lastChapter: 'الفصل الرابع',
    ),
    ContinueListeningItem(
      id: 'book_season_migration',
      title: 'موسم الهجرة إلى الشمال',
      author: 'الطيب صالح',
      coverUrl: 'assets/profile/imgImage27.png',
      progress: 0.70,
      lastChapter: 'الفصل السابع',
    ),
    ContinueListeningItem(
      id: 'cover_barefoot_bread',
      title: 'الخبز الحافي',
      author: 'محمد شكري',
      coverUrl: 'assets/cover_barefoot_bread.png',
      progress: 0.25,
      lastChapter: 'الفصل الثاني',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<ProfileViewModel>();
    final userContinueList = profileViewModel.profile?.continueListening ?? const [];
    final items = userContinueList.isNotEmpty ? userContinueList : _defaultContinueItems;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF040707),
        appBar: AppBar(
          backgroundColor: const Color(0xFF040707),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'تابع القراءة',
            style: TextStyle(
              color: Color(0xFFF4F4F4),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'ThmanyahSans',
            ),
          ),
          centerTitle: true,
        ),
        body: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildReadingProgressCard(item),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadingProgressCard(ContinueListeningItem item) {
    final isLiked = _likedBookIds.contains(item.id);
    final progressPercent = (item.progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cover Thumbnail (Right in RTL)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              item.coverUrl.isNotEmpty ? item.coverUrl : 'assets/profile/imgRectangle1.png',
              width: 90,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/profile/imgRectangle1.png',
                width: 90,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Book Details (Left in RTL)
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
                            style: const TextStyle(
                              color: Color(0xFFF4F4F4),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ThmanyahSans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.author,
                            style: const TextStyle(
                              color: Color(0xFFBDBDBD),
                              fontSize: 13,
                              fontFamily: 'ThmanyahSans',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? Colors.red : const Color(0xFFBDBDBD),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isLiked) {
                            _likedBookIds.remove(item.id);
                          } else {
                            _likedBookIds.add(item.id);
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Percentage & Bar
                Row(
                  children: [
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: item.progress > 0 ? item.progress : 0.1,
                          backgroundColor: const Color(0xFF393939),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFC5C5C5),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // "إكمال القراءة" Action Button
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.bookReader,
                      arguments: BookReaderScreenArgs(
                        pdfAssetPath: item.id,
                        bookTitle: item.title,
                        audioUrl: '',
                        chapterId: item.id,
                        transcript: null,
                        bookCoverUrl: item.coverUrl,
                      ),
                    );
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
                        const Text(
                          'إكمال القراءة',
                          style: TextStyle(
                            color: Color(0xFF1F1F1F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ThmanyahSans',
                          ),
                        ),
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          'assets/nav_books.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1F1F1F),
                            BlendMode.srcIn,
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
    );
  }
}
