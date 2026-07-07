import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kutub_fm/features/book_reader/presentation/pages/book_reader_screen.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0C0C),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top Bar (Aligned to top-left to follow Figma design layout)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'assets/arrow_back.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 18,
                          height: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // Cover Image
                Center(
                  child: Container(
                    width: 220,
                    height: 309,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/miah_aam_cover.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Title and Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      const Text(
                        'مئة عام من العزلة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أحمد خالد توفيق',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Action Icons (Order reversed in children list so that it renders Book on the right and Share on the left in RTL)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BookReaderScreen(),
                                ),
                              );
                            },
                            child: SvgPicture.asset(
                              'assets/nav_books.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              width: 28,
                              height: 28,
                            ),
                          ),
                          const SizedBox(width: 32),
                          SvgPicture.asset(
                            'assets/download.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 32),
                          SvgPicture.asset(
                            'assets/heart.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 32),
                          SvgPicture.asset(
                            'assets/share.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            width: 28,
                            height: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Soundwave
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(40, (index) {
                          final isPlayed = index < 25;
                          final height =
                              10.0 + (index % 5) * 5.0 + (index % 3) * 8.0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 4,
                            height: height > 35 ? 35 : height,
                            decoration: BoxDecoration(
                              color: isPlayed
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Timers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '50:30',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const Text(
                            '14:30',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Media Controls (Wrapped in LTR to ensure exact left-to-right alignment and chevron orientations)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SvgPicture.asset(
                              'assets/backward.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              width: 35,
                              height: 35,
                            ),
                            SvgPicture.asset(
                              'assets/replay_10.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              width: 30,
                              height: 30,
                            ),
                            SvgPicture.asset(
                              'assets/play_circle.svg',
                              width: 70,
                              height: 70,
                            ),
                            SvgPicture.asset(
                              'assets/forward_10.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              width: 30,
                              height: 30,
                            ),
                            SvgPicture.asset(
                              'assets/forward.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              width: 35,
                              height: 35,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Next Chapter Button
                      GestureDetector(
                        onTap: () => _showChaptersBottomSheet(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الفصل التالي',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'فصول الكتاب',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SvgPicture.asset(
                                  'assets/arrow_back.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white54,
                                    BlendMode.srcIn,
                                  ),
                                  width: 16,
                                  height: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Next Chapter Preview Card
                      GestureDetector(
                        onTap: () => _showChaptersBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '1',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'الفصل الرابع',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '45 دقيقة',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/nav_books.svg',
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  SvgPicture.asset(
                                    'assets/play.svg',
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    width: 24,
                                    height: 24,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChaptersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Color(0xFF0C0C0C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'فصول الكتاب',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chapter List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildChapterItem('الفصل الأول', '45 دقيقة', '1', false),
                      const SizedBox(height: 12),
                      _buildChapterItem('الفصل الثاني', '50 دقيقة', '2', false),
                      const SizedBox(height: 12),
                      _buildChapterItem(
                        'الفصل الثالث',
                        '40 دقيقة',
                        '3',
                        true,
                      ), // Currently playing
                      const SizedBox(height: 12),
                      _buildChapterItem('الفصل الرابع', '55 دقيقة', '4', false),
                      const SizedBox(height: 12),
                      _buildChapterItem('الفصل الخامس', '35 دقيقة', '5', false),
                      const SizedBox(height: 12),
                      _buildChapterItem('الفصل السادس', '60 دقيقة', '6', false),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterItem(
    String title,
    String duration,
    String index,
    bool isPlaying,
  ) {
    return Opacity(
      opacity: isPlaying ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Row(
          children: [
            // Left side: Buttons (Play/Pause + Read Book)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    // Tapping play/pause when already in the player screen
                    // pops the modal sheet (allowing them to see/hear the active player context)
                    Navigator.pop(context);
                  },
                  child: isPlaying
                      ? SvgPicture.asset(
                          'assets/pause.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/play.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white54,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    // Navigate to the Book Reader screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookReaderScreen(),
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/nav_books.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white54,
                      BlendMode.srcIn,
                    ),
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Middle side: Chapter Title and duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Right side: Index circle or Audio Wave
            if (isPlaying)
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/audio_wave.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF333333), width: 1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    index,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
