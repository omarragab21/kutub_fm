import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../audio_player/presentation/pages/audio_player_screen.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';
import 'package:kutub_fm/core/routes/app_routes.dart';
import '../../data/repositories/book_details_repository_impl.dart';
import '../../domain/entities/book_detail_model.dart';
import '../viewmodels/book_details_view_model.dart';
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
  void initState() {
    super.initState();
    if (widget.bookId != null) {
      // ViewModel will be created and load data automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookDetailsViewModel(
        repository: BookDetailsRepositoryImpl(),
        bookId: widget.bookId ?? '',
      ),
      child: Consumer<BookDetailsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF0C0C0C),
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (viewModel.errorMessage != null) {
            return Scaffold(
              backgroundColor: const Color(0xFF0C0C0C),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final book = viewModel.book;
          if (book == null) {
            return const Scaffold(
              backgroundColor: Color(0xFF0C0C0C),
              body: Center(
                child: Text(
                  'الكتاب غير موجود',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final hasAudio = book.chapters.any((chapter) => chapter.hasAudioUrl);
          final hasChapters = book.chapters.isNotEmpty;
          final hasPdf = book.pdfUrl.isNotEmpty;

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
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: _getImageProvider(book.imageUrl),
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
                                      Colors.black.withValues(alpha: 0.3),
                                      const Color(0xFF0C0C0C).withValues(alpha: 0.8),
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
                                    // Action icons on the right in RTL
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.share_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: viewModel.toggleFavorite,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              viewModel.isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: viewModel.isFavorite
                                                  ? Colors.red
                                                  : Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Back button on the left in RTL
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
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
                                          color: Colors.black.withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                      image: DecorationImage(
                                        image: _getImageProvider(book.imageUrl),
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
                                          children: [
                                            if (hasAudio)
                                              const Icon(
                                                Icons.headphones,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            if (hasAudio && hasPdf)
                                              const SizedBox(width: 4),
                                            if (hasPdf)
                                              const Icon(
                                                Icons.menu_book,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            if (hasAudio || hasPdf)
                                              const SizedBox(width: 4),
                                            Text(
                                              book.category,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
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
                                  Text(
                                    book.title,
                                    style: const TextStyle(
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
                                      builder: (_) => CreatorDetailsPage(
                                        args: CreatorDetailsArgs(
                                          creatorId: book.authorId,
                                          displayName: book.author,
                                          roleLabel: 'مؤلف',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  book.author,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Rating (Figma: 4.8 + 5 stars)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                            
                                  const SizedBox(width: 4),
                                  ...List.generate(5, (index) {
                                    final clampedRating = book.rating.clamp(0.0, 5.0);
                                    final roundedRating = (clampedRating * 2).round() / 2;
                                    final starValue = index + 1;
                                    final isFilled = starValue <= roundedRating;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 0.5,
                                      ),
                                      child: isFilled ? SvgPicture.asset("assets/star_filled.svg"): SvgPicture.asset("assets/star_unfilled.svg"));
                                  }),SizedBox(width: 8.w,),
                                        Text(
                                    book.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 16,
                                      fontFamily: 'ThmanyahSans',
                                      fontWeight: FontWeight.w400,
                                      height: 1.50,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Metadata
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (book.author.isNotEmpty)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildMetadataItem(book.author, 'مؤلف', () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreatorDetailsPage(
                                                args: CreatorDetailsArgs(
                                                  creatorId: book.authorId,
                                                  displayName: book.author,
                                                  roleLabel: 'مؤلف',
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        if (book.publisherName.isNotEmpty) ...[
                                          _buildMetadataDivider(),
                                          _buildMetadataItem(
                                            book.publisherName,
                                            'ناشر',
                                            () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => CreatorDetailsPage(
                                                    args: CreatorDetailsArgs(
                                                      creatorId: book.publisherId,
                                                      displayName: book.publisherName,
                                                      roleLabel: 'ناشر',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  if (book.narrator.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildMetadataItem(book.narrator, 'راوي', () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreatorDetailsPage(
                                                args: CreatorDetailsArgs(
                                                  creatorId: book.narratorId,
                                                  displayName: book.narrator,
                                                  roleLabel: 'راوي',
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        if (book.translator.isNotEmpty) ...[
                                          _buildMetadataDivider(),
                                          _buildMetadataItem(book.translator, 'مترجم', () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CreatorDetailsPage(
                                                  args: CreatorDetailsArgs(
                                                    creatorId: book.translatorId,
                                                    displayName: book.translator,
                                                    roleLabel: 'مترجم',
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Action Buttons (Figma: Listen sample + Read sample)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    // Listen sample button (right side in RTL)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _openListenSample(context, book),
                                        child: Container(
                                          height: 50.h,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 13.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFBD10),
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/play.svg',
                                                colorFilter: const ColorFilter.mode(
                                                  Color(0xFF1F1F1F),
                                                  BlendMode.srcIn,
                                                ),
                                                width: 24.w,
                                                height: 24.h,
                                              ),
                                              SizedBox(width: 8.w),
                                              Flexible(
                                                child: Text(
                                                  'استمع إلى عيّنة',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: const Color(0xFF1F1F1F),
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'ThmanyahSans',
                                                    height: 1.50,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    // Read sample button (left side in RTL)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _openReadSample(context, book),
                                        child: Container(
                                          height: 50.h,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 13.h,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFF333333),
                                              width: 1.w,
                                            ),
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/nav_books.svg',
                                                colorFilter: const ColorFilter.mode(
                                                  Color(0xFFF4F4F4),
                                                  BlendMode.srcIn,
                                                ),
                                                width: 24.w,
                                                height: 24.h,
                                              ),
                                              SizedBox(width: 8.w),
                                              Flexible(
                                                child: Text(
                                                  'اقرأ عيّنة',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: const Color(0xFFF4F4F4),
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'ThmanyahSans',
                                                    height: 1.50,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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
                    if (hasChapters) _buildTextTab(1, 'الفصول'),
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
                    book.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // About Author
              if (book.author.isNotEmpty)
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
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: book.authorId.isNotEmpty
                                    ? NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(book.author)}&background=random')
                                    : null,
                                child: book.authorId.isEmpty
                                    ? Text(
                                        book.author.isNotEmpty ? book.author[0] : '?',
                                        style: const TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.author,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (book.authorLife.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        book.authorLife,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
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
                      if (book.pages > 0) _buildDetailRow('عدد الصفحات', '${book.pages} صفحة'),
                      _buildDetailRow('المؤلف', book.author),
                      if (book.language.isNotEmpty) _buildDetailRow('اللغة', book.language),
                      if (book.publisherName.isNotEmpty) _buildDetailRow('الناشر', book.publisherName),
                      if (book.duration.isNotEmpty) _buildDetailRow('المدة', book.duration),
                    ],
                  ),
                ),
              ),
              if (viewModel.publisherBooks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'كتب لنفس دار النشر',
                              style: TextStyle(
                                color: Color(0xFFF4F4F4),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'ThmanyahSans',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreatorDetailsPage(
                                      args: CreatorDetailsArgs(
                                        creatorId: book.publisherId,
                                        displayName: book.publisherName,
                                        roleLabel: 'ناشر',
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 230.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: viewModel.publisherBooks.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final pubBook = viewModel.publisherBooks[index];
                              return SizedBox(
                                width: 104.w,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookDetailsPage(bookId: pubBook.id),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                            image: _getImageProvider(pubBook.imageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        pubBook.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'ThmanyahSans',
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pubBook.author,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 11,
                                          fontFamily: 'ThmanyahSans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ] else if (_selectedTabIndex == 1 && hasChapters) ...[
              // Chapters List Tab view
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ...book.chapters.asMap().entries.map((entry) {
                      final index = entry.key;
                      final chapter = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildChapterListItem(book, chapter, index + 1),
                      );
                    }),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ] else if (_selectedTabIndex == 4) ...[
              // Reviews Tab
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (book.comments.isEmpty)
                      const Center(
                        child: Text(
                          'لا توجد مراجعات بعد',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ...book.comments.map((comment) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildCommentItem(comment),
                        );
                      }),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ],
        ),
      ),
            );
        },
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

  Widget _buildCommentItem(BookComment comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.userAvatar.isNotEmpty
                    ? NetworkImage(comment.userAvatar)
                    : null,
                child: comment.userAvatar.isEmpty
                    ? Text(
                        comment.userName.isNotEmpty ? comment.userName[0] : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
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

  Widget _buildChapterListItem(BookDetail book, Chapter chapter, int index) {
    final hasAudio = chapter.hasAudioUrl;

    return Container(
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
          // Left side: Read (always) + Play (audio only)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasAudio)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(
                          name: AppRoutes.audioPlayer,
                        ),
                        builder: (_) => AudioPlayerScreen(
                          bookId: book.id,
                          bookTitle: book.title,
                          authorName: book.author,
                          coverUrl: book.imageUrl,
                          pdfUrl: book.pdfUrl,
                          chapters: book.chapters,
                        ),
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/play.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white54,
                      BlendMode.srcIn,
                    ),
                    width: 24,
                    height: 24,
                  ),
                ),
              if (hasAudio) const SizedBox(width:20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: AppRoutes.bookReader),
                      builder: (_) => BookReaderScreen(
                        bookId: book.id,
                        chapterId: chapter.id,
                        pdfUrl: book.pdfUrl,
                        startPage: chapter.startPage,
                        endPage: chapter.endPage,
                        bookTitle: book.title,
                        chapterTitle: chapter.title,
                        audioUrl: chapter.audioUrl,
                        transcription: chapter.transcription,
                        chapters: book.chapters,
                      ),
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
          // Middle side: Chapter Title and duration
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapter.duration,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 12,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right side: Audio wave if chapter has audio, otherwise sequential index circle
          if (hasAudio)
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
                  index.toString(),
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
    );
  }

  void _openReadSample(BuildContext context, BookDetail book) {
    if (book.pdfUrl.trim().isEmpty) {
      _showSampleUnavailable(context, 'لا يتوفر نص للقراءة');
      return;
    }
    final lastChapter = _lastChapter(book);
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.bookReader),
        builder: (_) => lastChapter != null
            ? BookReaderScreen(
                bookId: book.id,
                chapterId: lastChapter.id,
                pdfUrl: book.pdfUrl,
                startPage: lastChapter.startPage,
                endPage: lastChapter.endPage,
                bookTitle: book.title,
                chapterTitle: lastChapter.title,
                audioUrl: lastChapter.audioUrl,
                transcription: lastChapter.transcription,
                chapters: book.chapters,
              )
            : BookReaderScreen(
                pdfUrl: book.pdfUrl,
                bookTitle: book.title,
                chapters: book.chapters,
              ),
      ),
    );
  }

  void _openListenSample(BuildContext context, BookDetail book) {
    final lastAudioChapter = _lastAudioChapter(book);
    if (lastAudioChapter == null) {
      _showSampleUnavailable(context, 'لا يتوفر صوت للاستماع');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.audioPlayer),
        builder: (_) => AudioPlayerScreen(
          bookId: book.id,
          bookTitle: book.title,
          authorName: book.author,
          coverUrl: book.imageUrl,
          pdfUrl: book.pdfUrl,
          chapters: book.chapters,
          initialChapterId: lastAudioChapter.id,
        ),
      ),
    );
  }

  Chapter? _lastChapter(BookDetail book) {
    if (book.chapters.isEmpty) return null;
    return book.chapters.reduce(
      (a, b) => a.orderIndex > b.orderIndex ? a : b,
    );
  }

  Chapter? _lastAudioChapter(BookDetail book) {
    final audioChapters =
        book.chapters.where((ch) => ch.hasAudioUrl).toList();
    if (audioChapters.isEmpty) return null;
    return audioChapters.reduce(
      (a, b) => a.orderIndex > b.orderIndex ? a : b,
    );
  }

  void _showSampleUnavailable(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'ThmanyahSans'),
        ),
        backgroundColor: const Color(0xFF1F1F1F),
      ),
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
              color: Colors.white.withValues(alpha: 0.5),
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
