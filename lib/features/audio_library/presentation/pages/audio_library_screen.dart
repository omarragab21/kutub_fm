import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/audio_library_viewmodel.dart';
import '../widgets/category_card.dart';
import '../widgets/featured_audio_card.dart';
import '../widgets/audio_list_item.dart';
import 'package:kutub_fm/features/auth/presentation/providers/auth_provider.dart';

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AudioLibraryViewModel>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.appUser;

    String initials(String name) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
      return parts[0].isNotEmpty ? parts[0][0] : '?';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep Dark Background
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              sliver: SliverToBoxAdapter(
                child: viewModel.isSearchActive
                    ? Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                            onPressed: () {
                              _searchController.clear();
                              viewModel.toggleSearch(false);
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              onChanged: viewModel.updateSearchQuery,
                              decoration: InputDecoration(
                                hintText: 'ابحث عن كتاب، كاتب، تصنيف...',
                                hintTextDirection: TextDirection.rtl,
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.white60,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          viewModel.updateSearchQuery('');
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 15),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.surfaceContainerHighest,
                            backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                                ? Text(
                                    initials(user?.name ?? ''),
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const Spacer(),
                          Text(
                            'كتب FM',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.search, color: AppTheme.primary),
                            onPressed: () {
                              viewModel.toggleSearch(true);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
              ),
            ),

            // Horizontal Category Carousel
            if (!viewModel.isSearchActive)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120, // Enough height for card + drop shadow
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: viewModel.categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final category = viewModel.categories[index];
                      return CategoryCard(
                        category: category,
                        isSelected: viewModel.selectedCategoryId == category.id,
                        onTap: () => viewModel.selectCategory(category.id),
                      );
                    },
                  ),
                ),
              ),

            // Featured Audio Banner & Playlist list
            if (viewModel.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (viewModel.isSearchActive) ...[
              // Search Results Header
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    viewModel.searchQuery.isEmpty ? 'كل الكتب' : 'نتائج البحث',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (viewModel.filteredBooks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'لا توجد نتائج بحث تطابق استعلامك',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AudioListItem(
                          book: viewModel.filteredBooks[index],
                          onTap: () {
                            Navigator.pushNamed(context, '/audio_player');
                          },
                        );
                      },
                      childCount: viewModel.filteredBooks.length,
                    ),
                  ),
                ),
            ] else if (viewModel.featuredBook != null) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: FeaturedAudioCard(
                    book: viewModel.featuredBook!,
                    onTap: () {
                      Navigator.pushNamed(context, '/audio_player');
                    },
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Text(
                        'قائمة تشغيلك', // Your Playlist
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'عرض الكل',
                        style: TextStyle(
                          color: AppTheme.primary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Audio List Bottom
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  120,
                ), // padded bottom for miniplayer
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return AudioListItem(
                      book: viewModel.books[index],
                      onTap: () {
                        Navigator.pushNamed(context, '/audio_player');
                      },
                    );
                  }, childCount: viewModel.books.length),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
