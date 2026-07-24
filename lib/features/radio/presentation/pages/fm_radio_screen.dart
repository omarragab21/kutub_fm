import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../core/audio/audio_models.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../data/datasources/firebase_fm_radio_data_source.dart';
import '../../domain/fm_station.dart';
import '../provider/fm_radio_provider.dart';
import '../../../podcast/domain/entities/podcast.dart';
import '../../../podcast/domain/entities/podcast_episode.dart';
import '../../../podcast/presentation/providers/podcast_provider.dart';

/// Unified 'صوتي' (Audio) screen containing tabs for Radio and Podcast.
class FMRadioScreen extends StatelessWidget {
  const FMRadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MyAudioScreenContent();
  }
}

class _MyAudioScreenContent extends StatefulWidget {
  const _MyAudioScreenContent();

  @override
  State<_MyAudioScreenContent> createState() => _MyAudioScreenContentState();
}

class _MyAudioScreenContentState extends State<_MyAudioScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF040707),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  _buildCustomTabBar(),
                  _buildSearchBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRadioTab(),
                        _buildPodcastTab(),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildFloatingLivePlayerBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text "صوتي" on the far right in RTL
          const Text(
            'صوتي',
            style: TextStyle(
              color: Color(0xFFF4F4F4),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          // Back button on the far left in RTL
          Container(
            width: 41,
            height: 41,
            decoration: const BoxDecoration(
              color: Color(0xFF1F1F1F),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabIcon(String asset, bool selected) {
    return SvgPicture.asset(
      asset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        selected ? const Color(0xFFF4F4F4) : const Color(0xFFBDBDBD),
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final selectedIndex = _tabController.index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF333333), width: 1.0),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorColor: const Color(0xFFFFBD10),
            indicatorWeight: 3.0,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: const Color(0xFFF4F4F4),
            unselectedLabelColor: const Color(0xFFBDBDBD),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 18,
              height: 1.56,
              fontFamily: 'ThmanyahSans',
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 18,
              height: 1.56,
              fontFamily: 'ThmanyahSans',
            ),
            tabs: [
              Tab(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _tabIcon('assets/icon_radio_tab.svg', selectedIndex == 0),
                    const SizedBox(width: 8),
                    const Text('إذاعة'),
                  ],
                ),
              ),
              Tab(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _tabIcon(
                      'assets/icon_podcast_tab.svg',
                      selectedIndex == 1,
                    ),
                    const SizedBox(width: 8),
                    const Text('بودكاست'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(50.0),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/search_01.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFFBDBDBD),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ابحث عن ما تريد...',
              style: TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 14,
                height: 1.5,
                fontFamily: 'ThmanyahSans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RADIO TAB ---
  Widget _buildRadioTab() {
    final radioProvider = context.watch<FmRadioProvider>();
    final activeStation = radioProvider.stations.isNotEmpty
        ? radioProvider.stations.first
        : FirebaseFmRadioDataSource.defaultKutubFmStation;

    final programs = activeStation.programs.isNotEmpty
        ? activeStation.programs
        : FirebaseFmRadioDataSource.defaultKutubFmStation.programs;

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        for (final program in programs) ...[
          _buildSectionTitle(program.title),
          for (final audio in program.audios)
            _buildRadioItem(
              station: activeStation,
              program: program,
              audio: audio,
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool showArrow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF4F4F4),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.5,
              fontFamily: 'ThmanyahSans',
            ),
          ),
          if (showArrow)
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 14,
            ),
        ],
      ),
    );
  }

  Widget _buildRadioItem({
    required FmStation station,
    required RadioProgram program,
    required RadioAudio audio,
  }) {
    final radioProvider = context.watch<FmRadioProvider>();
    final isPlayingThisEpisode = radioProvider.isEpisodePlaying(audio.id);

    return GestureDetector(
      onTap: () {
        radioProvider.playRadioEpisode(
          station: station,
          program: program,
          audio: audio,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
        padding: const EdgeInsetsDirectional.only(
          start: 8,
          end: 16,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isPlayingThisEpisode
              ? const Color(0xFF2A2218)
              : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isPlayingThisEpisode
                ? const Color(0xFFFFBD10)
                : const Color(0xFF333333),
          ),
        ),
        child: Row(
          children: [
            // Cover image on the right in RTL
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                'assets/generated/radio_microphone.png',
                width: 50,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 11),
            // Title & time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlayingThisEpisode
                          ? const Color(0xFFFFBD10)
                          : const Color(0xFFF4F4F4),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  if (audio.subtitle != null && audio.subtitle!.isNotEmpty)
                    Text(
                      audio.subtitle!,
                      style: const TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Play icon on the left in RTL
            Icon(
              isPlayingThisEpisode
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_outline_rounded,
              color: isPlayingThisEpisode
                  ? const Color(0xFFFFBD10)
                  : const Color(0xFFF4F4F4),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  // --- PODCAST TAB ---
  Widget _buildPodcastTab() {
    final podcastProvider = context.watch<PodcastProvider>();
    final trendingEpisodes = podcastProvider.trendingEpisodes;
    final popularPodcasts = podcastProvider.popularPodcasts;

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        _buildSectionTitle('الحلقات الأكثر سماعًا', showArrow: true),
        for (final episode in trendingEpisodes)
          _buildPodcastEpisodeItem(episode),
        const SizedBox(height: 16),
        _buildSectionTitle('البرامج المشهورة', showArrow: true),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              for (final podcast in popularPodcasts)
                _buildFamousProgramCard(podcast),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodcastEpisodeItem(PodcastEpisode episode) {
    final audioProvider = context.watch<AudioProvider>();
    final isPlaying = audioProvider.currentTrack?.id == episode.id && audioProvider.isPlaying;

    final subtitle = [
      if (episode.publishedAgo != null) episode.publishedAgo,
      'الموسم ${episode.season}',
      'الحلقة ${episode.episodeNumber}',
    ].where((s) => s != null && s.isNotEmpty).join(' • ');

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/podcast_detail',
          arguments: episode.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isPlaying ? const Color(0xFFFFC00E) : const Color(0xFF333333),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                episode.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/generated/hands_holding_atom.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Middle Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        audioProvider.pause();
                      } else {
                        audioProvider.playPodcast(episode);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC00E),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            episode.duration,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ThmanyahSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Heart Icon
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.favorite_border_rounded, color: Colors.white54, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamousProgramCard(Podcast podcast) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/podcast_list',
          arguments: podcast.id,
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(left: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.network(
                  podcast.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/generated/glowing_open_book.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Heart icon top left
              const Positioned(
                top: 12,
                left: 12,
                child: Icon(Icons.favorite_border_rounded, color: Colors.white70, size: 20),
              ),
              // Text bottom right
              Positioned(
                bottom: 12,
                right: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.author,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      podcast.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${podcast.totalEpisodes} حلقة',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
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
    );
  }

  // --- FLOATING LIVE PLAYER BAR ---
  Widget _buildFloatingLivePlayerBar() {
    final radioProvider = context.watch<FmRadioProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final station = radioProvider.stations.isNotEmpty
        ? radioProvider.stations.first
        : FirebaseFmRadioDataSource.defaultKutubFmStation;

    final isLivePlaying = audioProvider.currentMode == AudioMode.fmRadio &&
        (audioProvider.currentTrack?.isLive ?? false) &&
        audioProvider.isPlaying;

    final isLoading = audioProvider.currentMode == AudioMode.fmRadio &&
        audioProvider.isLoading;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/fm_station_detail',
          arguments: station,
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF040707),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF333333)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14.9,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 8,
                end: 16,
                top: 10,
                bottom: 8,
              ),
              child: Row(
                children: [
                  // Cover Image (right in RTL)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      station.coverImageUrl.isNotEmpty
                          ? station.coverImageUrl
                          : 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/generated/kotob_fm_logo.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF4F4F4),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.5,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // LIVE badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x4CF84749),
                      borderRadius: BorderRadius.circular(12.55),
                      border: Border.all(
                        color: const Color(0xFFF36C6D),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      '● LIVE',
                      style: TextStyle(
                        color: Color(0xFFFF5A5A),
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Play icon (left in RTL)
                  GestureDetector(
                    onTap: () {
                      if (isLivePlaying) {
                        radioProvider.stop();
                      } else {
                        radioProvider.playStation(station);
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFFF36C6D),
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            isLivePlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: const Color(0xFFF36C6D),
                            size: 32,
                          ),
                  ),
                ],
              ),
            ),
            // Red live progress line
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                color: isLivePlaying
                    ? const Color(0xFFF36C6D)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            const SizedBox(height: 1),
          ],
        ),
      ),
    );
  }
}

