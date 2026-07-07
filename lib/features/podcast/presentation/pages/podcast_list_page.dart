import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/podcast_provider.dart';
import '../../../../core/routes/app_routes.dart';

class PodcastListPage extends StatefulWidget {
  const PodcastListPage({super.key});

  @override
  State<PodcastListPage> createState() => _PodcastListPageState();
}

class _PodcastListPageState extends State<PodcastListPage> {
  String _selectedFilter = 'الموسم الثاني';

  @override
  Widget build(BuildContext context) {
    final String programTitle =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 'قبل طي الصفحة';

    // Map content details dynamically based on program title
    final String coverImage;
    final String authorName;
    final String description;

    if (programTitle == 'وراء الملصق الغذائي') {
      coverImage = 'assets/generated/fresh_tomatoes.png';
      authorName = 'منى رجب';
      description =
          'نغوص في تفاصيل ما نأكله يومياً، ونكشف الأسرار المخبأة خلف الملصقات الغذائية وتأثيرها المباشر على صحتنا وحياتنا اليومية.';
    } else {
      coverImage = 'assets/generated/glowing_open_book.png';
      authorName = 'عامر واجد';
      description =
          'رحلة فلسفية وثقافية نتصفح فيها الحياة والكتب، ونتأمل الأفكار العميقة التي شكلت الوعي البشري عبر العصور المختلفة.';
    }

    final podcastProvider = context.watch<PodcastProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090806),
        body: CustomScrollView(
          slivers: [
            // SliverAppBar with custom banner image & gradient overlay
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(0xFF090806),
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      onPressed: () {},
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 18),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Banner Cover Image
                    Image.asset(
                      coverImage,
                      fit: BoxFit.cover,
                    ),
                    // Dark radial & linear gradient overlay for contrast
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF090806),
                            const Color(0xFF090806).withOpacity(0.8),
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // Titles inside flexible space
                    Positioned(
                      bottom: 16,
                      right: 16,
                      left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC00E).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFFC00E).withOpacity(0.5)),
                            ),
                            child: const Text(
                              'بودكاست كُتب FM',
                              style: TextStyle(
                                color: Color(0xFFFFC00E),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ThmanyahSans',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            programTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ThmanyahSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تقديم: $authorName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'ThmanyahSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Description & Filters section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Filters row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterDropdownButton(),
                          const SizedBox(width: 8),
                          _buildFilterPill('الموسم الثاني'),
                          const SizedBox(width: 8),
                          _buildFilterPill('الموسم الأول'),
                          const SizedBox(width: 8),
                          _buildFilterPill('الأكثر شعبية'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Episodes list
            podcastProvider.isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC00E))),
                  )
                : podcastProvider.episodes.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'لا توجد حلقات متاحة حالياً.',
                            style: TextStyle(color: Colors.white54, fontFamily: 'ThmanyahSans'),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final episode = podcastProvider.episodes[index];
                              return _buildEpisodeCard(episode);
                            },
                            childCount: podcastProvider.episodes.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdownButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'ترتيب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'ThmanyahSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String filterText) {
    final isSelected = _selectedFilter == filterText;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterText;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC00E) : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC00E) : const Color(0xFF333333),
          ),
        ),
        child: Text(
          filterText,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'ThmanyahSans',
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeCard(dynamic episode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Episode Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  episode.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFF2E2E2E),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white38),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Episode text information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الموسم الثاني • الحلقة ${episode.id.substring(episode.id.length - 1)}',
                      style: const TextStyle(
                        color: Color(0xFFFFC00E),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'منذ أسبوع • ${episode.duration}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Episode brief summary description
          Text(
            episode.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
              fontFamily: 'ThmanyahSans',
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Play/Listen button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.podcastDetail,
                    arguments: episode.id,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC00E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'استمع الآن',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ThmanyahSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Favorite & Share action icons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white70, size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border_rounded, color: Colors.white70, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
