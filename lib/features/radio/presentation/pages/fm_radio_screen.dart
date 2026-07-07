import 'package:flutter/material.dart';
import '../../domain/fm_station.dart';

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
        backgroundColor: const Color(0xFF090806),
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
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'ThmanyahSans',
            ),
          ),
          // Back button on the far left in RTL
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1F1F1F),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
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

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF333333),
            width: 1.0,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: const Color(0xFFFFC00E),
        indicatorWeight: 3.0,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'ThmanyahSans',
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 16,
          fontFamily: 'ThmanyahSans',
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radio_rounded, size: 20),
                SizedBox(width: 8),
                Text('إذاعة'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.podcasts_rounded, size: 20),
                SizedBox(width: 8),
                Text('بودكاست'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(25.0),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ابحث عن ما تريد...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'ThmanyahSans',
              ),
            ),
            Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  // --- RADIO TAB ---
  Widget _buildRadioTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        _buildSectionTitle('برنامج التواصل في العصر الحديث'),
        _buildRadioItem('كيف ننجونا في عصر المادية', 'قبل يومين'),
        _buildRadioItem('تأملات في الحرب النفسية الحديثة', 'منذ ساعة'),
        _buildRadioItem('الذكاء الاصطناعي', 'قبل 3 ساعات'),
        _buildRadioItem('العودة إلى الطبيعة', 'أمس'),
        const SizedBox(height: 16),
        _buildSectionTitle('برنامج صناعة الغذاء'),
        _buildRadioItem('رحلة النكهات: اكتشاف أسرار الطهي التقليدي', 'أسبوع مضى'),
        _buildRadioItem('مائدة المستقبل: تقنيات غذائية تغير العالم', 'منذ 3 أيام'),
        _buildRadioItem('قصص مزارع: من الحقل إلى المائدة', 'أمس'),
        _buildRadioItem('الغذاء المستدام: كيف نحمي كوكبنا؟', 'منذ 4 أيام'),
        _buildRadioItem('تاريخ الأطعمة الشعبية: بين الأصالة والحداثة', 'قبل أسبوع'),
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
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'ThmanyahSans',
            ),
          ),
          if (showArrow)
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 14,
            ),
        ],
      ),
    );
  }

  Widget _buildRadioItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          // Image on the right in RTL
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              'assets/generated/radio_microphone.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Middle Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
              ],
            ),
          ),
          // Play Button on the left in RTL
          IconButton(
            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 30),
            onPressed: () {
              // Open station detail screen directly or start playing
              Navigator.pushNamed(
                context,
                '/fm_station_detail',
                arguments: const FmStation(
                  id: 'kotob_fm',
                  name: 'إِذاعة كُتب FM',
                  tagline: 'أول إذاعة كتب عربية',
                  streamUrl: 'https://live.kutubfm.com/stream',
                  coverImageUrl: 'assets/generated/kotob_fm_logo.png',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- PODCAST TAB ---
  Widget _buildPodcastTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        _buildSectionTitle('الحلقات الأكثر سماعًا', showArrow: true),
        _buildPodcastEpisodeItem(
          'كيف تبني نظامًا لا يسقط؟',
          'قبل اسبوع • الموسم الثاني • الحلقه 22',
          '1:55 س',
          'assets/generated/hands_holding_atom.png',
        ),
        _buildPodcastEpisodeItem(
          'لما لا تتقبل نفسك ؟',
          'قبل شهر • الحلقة 5',
          '2:30 د',
          'assets/generated/blue_silhouette_door.png',
        ),
        _buildPodcastEpisodeItem(
          'كيف اصبحنا اسرى العالم الرقمي؟!',
          'أمس • الموسم الأول • الحلقة 10',
          '3:10 د',
          'assets/generated/phones_in_dark.png',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('البرامج المشهورة', showArrow: true),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildFamousProgramCard(
                'قبل طي الصفحة',
                '13 حلقة',
                'عامر واجد',
                'assets/generated/glowing_open_book.png',
              ),
              _buildFamousProgramCard(
                'وراء الملصق الغذائي',
                '6 حلقات',
                'منى رجب',
                'assets/generated/fresh_tomatoes.png',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodcastEpisodeItem(String title, String subtitle, String timeStr, String imgPath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              imgPath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
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
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
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
                    // Navigate to episode detail player screen
                    Navigator.pushNamed(
                      context,
                      '/podcast_detail',
                      arguments: 'episode_1', // default mock episode id
                    );
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
                        const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
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
    );
  }

  Widget _buildFamousProgramCard(String title, String subtitle, String author, String imgPath) {
    return GestureDetector(
      onTap: () {
        // Navigate to the channel / collection page (Screen 3)
        Navigator.pushNamed(
          context,
          '/podcast_list',
          arguments: title,
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(left: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          image: DecorationImage(
            image: AssetImage(imgPath),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Dark overlay to make text readable
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
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
                    author,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
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
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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
    );
  }

  // --- FLOATING LIVE PLAYER BAR ---
  Widget _buildFloatingLivePlayerBar() {
    return GestureDetector(
      onTap: () {
        // Open live station detail screen
        Navigator.pushNamed(
          context,
          '/fm_station_detail',
          arguments: const FmStation(
            id: 'kotob_fm',
            name: 'إِذاعة كُتب FM',
            tagline: 'أول إذاعة كتب عربية',
            streamUrl: 'https://live.kutubfm.com/stream',
            coverImageUrl: 'assets/generated/kotob_fm_logo.png',
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF333333)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                'assets/generated/kotob_fm_logo.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // Title & Live Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إذاعة كُتب FM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ThmanyahSans',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Play/Pause circular red button
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

