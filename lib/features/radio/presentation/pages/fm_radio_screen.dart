import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/fm_station.dart';
import '../provider/fm_radio_provider.dart';

import 'package:kutub_fm/features/podcast/presentation/providers/podcast_provider.dart';
import 'package:kutub_fm/core/navigation/app_navigation_state.dart';
import 'package:kutub_fm/core/routes/app_routes.dart';

/// Unified 'صوتي' (Audio) screen containing tabs for Radio and Podcast.
class FMRadioScreen extends StatelessWidget {
  const FMRadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FMRadioScreenContent();
  }
}

class _FMRadioScreenContent extends StatefulWidget {
  const _FMRadioScreenContent();

  @override
  State<_FMRadioScreenContent> createState() => _FMRadioScreenContentState();
}

class _FMRadioScreenContentState extends State<_FMRadioScreenContent>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'الكل';
  final List<String> _categories = [
    'الكل',
    'تعليم',
    'سفر',
    'فنون',
    'رياضة',
    'أخبار',
  ];

  void _openStation(FmStation station) {
    context.read<FmRadioProvider>().playStation(station);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmProvider = context.watch<FmRadioProvider>();
    final podcastProvider = context.watch<PodcastProvider>();

    // Dynamic filtering for radio stations based on selected category tag
    List<FmStation> filteredStations = fmProvider.stations;
    if (_selectedCategory != 'الكل') {
      filteredStations = fmProvider.stations.where((station) {
        final tagline = station.tagline.toLowerCase();
        final name = station.name.toLowerCase();
        if (_selectedCategory == 'أخبار') {
          return tagline.contains('أخبار') ||
              tagline.contains('خبر') ||
              name.contains('أخبار');
        } else if (_selectedCategory == 'تعليم') {
          return tagline.contains('قرآن') ||
              tagline.contains('ثقافة') ||
              tagline.contains('تعليم') ||
              tagline.contains('ديني');
        } else if (_selectedCategory == 'فنون') {
          return tagline.contains('موسيقى') ||
              tagline.contains('ترفيه') ||
              tagline.contains('شعبية') ||
              tagline.contains('طرب');
        } else if (_selectedCategory == 'رياضة') {
          return tagline.contains('رياضة') || tagline.contains('شباب');
        } else if (_selectedCategory == 'سفر') {
          return tagline.contains('سفر') ||
              tagline.contains('سياحة') ||
              tagline.contains('القاهرة') ||
              tagline.contains('نيل');
        }
        return false;
      }).toList();
    }

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF090806),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: const Text(
              'صوتي',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.read<AppNavigationState>().setSelectedIndex(0);
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Custom TabBar inside a styled container matching Figma
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFFF2CA50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: const Color(0xFF111217),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radio_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('راديو'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('بودكاست'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Radio View
                    _buildRadioTab(fmProvider, filteredStations, theme),

                    // Tab 2: Podcast View
                    _buildPodcastTab(podcastProvider, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioTab(
    FmRadioProvider fmProvider,
    List<FmStation> filteredStations,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Category Filters Carousel
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF2CA50)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF111217)
                            : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Radio Stations Vertical List
        Expanded(
          child: fmProvider.isDataLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF2CA50),
                  ),
                )
              : filteredStations.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد محطات في هذه الفئة.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: filteredStations.length,
                      itemBuilder: (context, index) {
                        final station = filteredStations[index];
                        final isCurrent =
                            fmProvider.currentStation?.id == station.id;
                        final isPlaying = fmProvider.isPlaying && isCurrent;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFFF2CA50).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Circular Play Button (Left)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _openStation(station);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCurrent
                                          ? const Color(0xFFF2CA50)
                                          : Colors.white30,
                                      width: 1.5,
                                    ),
                                    color: isPlaying
                                        ? const Color(0xFFF2CA50).withOpacity(0.1)
                                        : Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: isCurrent
                                          ? const Color(0xFFF2CA50)
                                          : Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Station Name & Tagline (Center)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      station.name,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? const Color(0xFFF2CA50)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      station.tagline,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Artwork Image (Right)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  station.coverImageUrl,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(
                                    width: 52,
                                    height: 52,
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.radio_rounded,
                                      color: Colors.white30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPodcastTab(PodcastProvider provider, ThemeData theme) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF2CA50),
        ),
      );
    }

    if (provider.error != null && provider.episodes.isEmpty) {
      return Center(
        child: Text(
          provider.error!,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Most Listened Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الحلقات الأكثر سماعًا',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),

        // 2. Episodes List
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final episode = provider.episodes[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Bookmark Icon (Left)
                      IconButton(
                        icon: const Icon(
                          Icons.bookmark_border_rounded,
                          color: Colors.white30,
                          size: 22,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمت الإضافة للمفضلة'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Text Info (Center)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Metadata
                            Text(
                              'قبل أسبوع • ${episode.category}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Title
                            Text(
                              episode.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            // Play Pill Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.podcastDetail,
                                  arguments: episode.id,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      episode.duration,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Cover Image (Right)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.podcastDetail,
                            arguments: episode.id,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            episode.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.white10,
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: Colors.white30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: provider.episodes.length,
            ),
          ),
        ),

        /*
        // 3. Popular Programs Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'البرامج المشهورة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),

        // 4. Horizontal Popular Programs List
        SliverToBoxAdapter(
          child: Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 120),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildProgramCard(
                  title: 'صناعة الأغذية حول العالم',
                  episodesCount: '١٣ حلقة',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C221C), Color(0xFF17130E)],
                  ),
                ),
                _buildProgramCard(
                  title: 'ضاعف وقتك مع عقل أفضل',
                  episodesCount: '٤ حلقات',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B262C), Color(0xFF0F171E)],
                  ),
                ),
                _buildProgramCard(
                  title: 'أسرار ريادة الأعمال',
                  episodesCount: '١٠ حلقات',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A2F25), Color(0xFF0C1D15)],
                  ),
                ),
              ],
            ),
          ),
        ),
        */
      ],
    );
  }

  /*
  Widget _buildProgramCard({
    required String title,
    required String episodesCount,
    required Gradient gradient,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Stack(
        children: [
          // Background CD ornament decoration
          Positioned(
            left: -30,
            top: -30,
            child: Opacity(
              opacity: 0.12,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  episodesCount,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  */
}
