import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';
import '../../domain/entities/book_detail_model.dart';
import 'creator_details_page.dart';
import '../viewmodels/book_details_view_model.dart';
import '../../data/repositories/book_details_repository_impl.dart';

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
  final String userId;
  final String authorName;
  final String avatarUrl;
  final String text;
  final int rating; // 1–5 stars
  final String timeAgo;
  final DateTime? createdAt;
  final DocumentReference<Map<String, dynamic>>? ref;
  final List<BookReview> replies;
  int likes;
  bool isLikedByMe;

  BookReview({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.avatarUrl,
    required this.text,
    required this.rating,
    required this.timeAgo,
    this.createdAt,
    this.ref,
    this.replies = const [],
    this.likes = 0,
    this.isLikedByMe = false,
  });
}

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
  final String? bookId;
  const BookDetailsPage({super.key, this.bookId});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  // ── Review state ────────────────────────────────────────────────────────
  List<BookReview> _reviews = const [];
  int _pendingStars = 0; // stars chosen by user before submitting
  bool _isReviewsLoading = true;
  String? _reviewsError;
  BookReview? _replyTarget;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _commentsSub;

  // ── Add-review sheet controller ─────────────────────────────────────────
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _listenToBookComments();
  }

  @override
  void didUpdateWidget(covariant BookDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      _listenToBookComments();
    }
  }

  @override
  void dispose() {
    _commentsSub?.cancel();
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _targetBookId => widget.bookId ?? 'book_late_arrival';

  CollectionReference<Map<String, dynamic>> get _commentsCollection =>
      FirebaseFirestore.instance
          .collection('books')
          .doc(_targetBookId)
          .collection('comments');

  // ── Average rating ───────────────────────────────────────────────────────
  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;
  }

  // ── Add review ────────────────────────────────────────────────────────────
  Future<void> _submitReview() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('سجل الدخول لإضافة تعليق')));
      return;
    }

    final stars = _pendingStars == 0 ? 5 : _pendingStars;
    final userName = _currentUserName(auth);
    final userAvatar = _currentUserAvatar(auth);

    try {
      final replyTarget = _replyTarget;
      final payload = {
        'userId': user.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'text': text,
        'rating': replyTarget == null ? stars : 0,
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (replyTarget == null) {
        await _commentsCollection.add(payload);
      } else {
        await replyTarget.ref?.collection('replies').add(payload);
      }

      setState(() {
        _pendingStars = 0;
        _replyTarget = null;
      });
      _commentCtrl.clear();
      _focusNode.unfocus();
      if (mounted) Navigator.pop(context);
      HapticFeedback.mediumImpact();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حفظ التعليق: $error')));
    }
  }

  // ── Like toggle ───────────────────────────────────────────────────────────
  Future<void> _toggleLike(BookReview review) async {
    final user = context.read<AuthProvider>().user;
    if (user == null || review.ref == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجل الدخول لتسجيل الإعجاب')),
      );
      return;
    }

    HapticFeedback.selectionClick();
    final likeRef = review.ref!.collection('likes').doc(user.uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final likeSnap = await transaction.get(likeRef);
      if (likeSnap.exists) {
        transaction.delete(likeRef);
        transaction.update(review.ref!, {
          'likesCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(likeRef, {
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(review.ref!, {
          'likesCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ── Show add-review bottom sheet ─────────────────────────────────────────
  void _showAddReviewSheet({BookReview? replyTo}) {
    setState(() => _replyTarget = replyTo);
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
        replyTargetName: replyTo?.authorName,
        onStarTap: (s) => setState(() => _pendingStars = s),
        onSubmit: _submitReview,
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _replyTarget = null);
    });
  }

  void _listenToBookComments() {
    _commentsSub?.cancel();
    setState(() {
      _isReviewsLoading = true;
      _reviewsError = null;
      _reviews = const [];
    });

    _commentsSub = _commentsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) async {
            try {
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final reviews = await Future.wait(
                snapshot.docs.map(
                  (doc) => _reviewFromSnapshot(doc, currentUserId),
                ),
              );
              if (!mounted) return;
              setState(() {
                _reviews = reviews;
                _isReviewsLoading = false;
                _reviewsError = null;
              });
            } catch (error) {
              if (!mounted) return;
              setState(() {
                _isReviewsLoading = false;
                _reviewsError = error.toString();
              });
            }
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isReviewsLoading = false;
              _reviewsError = error.toString();
              _reviews = const [];
            });
          },
        );
  }

  Future<BookReview> _reviewFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? currentUserId,
  ) async {
    final data = doc.data();
    final ref = doc.reference;
    final repliesSnap = await ref
        .collection('replies')
        .orderBy('createdAt')
        .get();
    final replies = await Future.wait(
      repliesSnap.docs.map(
        (replyDoc) => _reviewFromSnapshot(replyDoc, currentUserId),
      ),
    );

    final likesSnap = await ref.collection('likes').get();
    final isLikedByMe = currentUserId == null
        ? false
        : likesSnap.docs.any((doc) => doc.id == currentUserId);
    final storedLikesCount = (data['likesCount'] as num?)?.round();

    return BookReview(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      authorName: data['userName']?.toString().trim().isNotEmpty == true
          ? data['userName'].toString()
          : 'مستخدم كتب FM',
      avatarUrl: data['userAvatar']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      rating: (data['rating'] as num?)?.round() ?? 0,
      timeAgo: _timeAgo((data['createdAt'] as Timestamp?)?.toDate()),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      ref: ref,
      replies: replies,
      likes: storedLikesCount ?? likesSnap.size,
      isLikedByMe: isLikedByMe,
    );
  }

  String _currentUserName(AuthProvider auth) {
    final appName = auth.appUser?.name.trim();
    if (appName != null && appName.isNotEmpty) return appName;
    final displayName = auth.user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return 'مستخدم كتب FM';
  }

  String _currentUserAvatar(AuthProvider auth) {
    final appAvatar = auth.appUser?.photoUrl?.trim();
    if (appAvatar != null && appAvatar.isNotEmpty) return appAvatar;
    final photoUrl = auth.user?.photoURL?.trim();
    if (photoUrl != null && photoUrl.isNotEmpty) return photoUrl;
    return '';
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'الآن';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
  }

  String _formatDuration(String durationStr) {
    if (durationStr.isEmpty) return '';
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]);
      if (minutes != null) {
        if (minutes == 1) return 'دقيقة واحدة';
        if (minutes == 2) return 'دقيقتان';
        if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
        return '$minutes دقيقة';
      }
    } else if (parts.length == 3) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      if (hours != null && minutes != null) {
        String hoursStr = '';
        if (hours == 1) {
          hoursStr = 'ساعة';
        } else if (hours == 2) {
          hoursStr = 'ساعتان';
        } else if (hours >= 3 && hours <= 10) {
          hoursStr = '$hours ساعات';
        } else {
          hoursStr = '$hours ساعة';
        }

        if (minutes == 0) {
          return hoursStr;
        }

        String minutesStr = '';
        if (minutes == 1) {
          minutesStr = 'دقيقة';
        } else if (minutes == 2) {
          minutesStr = 'دقيقتان';
        } else if (minutes >= 3 && minutes <= 10) {
          minutesStr = '$minutes دقائق';
        } else {
          minutesStr = '$minutes دقيقة';
        }

        return '$hoursStr و $minutesStr';
      }
    }
    return durationStr;
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BookDetailsViewModel>(
      create: (_) => BookDetailsViewModel(
        repository: BookDetailsRepositoryImpl(),
        bookId: _targetBookId,
      ),
      child: Consumer<BookDetailsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(
              backgroundColor: _T.bg,
              body: Center(child: CircularProgressIndicator(color: _T.gold)),
            );
          }

          if (viewModel.errorMessage != null) {
            return Scaffold(
              backgroundColor: _T.bg,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: viewModel.loadBookDetails,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final book = viewModel.book;
          if (book == null) {
            return const Scaffold(
              backgroundColor: _T.bg,
              body: Center(
                child: Text(
                  'لم يتم العثور على الكتاب',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: _T.bg,
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(viewModel),
                  _buildHeroSection(book),
                  _buildMetadataGrid(book),
                  if (book.shortQuote.isNotEmpty) _buildQuoteCard(book),
                  _buildSectionTitle('نبذة عن القصة'),
                  _buildDescription(book),
                  _buildSectionTitle('عن المؤلف'),
                  _buildAuthorSection(book),
                  _buildSectionTitle('شباتر الكتاب'),
                  _buildChaptersList(book),
                  _buildRelatedSection(),
                  _buildReviewsHeader(),
                  _buildReviewsList(),
                  _buildAddReviewButton(),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BookDetailsViewModel viewModel) => SliverAppBar(
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
        icon: Icon(
          viewModel.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: viewModel.isFavorite ? _T.gold : Colors.white,
          size: 22,
        ),
        onPressed: () {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null || user.isAnonymous) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سجل الدخول لإضافة الكتاب إلى المفضلة')),
            );
            return;
          }
          HapticFeedback.mediumImpact();
          viewModel.toggleFavorite();
        },
      ),
      IconButton(
        icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
        onPressed: () {},
      ),
    ],
  );

  // ── HERO ─────────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildHeroSection(BookDetail book) => SliverToBoxAdapter(
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
                  book.imageUrl,
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
          if (book.category.isNotEmpty) ...[
            _goldBadge(book.category),
            const SizedBox(height: 16),
          ],
          Text(
            book.title,
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
            book.author,
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
              ..._starRow(book.rating.toDouble()),
              const SizedBox(width: 8),
              Text(
                '${book.rating.toStringAsFixed(1)} (${_reviews.length} تقييم)',
                style: const TextStyle(color: _T.mute, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── METADATA GRID ─────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildMetadataGrid(BookDetail book) => SliverToBoxAdapter(
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
            _metaItem(Icons.star_rounded, book.rating, "تقييم"),
            _vDivider(),
            _metaItem(
              Icons.access_time_filled_rounded,
              _formatDuration(book.duration),
              "مدة",
            ),
            _vDivider(),
            _metaItem(Icons.language_rounded, book.language, "لغة"),
            _vDivider(),
            _metaItem(Icons.auto_stories_rounded, "${book.pages}", "صفحة"),
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
  SliverToBoxAdapter _buildQuoteCard(BookDetail book) => SliverToBoxAdapter(
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
              book.shortQuote,
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
  SliverToBoxAdapter _buildDescription(BookDetail book) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        book.description,
        style: GoogleFonts.amiri(
          color: _T.text.withValues(alpha: 0.8),
          fontSize: 17,
          height: 1.8,
        ),
      ),
    ),
  );

  // ── AUTHOR SECTION ────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildAuthorSection(BookDetail book) {
    final showRussianName = book.authorFullNameRussian.isNotEmpty;
    final showLife = book.authorLife.isNotEmpty;
    final showTranslator = book.translator.isNotEmpty;
    final showNarrator = book.narrator.isNotEmpty;
    final showPublisher = book.publisherName.isNotEmpty;

    return SliverToBoxAdapter(
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openCreatorDetails(
                        id: book.authorId,
                        name: book.author,
                        roleLabel: 'المؤلف',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  book.author,
                                  style: GoogleFonts.amiri(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_left_rounded,
                                color: _T.gold,
                                size: 18,
                              ),
                            ],
                          ),
                          if (showRussianName) ...[
                            const SizedBox(height: 2),
                            Text(
                              book.authorFullNameRussian,
                              style: const TextStyle(
                                color: _T.mute,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (showLife ||
                  showTranslator ||
                  showNarrator ||
                  showPublisher) ...[
                const SizedBox(height: 24),
                if (showLife) ...[
                  _authorRow(Icons.calendar_today_rounded, book.authorLife),
                  if (showTranslator || showNarrator || showPublisher)
                    const SizedBox(height: 12),
                ],
                if (showTranslator) ...[
                  _authorRow(
                    Icons.translate_rounded,
                    "المترجم: ${book.translator}",
                    onTap: () => _openCreatorDetails(
                      id: book.translatorId,
                      name: book.translator,
                      roleLabel: 'المترجم',
                    ),
                  ),
                  if (showNarrator || showPublisher) const SizedBox(height: 12),
                ],
                if (showNarrator) ...[
                  _authorRow(
                    Icons.record_voice_over_rounded,
                    "بصوت: ${book.narrator}",
                    onTap: () => _openCreatorDetails(
                      id: book.narratorId,
                      name: book.narrator,
                      roleLabel: 'القارئ',
                    ),
                  ),
                  if (showPublisher) const SizedBox(height: 12),
                ],
                if (showPublisher) ...[
                  _authorRow(
                    Icons.business_rounded,
                    "الناشر: ${book.publisherName}",
                    onTap: () => _openCreatorDetails(
                      id: book.publisherId,
                      name: book.publisherName,
                      roleLabel: 'الناشر',
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _authorRow(IconData icon, String text, {VoidCallback? onTap}) {
    final row = Row(
      children: [
        Icon(icon, size: 16, color: _T.gold.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _T.mute, fontSize: 13),
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_left_rounded, color: _T.gold, size: 16),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }

  void _openCreatorDetails({
    required String id,
    required String name,
    required String roleLabel,
  }) {
    final cleanName = name.trim();
    final cleanId = id.trim();
    if (cleanId.isEmpty && cleanName.isEmpty) return;

    Navigator.pushNamed(
      context,
      AppRoutes.creatorDetails,
      arguments: CreatorDetailsArgs(
        creatorId: cleanId,
        displayName: cleanName,
        roleLabel: roleLabel,
      ),
    );
  }

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
  Widget _buildReviewsList() {
    if (_isReviewsLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator(color: _T.gold)),
        ),
      );
    }

    if (_reviewsError != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Text(
            'تعذر تحميل التعليقات',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _T.mute),
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            'لا توجد تعليقات بعد.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _T.mute),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _ReviewCard(
          review: _reviews[i],
          onLike: _toggleLike,
          onReply: (review) => _showAddReviewSheet(replyTo: review),
        ),
        childCount: _reviews.length,
      ),
    );
  }

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

  Widget _buildChaptersList(BookDetail book) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final chapter = book.chapters[index];
          return _buildChapterListItem(context, book, chapter, index);
        }, childCount: book.chapters.length),
      ),
    );
  }

  Widget _buildChapterListItem(
    BuildContext context,
    BookDetail book,
    Chapter chapter,
    int index,
  ) {
    final audioProvider = context.watch<AudioProvider>();
    final isActive = audioProvider.isActiveChapter(chapter.id);
    final isPlaying = isActive && audioProvider.isPlaying;

    Future<void> onTapPlay() async {
      HapticFeedback.lightImpact();
      if (isActive) {
        audioProvider.togglePlay();
      } else {
        await audioProvider.playChapterAudio(
          bookId: book.id,
          chapter: chapter,
          chapters: book.chapters,
          bookTitle: book.title,
          bookCoverUrl: book.imageUrl,
          author: book.author,
        );
      }
    }

    return GestureDetector(
      onTap: onTapPlay,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.surf,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? _T.gold.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Index/State icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? _T.gold
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isActive
                    ? Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 24,
                      )
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Chapter info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: GoogleFonts.amiri(
                      color: isActive ? _T.gold : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(chapter.duration),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Dual Actions
            Row(
              children: [
                // Listen button
                _buildChapterActionButton(
                  icon: isPlaying ? Icons.pause_rounded : Icons.headset_rounded,
                  label: 'استمع',
                  onTap: onTapPlay,
                  isPrimary: true,
                ),
                const SizedBox(width: 8),
                // Read button
                _buildChapterActionButton(
                  icon: Icons.menu_book_rounded,
                  label: 'اقرأ',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      AppRoutes.bookReader,
                      arguments: BookReaderScreenArgs(
                        pdfAssetPath: book.id,
                        bookTitle: book.title,
                        audioUrl: chapter.audioUrl,
                        chapterId: chapter.id,
                        transcript: chapter.transcript,
                        bookCoverUrl: book.imageUrl,
                      ),
                    );
                  },
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? _T.gold : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// REVIEW CARD WIDGET
// ════════════════════════════════════════════════════════════════════════════
class _ReviewCard extends StatelessWidget {
  final BookReview review;
  final ValueChanged<BookReview> onLike;
  final ValueChanged<BookReview> onReply;
  final bool isReply;

  const _ReviewCard({
    required this.review,
    required this.onLike,
    required this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.only(
          right: isReply ? 44 : 24,
          left: 24,
          top: isReply ? 4 : 8,
          bottom: isReply ? 4 : 8,
        ),
        padding: EdgeInsets.all(isReply ? 16 : 20),
        decoration: BoxDecoration(
          color: isReply
              ? Colors.white.withValues(alpha: 0.035)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(isReply ? 16 : 20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + time
            Row(
              children: [
                CircleAvatar(
                  radius: isReply ? 18 : 22,
                  backgroundImage: review.avatarUrl.isNotEmpty
                      ? NetworkImage(review.avatarUrl)
                      : null,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: review.avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        )
                      : null,
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
                          if (review.rating > 0) ...[
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
                          ],
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
                  onTap: () => onLike(review),
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
                if (!isReply) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => onReply(review),
                    icon: const Icon(Icons.reply_rounded, size: 16),
                    label: const Text('رد'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.onSurfaceVariant,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
            if (review.replies.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final reply in review.replies)
                _ReviewCard(
                  review: reply,
                  onLike: onLike,
                  onReply: onReply,
                  isReply: true,
                ),
            ],
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
  final String? replyTargetName;
  final ValueChanged<int> onStarTap;
  final VoidCallback onSubmit;

  const _AddReviewSheet({
    required this.commentCtrl,
    required this.focusNode,
    required this.pendingStars,
    this.replyTargetName,
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
                widget.replyTargetName == null
                    ? 'أضف تقييمك'
                    : 'رد على ${widget.replyTargetName}',
                style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Star selector
              if (widget.replyTargetName == null) ...[
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
              ],

              // Text field
              TextField(
                controller: widget.commentCtrl,
                focusNode: widget.focusNode,
                maxLines: 5,
                minLines: 3,
                style: GoogleFonts.amiri(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: widget.replyTargetName == null
                      ? 'اكتب تعليقك هنا...'
                      : 'اكتب ردك هنا...',
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
