import "package:flutter/material.dart";
import "package:kutub_fm/features/book_details/presentation/pages/book_details_page.dart";
import "package:kutub_fm/features/reels/presentation/pages/reels_feed_page.dart";
import 'package:kutub_fm/core/navigation/app_navigation_state.dart';
import 'package:provider/provider.dart';
import "../../../../core/audio/audio_provider.dart";
import "../../../../core/routes/app_routes.dart";
import "../viewmodels/home_view_model.dart";
import "../../domain/entities/category_entity.dart";
import "../../domain/entities/book_entity.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<HomeViewModel>();
    final hasMiniPlayer = context.watch<AudioProvider>().shouldShowMiniPlayer;

    return _buildBody(viewModel, theme, context, hasMiniPlayer);
  }

  Widget _buildBody(
    HomeViewModel viewModel,
    ThemeData theme,
    BuildContext context,
    bool hasMiniPlayer,
  ) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Text(
          viewModel.error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Custom App Bar
        _buildSliverAppBar(theme),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, hasMiniPlayer ? 220 : 160),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Categories Section
              _buildSectionHeader(theme, 'تصنيفاتنا', 'استعراض'),
              const SizedBox(height: 16),
              _buildCategoryList(viewModel.categories, theme),
              const SizedBox(height: 40),

              // Quick Access Bento Grid
              _buildSectionHeader(theme, 'المحطات السريعة', ''),
              const SizedBox(height: 16),
              _buildBentoGrid(theme, context),
              const SizedBox(height: 40),

              // Recommendations Section
              _buildSectionHeader(theme, 'ترشيحاتنا لك', 'استكشاف'),
              const SizedBox(height: 24),
              _buildBookList(viewModel.recommendedBooks, theme, context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.6),
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCbcWwRMbRSWdy7n25hPeBHNvsY8I3tIgf1keWBcCrm6BWy_cSPyFSvcpKqehCFDNwcGwYle_WCEHvzRM8s69DzXavNKzetg6g3mQUDqow0CJAx7V-fWNziFXbKPtehAFPuJd8SY8SxWr7JTGK92v3EDJ5SCXm9QJEe0Vqx2HwmZPAO1h07Y1RdXFHfXsKuiUd9qYVxNmEdcY26bcSbyqpL47c-b3X0nH2m9xQFSjP06K9X7jUQhFjw5ijtLiSSFWKzRKeV0nHI9_0',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFF2CA50), Color(0xFFD4AF37)],
            ).createShader(bounds),
            child: Text(
              'كتب FM',
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 24,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
        ),
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: () {},
            child: Text(
              actionText,
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryList(List<HomeCategory> categories, ThemeData theme) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        clipBehavior: Clip.none,
        separatorBuilder: (context, index) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReelsFeedPage()),
              );
            },
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2C2C2B),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getIconData(cat.icon),
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.title,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'history_edu':
        return Icons.history_edu;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'trending_up':
        return Icons.trending_up;
      case 'mosque':
        return Icons.mosque;
      case 'science':
        return Icons.science;
      default:
        return Icons.category;
    }
  }

  Widget _buildBentoGrid(ThemeData theme, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Radio Square
            Expanded(
              flex: 1,
              child: AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.fmRadio);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Color(0xFF2C2C2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          child: Icon(
                            Icons.radio,
                            color: theme.colorScheme.primary,
                            size: 30,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'راديو العرب',
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'محطات حية',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Stacked Row Boxes
            Expanded(
              flex: 1,
              child: AspectRatio(
                aspectRatio: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.podcastList),
                        child: _buildSmallBentoItem(
                          theme,
                          'بودكاست',
                          Icons.mic_external_on,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Majlis Wide Card
        GestureDetector(
          onTap: () =>
              context.read<AppNavigationState>().setSelectedIndex(1),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مجلس القرّاء',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 20,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    Text(
                      'انضم إلى النقاش المباشر الآن',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 104,
                  height: 40,
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        start: 0,
                        child: _buildAvatar(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuD6V_qaGZ--aIXlFB_0cHSn0bBWSN_o3wCHFqAgODAI6rwLpxUKhv4HLQt8A1QGBULdZHQRDCkM1-DVo26mhP1yKZ3GknzsMotl6CJP8aAZvDUxY88koeV6h5bQ_JaNiXXPpsAtKbGfA0K_xjCl2Sa2n366ZY3I8NObzyhpeZLkD8OtDdewgOuoyuLVmpuCct4rLLIARqR-DXv-Oqule4dP95y-nHQPgJpVBVb2i4xzx6RYEyBXI4IeLHEZUHgg17WNiEfJZTMwx18',
                        ),
                      ),
                      PositionedDirectional(
                        start: 32,
                        child: _buildAvatar(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBwPLREPGogwsJ6jcO2MI5cdJ5eoRih3TMgDSlQFmBp9z4XSJCVUoJ0aFNhZ0oIwhI299LZNZzQzrLCflma9C8b2A93qBZtmHEN1WP576PFZdjAilavBcW2tTjR6a5nZeGP2GJaiBRY6qTJXKJiajCpVl8Ga26VZJ7zP1uVO0DPA3JkO4rMWIcrIw7LQAEYDt5H03pkAxk_Z4k6-6591gLxNMqQChZSAZjnemoSoeZyUNRcvdaAU8PbvLueWk_gDKxFcmqqidOgOyQ',
                        ),
                      ),
                      PositionedDirectional(
                        start: 64,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.2,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.primaryContainer,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '+١٤',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBentoItem(ThemeData theme, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 18),
          ),
          Icon(icon, color: theme.colorScheme.primaryContainer),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBookList(
    List<BookEntity> books,
    ThemeData theme,
    BuildContext context,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (context, index) => const SizedBox(height: 32),
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookDetailsPage()),
            );
          },
          child: Row(
            children: [
              Hero(
                tag: 'book_${book.id}',
                child: Container(
                  width: 96,
                  height: 128,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(book.coverUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: theme.colorScheme.tertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book.rating.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.tertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          book.duration,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
