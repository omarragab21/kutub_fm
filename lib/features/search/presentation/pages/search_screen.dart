import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../viewmodels/search_view_model.dart';
import '../../../home/domain/entities/book_entity.dart';
import '../../../radio/domain/fm_station.dart';
import '../../../podcast/domain/entities/podcast_episode.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedTab = 0; // 0: الكل, 1: كتب, 2: راديو, 3: بودكاست

  final List<String> _tabs = ['الكل', 'الكتب', 'الراديو', 'البودكاست'];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String val, SearchViewModel viewModel) {
    viewModel.performSearch(val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<SearchViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Search Bar Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      // Search TextField
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _focusNode.hasFocus
                                  ? AppTheme.primary.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: (val) => _onSearch(val, viewModel),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (val) => _onSearch(val, viewModel),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن كتب، راديو، أو بودكاست...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: _focusNode.hasFocus
                                    ? AppTheme.primary
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        viewModel.clearSearch();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Horizontal Scrollable Tabs
                const SizedBox(height: 4),
                _buildTabsBar(theme),
              ],
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: _buildBody(viewModel, theme),
      ),
    );
  }

  Widget _buildTabsBar(ThemeData theme) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _tabs.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTab = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.white60,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(SearchViewModel viewModel, ThemeData theme) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
        ),
      );
    }

    switch (viewModel.state) {
      case SearchState.initial:
        return _buildInitialState(theme);
      case SearchState.empty:
        return _buildEmptyState(theme);
      case SearchState.success:
        return _buildResults(viewModel, theme);
      case SearchState.loading:
      case SearchState.failure:
        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
  }

  Widget _buildInitialState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          Text(
            'ابحث في كتب FM',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'اكتشف الكتب الصوتية المفضلة لديك، محطات الراديو الحية، وحلقات البودكاست الثقافية الممتعة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج بحث',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'لم نجد أي نتائج تطابق "${_searchController.text}". يرجى التأكد من كتابة الكلمات بشكل صحيح أو تجربة كلمات بحث أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchViewModel viewModel, ThemeData theme) {
    final showAll = _selectedTab == 0;
    final showBooks = _selectedTab == 1;
    final showRadio = _selectedTab == 2;
    final showPodcasts = _selectedTab == 3;

    final books = viewModel.filteredBooks;
    final stations = viewModel.filteredStations;
    final episodes = viewModel.filteredPodcasts;

    if (showBooks && books.isEmpty) return _buildEmptyState(theme);
    if (showRadio && stations.isEmpty) return _buildEmptyState(theme);
    if (showPodcasts && episodes.isEmpty) return _buildEmptyState(theme);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Books section
        if ((showAll || showBooks) && books.isNotEmpty) ...[
          _buildCategoryHeader(theme, 'الكتب الصوتية (${books.length})'),
          const SizedBox(height: 16),
          ...books.map((book) => _buildBookItem(book, theme)),
          const SizedBox(height: 24),
        ],

        // 2. Radio Stations section
        if ((showAll || showRadio) && stations.isNotEmpty) ...[
          _buildCategoryHeader(theme, 'محطات الراديو (${stations.length})'),
          const SizedBox(height: 16),
          ...stations.map((station) => _buildRadioItem(station, theme)),
          const SizedBox(height: 24),
        ],

        // 3. Podcast Episodes section
        if ((showAll || showPodcasts) && episodes.isNotEmpty) ...[
          _buildCategoryHeader(theme, 'حلقات البودكاست (${episodes.length})'),
          const SizedBox(height: 16),
          ...episodes.map((episode) => _buildPodcastItem(episode, theme)),
          const SizedBox(height: 80),
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBookItem(BookEntity book, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.bookDetails,
          arguments: book.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            // Cover Image
            Hero(
              tag: 'book_search_${book.id}',
              child: Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(book.coverUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        book.rating.toString(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.4), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        book.duration,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioItem(FmStation station, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.fmStationDetail,
          arguments: station,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            // Cover Image
            Hero(
              tag: FmStation.heroTag(station.id),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(station.coverImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    station.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${station.frequencyLabel} FM',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Play Action indicator icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
              child: const Center(
                child: Icon(Icons.play_arrow_rounded, color: AppTheme.primary, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastItem(PodcastEpisode episode, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.podcastDetail,
          arguments: episode.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            // Cover Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(episode.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          episode.category,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.4), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        episode.duration,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }
}
