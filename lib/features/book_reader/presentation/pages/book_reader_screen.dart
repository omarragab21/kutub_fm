import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kutub_fm/features/audio_player/presentation/pages/audio_player_screen.dart';

class BookReaderScreenArgs {
  final String pdfAssetPath;
  final String bookTitle;
  final String audioUrl;
  final String chapterId;
  final String? transcript;
  final String? bookCoverUrl;

  const BookReaderScreenArgs({
    required this.pdfAssetPath,
    required this.bookTitle,
    required this.audioUrl,
    required this.chapterId,
    this.transcript,
    this.bookCoverUrl,
  });
}

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF040707), // #040707 Page BG from Figma
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF040707),
          elevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Actions: Chevron Back and Sliders/Tune icon
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                      const SizedBox(width: 16),
                      SvgPicture.asset(
                        'assets/filter.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        width: 24,
                        height: 24,
                      ),
                    ],
                  ),
                  // Center Title
                  const Text(
                    'مئة عام من العزلة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  // Right Actions: Bookmark and Highlighter/Edit icon
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/bookmark.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 16),
                      SvgPicture.asset(
                        'assets/highlighter.svg',
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
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الفصل الأول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ThmanyahSans',
                            ),
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                height: 1.8,
                                fontFamily: 'ThmanyahSans',
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'في مدينة لا تنام، تُعرف بين سكانها باسم "مدينة الوهم". كانت الأضواء دائمًا تخفي أكثر مما تكشف. الشوارع القديمة تحمل همسات الماضي، ',
                                ),
                                TextSpan(
                                  text:
                                      'والوجوه العابرة تخفي قصصًا لم تُروَ بعد.',
                                  style: TextStyle(
                                    backgroundColor: const Color(
                                      0xFFF38181,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ' هناك، في ليلة بدا فيها كل شيء عاديًا، تظهر بوابة غامضة تقود إلى زمن آخر...\n\n',
                                ),
                                TextSpan(
                                  text: 'زمن يرتبط',
                                  style: const TextStyle(
                                    backgroundColor: Color(0xFFFFBD10),
                                    color: Color(0xFF1F1F1F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ' بسر عائلة الرياح المؤسسة. العائلة التي بُنيت المدينة على أنقاض قوتها واختفائها المفاجئ. تبدأ الرحلة حين يجد الأبطال أنفسهم أمام سلسلة من الأحداث التي تتجاوز حدود الواقع.\n\nحيث تختلط الذكريات بالأحلام، ويصبح من الصعب التفرقة بين الحقيقة والوهم. ومع كل خطوة داخل هذا العالم الغامض، \n\nتتكشف أسرار قديمة عن السلطة، الخيانة، والتحالفات التي شكّلت مصير المدينة لسنوات طويلة. في مدينة لا تنام، تُعرف بين سكانها باسم "مدينة الوهم". كانت الأضواء دائمًا تخفي أكثر مما تكشف. الشوارع القديمة تحمل همسات الماضي،',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Progress Bar
                  GestureDetector(
                    onTap: () => _showChaptersBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF1F1F1F,
                        ), // Match cards/primary-card
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Right side: الفصل الأول + circle arrow up
                              Row(
                                children: [
                                  const Text(
                                    'الفصل الأول',
                                    style: TextStyle(
                                      color: Color(0xFFF4F4F4),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'ThmanyahSans',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.chevron_up_circle,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              // Left side: فصول الكتاب + chevron back
                              Row(
                                children: const [
                                  Icon(
                                    Icons.chevron_left,
                                    color: Colors.white54,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'فصول الكتاب',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                      fontFamily: 'ThmanyahSans',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Custom-width segments from Figma design React mockup
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSegment(72, true),
                                const SizedBox(width: 2),
                                _buildSegment(15, true),
                                const SizedBox(width: 2),
                                _buildSegment(71, true),
                                const SizedBox(width: 2),
                                _buildSegment(28, true),
                                const SizedBox(width: 2),
                                _buildSegment(30, true),
                                const SizedBox(width: 2),
                                _buildSegment(59, true),
                                const SizedBox(width: 2),
                                _buildSegment(20, true),
                                const SizedBox(width: 2),
                                _buildSegment(
                                  49,
                                  false,
                                ), // Leftmost segment (Chapter 8) is grey
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Text Selection Popup Overlay (Figma Node 19118:12690)
              Positioned(top: 180, right: 30, child: _buildTextPopup()),

              // Caption Tag Overlay (Figma Node 19121:12885)
              Positioned(top: 310, right: 30, child: _buildCaptionTag()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(double width, bool isActive) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFF4F4F4)
            : const Color(0xFFF4F4F4).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildTextPopup() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6.3,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.share_outlined, color: Colors.black, size: 20),
          _buildPopupDivider(),
          const Icon(Icons.format_quote, color: Colors.black, size: 20),
          _buildPopupDivider(),
          Row(
            children: [
              _buildColorCircle(const Color(0xFFFFAE56)),
              const SizedBox(width: 4),
              _buildColorCircle(const Color(0xFFFFDA62)),
              const SizedBox(width: 4),
              _buildColorCircle(const Color(0xFFF38181)),
              const SizedBox(width: 4),
              _buildColorCircle(const Color(0xFFAA96DA)),
              const SizedBox(width: 4),
              _buildColorCircle(const Color(0xFF609966)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 1,
      height: 20,
      color: Colors.black12,
    );
  }

  Widget _buildColorCircle(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildCaptionTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFBD10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'زمن يرتبط',
        style: TextStyle(
          color: Color(0xFF1F1F1F),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'ThmanyahSans',
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
                    // Navigate to the Audio Player screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AudioPlayerScreen(),
                      ),
                    );
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
                    // Tapping book when already in reader screen
                    // pops the modal sheet (allowing them to see the reader context)
                    Navigator.pop(context);
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
