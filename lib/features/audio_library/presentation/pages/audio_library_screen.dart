import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';
import '../viewmodels/audio_library_viewmodel.dart';
import 'package:share_plus/share_plus.dart';
import '../../../reels/domain/entities/reel_model.dart';

class AudioLibraryScreen extends StatelessWidget {
  const AudioLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioLibraryViewModel(),
      child: const _AudioLibraryContent(),
    );
  }
}

class _AudioLibraryContent extends StatefulWidget {
  const _AudioLibraryContent();

  @override
  State<_AudioLibraryContent> createState() => _AudioLibraryContentState();
}

class _AudioLibraryContentState extends State<_AudioLibraryContent> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AudioLibraryViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // ── Header (مكتبتي) ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Right side: Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مكتبتي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'يمكن للمستخدم تجميع كل ما يحبه في مكان واحد',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Left side: Back Button
                    _buildCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Tabs Bar ──────────────────────────────────────────
              _buildTabSelector(viewModel),
              const SizedBox(height: 16),

              // ── Tab Content ───────────────────────────────────────
              Expanded(
                child: _buildActiveTabContent(context, viewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
      ),
    );
  }

  Widget _buildTabSelector(AudioLibraryViewModel viewModel) {
    final tabs = [
      {'title': 'المفضلة', 'icon': Icons.favorite_border_rounded},
      {'title': 'التنزيلات', 'icon': Icons.download_rounded},
      {'title': 'الإشارات', 'icon': Icons.bookmark_border_rounded},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = viewModel.activeTabIndex == index;
          final tab = tabs[index];
          return Expanded(
            child: GestureDetector(
              onTap: () => viewModel.setActiveTab(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 16,
                      color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['title'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent(BuildContext context, AudioLibraryViewModel viewModel) {
    switch (viewModel.activeTabIndex) {
      case 0:
        return _buildFavoritesTab(context, viewModel);
      case 1:
        return _buildDownloadsTab(context, viewModel);
      case 2:
        return _buildHighlightsTab(context, viewModel);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── FAVORITES TAB ──────────────────────────────────────────────────
  Widget _buildFavoritesTab(BuildContext context, AudioLibraryViewModel viewModel) {
    return Column(
      children: [
        // Filter pills: Books, Podcasts, Reels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildFilterPills(viewModel),
        ),
        const SizedBox(height: 16),

        // List of items
        Expanded(
          child: _buildFavoritesList(context, viewModel),
        ),
      ],
    );
  }

  Widget _buildFilterPills(AudioLibraryViewModel viewModel) {
    final filters = ['كتب', 'بودكاست', 'ريلز'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(filters.length, (index) {
        final isSelected = viewModel.activeFavFilterIndex == index;
        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: GestureDetector(
            onTap: () => viewModel.setActiveFavFilter(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : const Color(0xFF2C2C2B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFavoritesList(BuildContext context, AudioLibraryViewModel viewModel) {
    if (viewModel.activeFavFilterIndex == 0) {
      // Books
      if (viewModel.favoriteBooks.isEmpty) {
        return _buildEmptyState('لا توجد كتب مفضلة حالياً');
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: viewModel.favoriteBooks.length,
        itemBuilder: (context, index) {
          final book = viewModel.favoriteBooks[index];
          return _buildBookCard(context, book, viewModel);
        },
      );
    } else if (viewModel.activeFavFilterIndex == 1) {
      // Podcasts
      if (viewModel.favoritePodcasts.isEmpty) {
        return _buildEmptyState('لا توجد بودكاستات مفضلة حالياً');
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: viewModel.favoritePodcasts.length,
        itemBuilder: (context, index) {
          final podcast = viewModel.favoritePodcasts[index];
          return _buildPodcastCard(context, podcast, viewModel);
        },
      );
    } else {
      // Reels
      if (viewModel.favoriteReels.isEmpty) {
        return _buildEmptyState('لا توجد مقاطع ريلز مفضلة حالياً');
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: viewModel.favoriteReels.length,
        itemBuilder: (context, index) {
          final reel = viewModel.favoriteReels[index];
          return _buildReelCard(context, reel, viewModel);
        },
      );
    }
  }

  Widget _buildBookCard(BuildContext context, LibraryBook book, AudioLibraryViewModel viewModel) {
    final hasProgress = book.progress > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column (Heart icon, progress info, continue reading button)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => viewModel.toggleFavoriteBook(book.id),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                    ),
                    if (hasProgress)
                      Text(
                        '${(book.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Linear progress bar (if progress > 0)
                if (hasProgress) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: book.progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action button or Play icon
                if (hasProgress)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/book_reader',
                          arguments: BookReaderScreenArgs(
                            pdfAssetPath: book.pdfAssetPath,
                            bookTitle: book.title,
                            audioUrl: '',
                            chapterId: 'ch1',
                            transcript: 'الفصل الأول من رواية ${book.title}...',
                            bookCoverUrl: book.coverUrl,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppTheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                      label: const Text(
                        'استكمال القراءة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  // Simple play circle button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/audio_player');
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right Column (Title, Author, Cover image)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  book.coverUrl,
                  width: 76,
                  height: 104,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 76,
                      height: 104,
                      color: const Color(0xFF353534),
                      child: const Icon(Icons.book, color: Colors.white30, size: 30),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastCard(BuildContext context, LibraryPodcast podcast, AudioLibraryViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Favorite toggle & play button
          Row(
            children: [
              GestureDetector(
                onTap: () => viewModel.toggleFavoritePodcast(podcast.id),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/audio_player');
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

          // Right: Cover and podcast info
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    podcast.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    podcast.author,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  podcast.coverUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFF353534),
                      child: const Icon(Icons.mic, color: Colors.white30, size: 24),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReelCard(BuildContext context, Reel reel, AudioLibraryViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Favorite toggle & play button
          Row(
            children: [
              GestureDetector(
                onTap: () => viewModel.toggleFavoriteReel(reel.id),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  // Route to Reels Feed or Reel Preview
                  Navigator.pushNamed(context, '/home'); // Back to main home tabs
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

          // Right: Cover and quote info
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reel.bookTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 160,
                    child: Text(
                      reel.quote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  reel.imageUrl,
                  width: 50,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 80,
                      color: const Color(0xFF353534),
                      child: const Icon(Icons.video_library_rounded, color: Colors.white30, size: 24),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── DOWNLOADS TAB ──────────────────────────────────────────────────
  Widget _buildDownloadsTab(BuildContext context, AudioLibraryViewModel viewModel) {
    if (viewModel.downloadedBooks.isEmpty) {
      return _buildEmptyState('لا توجد تنزيلات متوفرة');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: viewModel.downloadedBooks.length,
      itemBuilder: (context, index) {
        final book = viewModel.downloadedBooks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Delete download & Play button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => viewModel.deleteDownload(book.id),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/audio_player');
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              // Right: Cover and info
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      book.coverUrl,
                      width: 50,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 68,
                          color: const Color(0xFF353534),
                          child: const Icon(Icons.book, color: Colors.white30, size: 20),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── BOOKMARKS / HIGHLIGHTS TAB ────────────────────────────────────
  Widget _buildHighlightsTab(BuildContext context, AudioLibraryViewModel viewModel) {
    if (viewModel.highlights.isEmpty) {
      return _buildEmptyState('لا توجد نصوص أو إشارات محفوظة');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: viewModel.highlights.length,
      itemBuilder: (context, index) {
        final hl = viewModel.highlights[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Book Title + Delete Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        hl.bookTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => viewModel.deleteHighlight(hl.id),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle: Quote text
              Text(
                '« ${hl.quote} »',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 14),

              // Bottom: Date & Share Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hl.date,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Share.share('إليك مقولة أعجبتني في كتاب "${hl.bookTitle}":\n\n"${hl.quote}"');
                    },
                    child: Row(
                      children: [
                        Text(
                          'مشاركة',
                          style: TextStyle(
                            color: AppTheme.primary.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.share_outlined,
                          color: AppTheme.primary.withOpacity(0.8),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper empty state widget
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_rounded,
            size: 48,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
