import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// MOCK DATA MODEL
// ════════════════════════════════════════════════════════════════════════════
class BookMockData {
  static const String title = "الأعداء";
  static const String authorName = "أنطون تشيخوف";
  static const String authorFullNameRussian = "Антон Павлович Чехов";
  static const String authorLife = "29 يناير 1860 - 15 يوليو 1904";
  static const String category = "قصة قصيرة / أدب روسي";
  static const String translator = "أبي بكر يوسف";
  static const String narrator = "نزار طه حاج أحمد";
  static const String language = "العربية";
  static const String duration = "39 دقيقة";
  static const double rating = 4.8;
  static const int pages = 72;
  static const String shortQuote = "إن الطب هو زوجتي والأدب عشيقتي.";
  static const String description =
      "(29 يناير 1860 - 15 يوليو 1904) (بالروسية: Антон Павлович Чехов) طبيب وكاتب مسرحي ومؤلف قصصي روسي كبير ينظر إليه على أنه من أفضل كتاب القصص القصيرة على مدى التاريخ، ومن كبار الأدباء الروس. كتب المئات من القصص القصيرة التي اعتبر الكثير منها إبداعات فنية كلاسيكية، كما أن مسرحياته كان لها تأثير عظيم على دراما القرن العشرين. بدأ تشيخوف الكتابة عندما كان طالباً في كلية الطب في جامعة موسكو، ولم يترك الكتابة حتى أصبح من أعظم الأدباء، واستمرّ أيضاً في مهنة الطب وكان يقول «إن الطب هو زوجتي والأدب عشيقتي.»\n\nتخلى تشيخوف عن المسرح بعد كارثة حفل النورس في عام 1896، ولكن تم إحياء المسرحية في عام 1898 من قبل قسطنطين ستانيسلافسكي في مسرح موسكو للفنون، التي أنتجت في وقت لاحق أيضًا العم فانيا لتشيخوف وعرضت آخر مسرحياته لأول مرة، الأخوات الثلاث وبستان الكرز. تتميز أعماله بالمزاجية المسرحية والحياة المضمرة في النص.\n\nكان تشيخوف يكتب في البداية لتحقيق مكاسب مادية فقط، لكن طموحاته الفنية نمت سريعًا، وابتكر تقنيات أثرت على تطور القصة القصيرة الحديثة. من أبرز سماته الاستخدام المبتكر لتدفق الشعور الإنساني، مع التخلي عن النهايات المباشرة والبنية التقليدية. وكان يرى أن دور الفنان هو طرح الأسئلة وليس تقديم الإجابات.";

  // ── YouTube thumbnail as book cover ───────────────────────────────────────
  static const String coverUrl =
      "https://i.ytimg.com/vi/Ie6vcn8gel4/maxresdefault.jpg";
}

// ════════════════════════════════════════════════════════════════════════════
// REVIEW DATA MODEL
// ════════════════════════════════════════════════════════════════════════════
class BookReview {
  final String id;
  final String authorName;
  final String avatarUrl;
  final String text;
  final int rating; // 1–5 stars
  final String timeAgo;
  int likes;
  bool isLikedByMe;

  BookReview({
    required this.id,
    required this.authorName,
    required this.avatarUrl,
    required this.text,
    required this.rating,
    required this.timeAgo,
    this.likes = 0,
    this.isLikedByMe = false,
  });
}

// Separate singleton list so new posts persist while user scrolls
final List<BookReview> _mockReviews = [
  BookReview(
    id: '1',
    authorName: 'سارة خالد',
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
    text:
        'من أروع ما قرأت في الأدب الروسي. تشيخوف قادر بجملة واحدة أن يرسم عالماً كاملاً. الترجمة أيضاً رائعة وبسيطة.',
    rating: 5,
    timeAgo: 'منذ يومين',
    likes: 34,
  ),
  BookReview(
    id: '2',
    authorName: 'محمد العمري',
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
    text:
        'قصة قصيرة لكنها عميقة جداً. الصراع بين الألم الشخصي والواجب الإنساني يجعلك تتأمل طويلاً بعد انتهائها.',
    rating: 5,
    timeAgo: 'منذ 5 ساعات',
    likes: 21,
  ),
  BookReview(
    id: '3',
    authorName: 'لمياء الزهراني',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    text:
        'الأداء الصوتي ممتاز وجميل جداً. يضيف بُعداً آخر للقصة. أتمنى المزيد من الأعمال المترجمة بهذا المستوى.',
    rating: 4,
    timeAgo: 'منذ 3 أيام',
    likes: 18,
  ),
  BookReview(
    id: '4',
    authorName: 'فيصل الدوسري',
    avatarUrl: 'https://i.pravatar.cc/150?img=8',
    text:
        'استمعت إليها مرتين. في كل مرة أكتشف تفصيلاً جديداً لم أنتبه إليه. عبقرية تشيخوف في الاختزال مذهلة.',
    rating: 5,
    timeAgo: 'منذ أسبوع',
    likes: 45,
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// THEME
// ════════════════════════════════════════════════════════════════════════════
class _T {
  static const Color bg = AppTheme.background;
  static const Color surf = Color(0xFF1C1C1E);
  static const Color gold = AppTheme.primary;
  static const Color text = AppTheme.onSurface;
  static const Color mute = AppTheme.onSurfaceVariant;
}

// ════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN (StatefulWidget for reviews state)
// ════════════════════════════════════════════════════════════════════════════
class BookDetailsPage extends StatefulWidget {
  const BookDetailsPage({super.key});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  // ── Review state ────────────────────────────────────────────────────────
  final List<BookReview> _reviews = List.from(_mockReviews);
  int _pendingStars = 0; // stars chosen by user before submitting

  // ── Add-review sheet controller ─────────────────────────────────────────
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Average rating ───────────────────────────────────────────────────────
  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;
  }

  // ── Add review ────────────────────────────────────────────────────────────
  void _submitReview() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final stars = _pendingStars == 0 ? 5 : _pendingStars;
    setState(() {
      _reviews.insert(
        0,
        BookReview(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          authorName: 'أنت',
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
          text: text,
          rating: stars,
          timeAgo: 'الآن',
          likes: 0,
        ),
      );
      _pendingStars = 0;
    });
    _commentCtrl.clear();
    _focusNode.unfocus();
    Navigator.pop(context); // close bottom sheet
    HapticFeedback.mediumImpact();
  }

  // ── Like toggle ───────────────────────────────────────────────────────────
  void _toggleLike(BookReview review) {
    setState(() {
      if (review.isLikedByMe) {
        review.likes--;
        review.isLikedByMe = false;
      } else {
        review.likes++;
        review.isLikedByMe = true;
      }
    });
    HapticFeedback.selectionClick();
  }

  // ── Show add-review bottom sheet ─────────────────────────────────────────
  void _showAddReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _T.surf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddReviewSheet(
        commentCtrl: _commentCtrl,
        focusNode: _focusNode,
        pendingStars: _pendingStars,
        onStarTap: (s) => setState(() => _pendingStars = s),
        onSubmit: _submitReview,
      ),
    );
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildHeroSection(),
            _buildActionButtons(),
            _buildMetadataGrid(),
            _buildQuoteCard(),
            _buildSectionTitle('نبذة عن القصة'),
            _buildDescription(),
            _buildSectionTitle('عن المؤلف'),
            _buildAuthorSection(),
            _buildSectionTitle('كتب ذات صلة'),
            _buildRelatedSection(),
            _buildReviewsHeader(),
            _buildReviewsList(),
            _buildAddReviewButton(),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() => SliverAppBar(
    pinned: true,
    backgroundColor: _T.bg.withValues(alpha: 0.96),
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: _T.gold,
        size: 20,
      ),
      onPressed: () => Navigator.pop(context),
    ),
    actions: [
      IconButton(
        icon: const Icon(
          Icons.favorite_border_rounded,
          color: Colors.white,
          size: 22,
        ),
        onPressed: () => HapticFeedback.mediumImpact(),
      ),
      IconButton(
        icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
        onPressed: () {},
      ),
    ],
  );

  // ── HERO ─────────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildHeroSection() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _T.gold.withValues(alpha: 0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -8,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  BookMockData.coverUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : Container(
                          color: _T.surf,
                          child: const Center(
                            child: CircularProgressIndicator(color: _T.gold),
                          ),
                        ),
                  errorBuilder: (ctx, obj, err) => Container(
                    color: _T.surf,
                    child: const Icon(
                      Icons.book_rounded,
                      color: _T.gold,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _goldBadge(BookMockData.category),
          const SizedBox(height: 16),
          Text(
            BookMockData.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: _T.gold,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            BookMockData.authorName,
            style: GoogleFonts.amiri(
              color: _T.mute,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // "Average rating" stars + count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._starRow(_avgRating),
              const SizedBox(width: 8),
              Text(
                '${_avgRating.toStringAsFixed(1)} (${_reviews.length} تقييم)',
                style: const TextStyle(color: _T.mute, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildActionButtons() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _BigButton(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, AppRoutes.audioPlayer);
              },
              icon: Icons.headset_rounded,
              label: "استمع الآن",
              primary: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BigButton(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(
                  context,
                  AppRoutes.bookReader,
                  arguments: const BookReaderScreenArgs(
                    pdfAssetPath: 'assets/transcript.json',
                    bookTitle: BookMockData.title,
                  ),
                );
              },
              icon: Icons.menu_book_rounded,
              label: "اقرأ الآن",
              primary: false,
            ),
          ),
        ],
      ),
    ),
  );

  // ── METADATA GRID ─────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildMetadataGrid() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _T.surf,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metaItem(Icons.star_rounded, BookMockData.rating, "تقييم"),
            _vDivider(),
            _metaItem(
              Icons.access_time_filled_rounded,
              BookMockData.duration,
              "مدة",
            ),
            _vDivider(),
            _metaItem(Icons.language_rounded, BookMockData.language, "لغة"),
            _vDivider(),
            _metaItem(
              Icons.auto_stories_rounded,
              "${BookMockData.pages}",
              "صفحة",
            ),
          ],
        ),
      ),
    ),
  );

  Widget _metaItem(IconData icon, dynamic value, String label) => Column(
    children: [
      Icon(icon, color: _T.gold, size: 20),
      const SizedBox(height: 6),
      Text(
        "$value",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      Text(label, style: const TextStyle(color: _T.mute, fontSize: 10)),
    ],
  );

  Widget _vDivider() => Container(
    width: 1,
    height: 30,
    color: Colors.white.withValues(alpha: 0.1),
  );

  // ── QUOTE CARD ────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildQuoteCard() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_T.gold.withValues(alpha: 0.14), _T.surf],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _T.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: _T.gold.withValues(alpha: 0.5),
              size: 40,
            ),
            const SizedBox(height: 14),
            Text(
              BookMockData.shortQuote,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: _T.gold,
                fontSize: 22,
                height: 1.5,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── DESCRIPTION ───────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildDescription() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        BookMockData.description,
        style: GoogleFonts.amiri(
          color: _T.text.withValues(alpha: 0.8),
          fontSize: 17,
          height: 1.8,
        ),
      ),
    ),
  );

  // ── AUTHOR SECTION ────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildAuthorSection() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _T.surf,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.gold.withValues(alpha: 0.2),
                    border: Border.all(color: _T.gold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.person, color: _T.gold, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BookMockData.authorName,
                        style: GoogleFonts.amiri(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        BookMockData.authorFullNameRussian,
                        style: const TextStyle(color: _T.mute, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _authorRow(Icons.calendar_today_rounded, BookMockData.authorLife),
            const SizedBox(height: 12),
            _authorRow(
              Icons.translate_rounded,
              "المترجم: ${BookMockData.translator}",
            ),
            const SizedBox(height: 12),
            _authorRow(
              Icons.record_voice_over_rounded,
              "بصوت: ${BookMockData.narrator}",
            ),
          ],
        ),
      ),
    ),
  );

  Widget _authorRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: _T.gold.withValues(alpha: 0.6)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(text, style: const TextStyle(color: _T.mute, fontSize: 13)),
      ),
    ],
  );

  // ── RELATED ───────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildRelatedSection() => SliverToBoxAdapter(
    child: SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, i) => Container(
          width: 110,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _T.surf,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.book_rounded, color: Colors.white12, size: 40),
          ),
        ),
      ),
    ),
  );

  // ── REVIEWS HEADER (aggregate stats) ─────────────────────────────────────
  SliverToBoxAdapter _buildReviewsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 40,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'التعليقات والتقييمات',
                  style: GoogleFonts.amiri(
                    color: _T.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_reviews.length} تقييم',
                  style: const TextStyle(color: _T.mute, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Rating summary bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _T.surf,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Big score
                  Column(
                    children: [
                      Text(
                        _avgRating.toStringAsFixed(1),
                        style: GoogleFonts.amiri(
                          color: _T.gold,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: _starRow(_avgRating)),
                      const SizedBox(height: 4),
                      Text(
                        '${_reviews.length} مراجعة',
                        style: const TextStyle(color: _T.mute, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  const VerticalDivider(color: Colors.white12, thickness: 1),
                  const SizedBox(width: 20),
                  // Histogram bars
                  Expanded(
                    child: Column(
                      children: List.generate(5, (i) {
                        final star = 5 - i;
                        final count = _reviews
                            .where((r) => r.rating == star)
                            .length;
                        final frac = _reviews.isEmpty
                            ? 0.0
                            : count / _reviews.length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Text(
                                '$star',
                                style: const TextStyle(
                                  color: _T.mute,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star_rounded,
                                color: _T.gold,
                                size: 10,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: frac,
                                    minHeight: 6,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.07,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          _T.gold,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

  // ── REVIEWS LIST ──────────────────────────────────────────────────────────
  SliverList _buildReviewsList() => SliverList(
    delegate: SliverChildBuilderDelegate(
      (ctx, i) => _ReviewCard(
        review: _reviews[i],
        onLike: () => _toggleLike(_reviews[i]),
      ),
      childCount: _reviews.length,
    ),
  );

  // ── ADD REVIEW BUTTON ─────────────────────────────────────────────────────
  SliverToBoxAdapter _buildAddReviewButton() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GestureDetector(
        onTap: _showAddReviewSheet,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: _T.gold.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(20),
            color: _T.gold.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rate_review_rounded,
                color: _T.gold.withValues(alpha: 0.8),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'أضف تعليقك وتقييمك',
                style: GoogleFonts.amiri(
                  color: _T.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _goldBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: _T.gold.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _T.gold.withValues(alpha: 0.3)),
    ),
    child: Text(
      text,
      style: GoogleFonts.amiri(
        color: _T.gold,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  List<Widget> _starRow(double rating) {
    return List.generate(5, (i) {
      final full = i < rating.floor();
      final half = !full && i < rating;
      return Icon(
        full
            ? Icons.star_rounded
            : half
            ? Icons.star_half_rounded
            : Icons.star_outline_rounded,
        color: _T.gold,
        size: 16,
      );
    });
  }

  SliverToBoxAdapter _buildSectionTitle(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.amiri(
          color: _T.gold,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// REVIEW CARD WIDGET
// ════════════════════════════════════════════════════════════════════════════
class _ReviewCard extends StatelessWidget {
  final BookReview review;
  final VoidCallback onLike;

  const _ReviewCard({required this.review, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + time
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(review.avatarUrl),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppTheme.primary,
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            review.timeAgo,
                            style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Review text
            Text(
              review.text,
              style: GoogleFonts.amiri(
                color: AppTheme.onSurface.withValues(alpha: 0.82),
                fontSize: 15,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 12),

            // Like row
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: review.isLikedByMe
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: review.isLikedByMe
                            ? AppTheme.primary.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          review.isLikedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: review.isLikedByMe
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${review.likes}',
                          style: TextStyle(
                            color: review.isLikedByMe
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ADD REVIEW BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════════
class _AddReviewSheet extends StatefulWidget {
  final TextEditingController commentCtrl;
  final FocusNode focusNode;
  final int pendingStars;
  final ValueChanged<int> onStarTap;
  final VoidCallback onSubmit;

  const _AddReviewSheet({
    required this.commentCtrl,
    required this.focusNode,
    required this.pendingStars,
    required this.onStarTap,
    required this.onSubmit,
  });

  @override
  State<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  late int _stars;

  @override
  void initState() {
    super.initState();
    _stars = widget.pendingStars == 0 ? 5 : widget.pendingStars;
    // Open keyboard immediately
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.focusNode.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'أضف تقييمك',
                style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Star selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _stars = star);
                      widget.onStarTap(star);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          star <= _stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          key: ValueKey('$star-${star <= _stars}'),
                          color: AppTheme.primary,
                          size: 38,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Text field
              TextField(
                controller: widget.commentCtrl,
                focusNode: widget.focusNode,
                maxLines: 5,
                minLines: 3,
                style: GoogleFonts.amiri(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'اكتب تعليقك هنا...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: widget.onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'إرسال التقييم',
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PRIMARY ACTION BUTTON
// ════════════════════════════════════════════════════════════════════════════
class _BigButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool primary;

  const _BigButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: primary ? AppTheme.primary : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primary ? Colors.black : Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
