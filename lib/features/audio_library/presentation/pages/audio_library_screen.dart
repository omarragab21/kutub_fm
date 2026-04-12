import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/audio_library_viewmodel.dart';
import '../widgets/category_card.dart';
import '../widgets/featured_audio_card.dart';
import '../widgets/audio_list_item.dart';

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

class _AudioLibraryContent extends StatelessWidget {
  const _AudioLibraryContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AudioLibraryViewModel>();

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 15),
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=11',
                      ),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          'مكتبة صوتية',
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
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.search, color: AppTheme.primary),
                      onPressed: () {},
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

            // Featured Audio Banner
            if (viewModel.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (viewModel.featuredBook != null) ...[
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
