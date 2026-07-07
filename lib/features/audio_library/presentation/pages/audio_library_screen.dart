import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/audio_library_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';

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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF040707),
        body: SafeArea(
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F1F1F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const Text(
                      'مكتبتي',
                      style: TextStyle(
                        color: Color(0xFFF4F4F4),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'thmanyah_sans',
                      ),
                    ),
                    const SizedBox(width: 44), // Placeholder to balance
                  ],
                ),
              ),

              // Tab Selector (المفضلة, التنزيلات, الإشارات)
              _buildTabSelector(viewModel),
              const SizedBox(height: 16),

              // Active Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildActiveTabContent(viewModel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(AudioLibraryViewModel viewModel) {
    // Tabs ordered according to Figma (right to left):
    // 0 = المفضلة, 1 = التنزيلات, 2 = الإشارات
    final tabs = [
      {
        'title': 'المفضلة',
        'icon': Icons.favorite,
        'inactiveIcon': Icons.favorite_border_rounded
      },
      {
        'title': 'التنزيلات',
        'icon': Icons.file_download_outlined, // Wait, figma download icon is download-01 (two components). We use standard download icon.
        'inactiveIcon': Icons.file_download_outlined
      },
      {
        'title': 'الإشارات',
        'icon': Icons.bookmark_border_rounded,
        'inactiveIcon': Icons.bookmark_border_rounded
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      color: isSelected
                          ? const Color(0xFFFFBD10)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab['title'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF4F4F4)
                            : const Color(0xFFBDBDBD),
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'thmanyah_sans',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      (isSelected ? tab['icon'] : tab['inactiveIcon']) as IconData,
                      size: 24,
                      color: isSelected
                          ? const Color(0xFFF4F4F4)
                          : const Color(0xFFBDBDBD),
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

  Widget _buildActiveTabContent(AudioLibraryViewModel viewModel) {
    switch (viewModel.activeTabIndex) {
      case 0:
        return _buildFavoritesTab(viewModel);
      case 1:
        return _buildDownloadsTab(viewModel);
      case 2:
        return _buildHighlightsTab(viewModel);
      default:
        return const SizedBox.shrink();
    }
  }

  // ==================== FAVORITES TAB ====================
  Widget _buildFavoritesTab(AudioLibraryViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-filter pills (كتب, بودكاست, ريلز)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildFilterPill(viewModel, 2, 'ريلز'),
            const SizedBox(width: 4),
            _buildFilterPill(viewModel, 1, 'بودكاست'),
            const SizedBox(width: 4),
            _buildFilterPill(viewModel, 0, 'كتب'),
          ],
        ),
        const SizedBox(height: 16),

        // List Content
        Expanded(child: _buildFavoritesList(viewModel)),
      ],
    );
  }

  Widget _buildFilterPill(
    AudioLibraryViewModel viewModel,
    int index,
    String label,
  ) {
    final isSelected = viewModel.activeFavFilterIndex == index;
    return GestureDetector(
      onTap: () => viewModel.setActiveFavFilter(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFBD10) : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1F1F1F) : const Color(0xFFF4F4F4),
            fontSize: 14,
            fontWeight: FontWeight.normal,
            fontFamily: 'thmanyah_sans',
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(AudioLibraryViewModel viewModel) {
    if (viewModel.activeFavFilterIndex == 0) {
      // Books List
      final books = viewModel.favoriteBooks;
      if (books.isEmpty) {
        return const Center(
          child: Text(
            'لا توجد كتب مفضلة حالياً',
            style: TextStyle(color: Colors.white54, fontFamily: 'thmanyah_sans'),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildFigmaBookCard(book, () {
            viewModel.toggleFavoriteBook(book.id);
          });
        },
      );
    } else if (viewModel.activeFavFilterIndex == 1) {
      // Podcasts List (Shows & Episodes)
      return _buildFigmaPodcastsView(viewModel);
    } else {
      // Reels Grid
      final reels = viewModel.favoriteReels;
      if (reels.isEmpty) {
        return const Center(
          child: Text(
            'لا توجد مقاطع ريلز مفضلة حالياً',
            style: TextStyle(color: Colors.white54, fontFamily: 'thmanyah_sans'),
          ),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 116 / 170,
        ),
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return _buildFigmaReelCard(reel, () {
            viewModel.toggleFavoriteReel(reel.id);
          });
        },
      );
    }
  }

  Widget _buildFigmaBookCard(LibraryBook book, VoidCallback onFavoriteTap) {
    final progress = book.progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left section: Title, author, progress, actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onFavoriteTap,
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFF46D6E),
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF4F4F4),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'thmanyah_sans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFBDBDBD),
                              fontSize: 14,
                              fontFamily: 'thmanyah_sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 14,
                        fontFamily: 'thmanyah_sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 3,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF393939),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerRight,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5C5C5),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // "إكمال القراءة" Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookReaderScreen(),
                        ),
                      );
                    },
                    icon: SvgPicture.asset(
                      'assets/nav_books.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1F1F1F),
                        BlendMode.srcIn,
                      ),
                      width: 16,
                      height: 16,
                    ),
                    label: const Text(
                      'إكمال القراءة',
                      style: TextStyle(
                        color: Color(0xFF1F1F1F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'thmanyah_sans',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFBD10),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right section: Cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              book.coverUrl,
              width: 113,
              height: 129,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaPodcastsView(AudioLibraryViewModel viewModel) {
    final shows = viewModel.favoritePodcastShows;
    final episodes = viewModel.favoritePodcastEpisodes;

    return CustomScrollView(
      slivers: [
        // 1. Favorite Shows section (البرامج المفضلة)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'البرامج المفضلة',
                  style: TextStyle(
                    color: Color(0xFFF4F4F4),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (shows.isEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'لا توجد برامج مفضلة حالياً',
                  style: TextStyle(color: Colors.white54, fontFamily: 'thmanyah_sans'),
                ),
              ),
            ),
          )
        else
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 175 / 157,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final show = shows[index];
                return _buildFigmaPodcastShowCard(show, () {
                  viewModel.toggleFavoritePodcastShow(show.id);
                });
              },
              childCount: shows.length,
            ),
          ),

        // 2. Favorite Episodes section (الحلقات المفضلة)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 24.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'الحلقات المفضلة',
                  style: TextStyle(
                    color: Color(0xFFF4F4F4),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (episodes.isEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'لا توجد حلقات مفضلة حالياً',
                  style: TextStyle(color: Colors.white54, fontFamily: 'thmanyah_sans'),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final episode = episodes[index];
                return _buildFigmaPodcastEpisodeCard(episode, () {
                  viewModel.toggleFavoritePodcastEpisode(episode.id);
                });
              },
              childCount: episodes.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildFigmaPodcastShowCard(LibraryPodcastShow show, VoidCallback onFavoriteTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(show.coverUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1F1F1F).withValues(alpha: 0.4),
                  const Color(0xFF1F1F1F).withValues(alpha: 0.0),
                  const Color(0xFF1F1F1F).withValues(alpha: 0.9),
                ],
                stops: const [0.15, 0.5, 1.0],
              ),
            ),
          ),

          // Favorite Heart Icon with glassmorphic circle background (top-left in RTL / top-right in LTR)
          Positioned(
            left: 8,
            top: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 27,
                height: 27,
                color: Colors.white.withValues(alpha: 0.2),
                child: Center(
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFF46D6E),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Show Titles at bottom (RTL alignment)
          Positioned(
            right: 16,
            bottom: 12,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  show.author,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F4),
                    fontSize: 14,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
                Text(
                  show.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
                Text(
                  '${show.episodesCount} حلقات',
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 14,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaPodcastEpisodeCard(LibraryPodcastEpisode episode, VoidCallback onFavoriteTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Favorite toggle icon
          GestureDetector(
            onTap: onFavoriteTap,
            child: const Icon(
              Icons.favorite,
              color: Color(0xFFF46D6E),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),

          // Center: Title, Meta, duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.metaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  episode.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
                const SizedBox(height: 6),

                // Play / duration button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBD10),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        episode.duration,
                        style: const TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'thmanyah_sans',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 14,
                        color: Color(0xFF1F1F1F),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),

          // Right: Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              episode.coverUrl,
              width: 77,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaReelCard(LibraryReel reel, VoidCallback onFavoriteTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        image: DecorationImage(
          image: AssetImage(reel.coverUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF040707).withValues(alpha: 0.6),
                  const Color(0xFF040707).withValues(alpha: 0.0),
                  const Color(0xFF040707).withValues(alpha: 0.8),
                ],
                stops: const [0.1, 0.5, 1.0],
              ),
            ),
          ),

          // Favorite Heart Icon with glassmorphic circle background (top-left)
          Positioned(
            left: 7,
            top: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 27,
                height: 27,
                color: Colors.white.withValues(alpha: 0.2),
                child: Center(
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFF46D6E),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Book Title (top-right RTL)
          Positioned(
            right: 8,
            top: 8,
            left: 38,
            child: Text(
              reel.bookTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 10,
                fontFamily: 'thmanyah_sans',
              ),
            ),
          ),

          // Quote Text (bottom center)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              reel.quote,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.normal,
                fontFamily: 'thmanyah_sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DOWNLOADS TAB ====================
  Widget _buildDownloadsTab(AudioLibraryViewModel viewModel) {
    final downloads = viewModel.downloadedBooks;

    return Column(
      children: [
        // Summary bar `chapter`
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF333333)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '6 كتب محملة',
                      style: TextStyle(
                        color: Color(0xFFF4F4F4),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'thmanyah_sans',
                      ),
                    ),
                    Text(
                      '340 ميجا مستخدمة',
                      style: TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 12,
                        fontFamily: 'thmanyah_sans',
                      ),
                    ),
                  ],
                ),
              ),
              // Download Icon
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.file_download_outlined,
                  size: 24,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
        ),

        // Downloads List
        Expanded(
          child: downloads.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد تنزيلات حالياً',
                    style: TextStyle(color: Colors.white54, fontFamily: 'thmanyah_sans'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    final book = downloads[index];
                    return _buildFigmaDownloadedBookCard(book, () {
                      viewModel.deleteDownload(book.id);
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFigmaDownloadedBookCard(LibraryBook book, VoidCallback onDeleteTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Menu book / Delete icon
          GestureDetector(
            onTap: onDeleteTap,
            child: SvgPicture.asset(
              'assets/nav_books.svg',
              colorFilter: const ColorFilter.mode(
                Color(0xFFFFBD10),
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 10),

          // Center: Title, Author
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'thmanyah_sans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right: Small cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(
              book.coverUrl,
              width: 31,
              height: 42,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HIGHLIGHTS TAB ====================
  Widget _buildHighlightsTab(AudioLibraryViewModel viewModel) {
    final highlights = viewModel.highlights;

    if (highlights.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد إشارات أو اقتباسات حالياً',
          style: TextStyle(color: Colors.white54, fontFamily: 'thmanyah_sans'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: highlights.length,
      itemBuilder: (context, index) {
        final highlight = highlights[index];
        return _buildFigmaHighlightCard(highlight, () {
          viewModel.deleteHighlight(highlight.id);
        });
      },
    );
  }

  Widget _buildFigmaHighlightCard(LibraryHighlight hl, VoidCallback onDeleteTap) {
    final themeColor = Color(hl.colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Bookmark icon, Title/Author, Cover image
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Delete / bookmark icon
              GestureDetector(
                onTap: onDeleteTap,
                child: SvgPicture.asset(
                  'assets/bookmark.svg',
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFFBD10),
                    BlendMode.srcIn,
                  ),
                  width: 18,
                  height: 18,
                ),
              ),

              // Center-Right: Book Details & cover thumbnail
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hl.bookTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF4F4F4),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'thmanyah_sans',
                            ),
                          ),
                          Text(
                            hl.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFBDBDBD),
                              fontSize: 12,
                              fontFamily: 'thmanyah_sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.asset(
                        hl.coverUrl,
                        width: 31,
                        height: 42,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Colored quote box with right border (border-right-4)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
                topRight: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              border: Border(
                right: BorderSide(
                  color: themeColor,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hl.quote,
                    style: const TextStyle(
                      color: Color(0xFFF4F4F4),
                      fontSize: 12,
                      height: 1.5,
                      fontFamily: 'thmanyah_sans',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bottom Row: share icon & date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Share button
              GestureDetector(
                onTap: () {
                  // Mock Share
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ الاقتباس للمشاركة!'),
                    ),
                  );
                },
                child: SvgPicture.asset(
                  'assets/share.svg',
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFBDBDBD),
                    BlendMode.srcIn,
                  ),
                  width: 20,
                  height: 20,
                ),
              ),

              // Date text
              Text(
                hl.date,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                  fontFamily: 'thmanyah_sans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
