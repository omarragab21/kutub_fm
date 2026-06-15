import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';
import '../../domain/entities/book_detail_model.dart';

import '../viewmodels/book_details_view_model.dart';
import '../../data/repositories/book_details_repository_impl.dart';

// ════════════════════════════════════════════════════════════════════════════
// THEME & CONSTANTS
// ════════════════════════════════════════════════════════════════════════════
class _T {
  static const Color bg = AppTheme.background;
  static const Color surf = Color(0xFF1C1C1E);
  static const Color gold = AppTheme.primary;
  static const Color text = AppTheme.onSurface;
  static const Color mute = AppTheme.onSurfaceVariant;
}

// ════════════════════════════════════════════════════════════════════════════
// REVIEWS DATA MODEL
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
// MAIN SCREEN
// ════════════════════════════════════════════════════════════════════════════
class BookDetailsPage extends StatefulWidget {
  final String? bookId;
  const BookDetailsPage({super.key, this.bookId});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  // ── Tab State ────────────────────────────────────────────────────────────
  int _selectedTab = 0; // 0 = عن الكتاب, 1 = الفصول, 2 = مراجعة الكتاب

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

  String get _targetBookId => widget.bookId ?? 'miah_aam';

  CollectionReference<Map<String, dynamic>> get _commentsCollection =>
      FirebaseFirestore.instance
          .collection('books')
          .doc(_targetBookId)
          .collection('comments');

  // ── Average rating ───────────────────────────────────────────────────────
  double get _avgRating {
    if (_reviews.isEmpty) return 4.8; // default mock rating from wireframe
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
                _reviews = _getFallbackReviews();
                _isReviewsLoading = false;
                _reviewsError = null;
              });
            }
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _reviews = _getFallbackReviews();
              _isReviewsLoading = false;
              _reviewsError = null;
            });
          },
        );
  }

  List<BookReview> _getFallbackReviews() {
    return [
      BookReview(
        id: '101',
        userId: 'u1',
        authorName: 'سامر العلي',
        avatarUrl: '',
        text:
            'رواية استثنائية، أعادت تشكيل نظرتي للوزارة والوجود أسلوب ساحر ومترجم بشكل رائع، أنصح بها بشدة.',
        rating: 5,
        timeAgo: '24/5/2026',
        likes: 24,
      ),
      BookReview(
        id: '102',
        userId: 'u2',
        authorName: 'ليلى حسن',
        avatarUrl: '',
        text:
            'قصة عميقة تحمل بين طياتها مشاعر صادقة وأحداث مشوقة، لا يمكنني الانتظار لقراءة المزيد من...',
        rating: 4,
        timeAgo: '15/6/2026',
        likes: 12,
      ),
    ];
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Stack(
                  children: [
                    // 1. Header Background Curved Pattern
                    _buildHeaderBackground(book),

                    // 2. Main Content Card
                    Column(
                      children: [
                        const SizedBox(height: 200),
                        _buildContentCard(context, viewModel, book),
                      ],
                    ),

                    // 3. Overlapping Book Cover
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildOverlappingCover(book)),
                    ),

                    // 4. Back / Action Buttons at the Top
                    Positioned(
                      top: 48,
                      left: 20,
                      right: 20,
                      child: _buildTopBarActions(viewModel),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── HEADER BACKGROUND ────────────────────────────────────────────────────
  Widget _buildHeaderBackground(BookDetail book) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2519), Color(0xFF131313)],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: Stack(
          children: [
            // Abstract geometric layout/pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
              ),
            ),
            // Light dust texture/gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      _T.gold.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── OVERLAPPING COVER ────────────────────────────────────────────────────
  Widget _buildOverlappingCover(BookDetail book) {
    final isAsset = book.imageUrl.startsWith('assets/');
    return Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: _T.gold.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isAsset
            ? Image.asset(book.imageUrl, fit: BoxFit.cover)
            : Image.network(
                book.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, obj, err) => Container(
                  color: _T.surf,
                  child: const Icon(
                    Icons.book_rounded,
                    color: _T.gold,
                    size: 50,
                  ),
                ),
              ),
      ),
    );
  }

  // ── TOP BAR ACTIONS ──────────────────────────────────────────────────────
  Widget _buildTopBarActions(BookDetailsViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        _buildCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        // Share & Heart Buttons
        Row(
          children: [
            _buildCircleButton(
              icon: Icons.share_outlined,
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('مشاركة رابط الكتاب')),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildCircleButton(
              icon: viewModel.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: viewModel.isFavorite ? _T.gold : Colors.white,
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.isAnonymous) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سجل الدخول لإضافة الكتاب إلى المفضلة'),
                    ),
                  );
                  return;
                }
                HapticFeedback.mediumImpact();
                viewModel.toggleFavorite();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
      ),
    );
  }

  // ── CONTENT CARD ─────────────────────────────────────────────────────────
  Widget _buildContentCard(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookDetail book,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _T.surf,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.only(top: 90, left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          // Genre pill
          if (book.category.isNotEmpty) ...[
            _goldBadge(book.category),
            const SizedBox(height: 16),
          ],

          // Title
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Author
          Text(
            book.author,
            style: TextStyle(
              color: _T.mute,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Rating Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              ..._starRow(_avgRating),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons Row
          _buildActionButtons(context, viewModel, book),
          const SizedBox(height: 32),

          // Tab Bar
          _buildTabBar(),
          const SizedBox(height: 24),

          // Tab View Content
          _buildTabContent(book),
        ],
      ),
    );
  }

  // ── ACTION BUTTONS ───────────────────────────────────────────────────────
  Widget _buildActionButtons(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookDetail book,
  ) {
    final audioProvider = context.watch<AudioProvider>();
    final isBookPlaying =
        book.chapters.any((c) => audioProvider.isActiveChapter(c.id)) &&
        audioProvider.isPlaying;

    Future<void> onTapListen() async {
      HapticFeedback.mediumImpact();
      if (book.chapters.isEmpty) return;

      final currentPlayingChapter = book.chapters.firstWhere(
        (c) => audioProvider.isActiveChapter(c.id),
        orElse: () => book.chapters.first,
      );

      if (!audioProvider.isActiveChapter(currentPlayingChapter.id)) {
        await audioProvider.playChapterAudio(
          bookId: book.id,
          chapter: currentPlayingChapter,
          chapters: book.chapters,
          bookTitle: book.title,
          bookCoverUrl: book.imageUrl,
          author: book.author,
        );
      }
      if (context.mounted) {
        Navigator.pushNamed(context, AppRoutes.audioPlayer);
      }
    }

    return Row(
      children: [
        // Download Button (outlined, circular icon button)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إضافة الكتاب إلى قائمة التنزيل'),
              ),
            );
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              color: Colors.white.withValues(alpha: 0.02),
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Read Now Button (outlined)
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                AppRoutes.bookReader,
                arguments: BookReaderScreenArgs(
                  pdfAssetPath: book.id,
                  bookTitle: book.title,
                  audioUrl: book.chapters.isNotEmpty
                      ? book.chapters[0].audioUrl
                      : '',
                  chapterId: book.chapters.isNotEmpty
                      ? book.chapters[0].id
                      : '',
                  transcript: book.chapters.isNotEmpty
                      ? book.chapters[0].transcript
                      : null,
                  bookCoverUrl: book.imageUrl,
                ),
              );
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                color: Colors.white.withValues(alpha: 0.02),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اقرأ الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Listen Now Button (filled solid)
        Expanded(
          child: GestureDetector(
            onTap: onTapListen,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _T.gold,
                boxShadow: [
                  BoxShadow(
                    color: _T.gold.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBookPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBookPlaying ? 'إيقاف مؤقت' : 'استمع الآن',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── TAB BAR ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(0, 'عن الكتاب'),
          _buildTabItem(1, 'الفصول'),
          _buildTabItem(2, 'مراجعة الكتاب'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTab = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? _T.gold : Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isActive)
            Container(
              height: 2.5,
              width: 60,
              decoration: const BoxDecoration(
                color: _T.gold,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }

  // ── TAB CONTENT RESOLVER ─────────────────────────────────────────────────
  Widget _buildTabContent(BookDetail book) {
    switch (_selectedTab) {
      case 0:
        return _buildAboutTab(book);
      case 1:
        return _buildChaptersTab(book);
      case 2:
        return _buildReviewsTab(book);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── ABOUT TAB ────────────────────────────────────────────────────────────
  Widget _buildAboutTab(BookDetail book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          book.description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 16,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 32),

        // About Author
        Text(
          'عن الكاتب',
          style: TextStyle(
            color: _T.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _T.gold.withValues(alpha: 0.1),
                  border: Border.all(color: _T.gold.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _T.gold,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.author,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أحمد خالد توفيق فراج، كاتب وأديب مصري اشتهر بالرواية في الكتابة.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Book Details Table
        Text(
          'تفاصيل الكتاب',
          style: TextStyle(
            color: _T.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              _buildDetailRow('عدد الصفحات', '${book.pages} صفحة'),
              _buildDetailDivider(),
              _buildDetailRow('المؤلف', book.author),
              _buildDetailDivider(),
              _buildDetailRow(
                'تاريخ النشر',
                book.publisherId.contains('shorouk') ? '2018' : '2018',
              ),
              _buildDetailDivider(),
              _buildDetailRow('نوع الكتاب', 'رواية خيال علمي'),
              _buildDetailDivider(),
              _buildDetailRow(
                'الناشر',
                book.publisherName.isNotEmpty
                    ? book.publisherName
                    : 'الدار العربية للعلوم ناشرون',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.04),
    );
  }

  // ── CHAPTERS TAB ─────────────────────────────────────────────────────────
  Widget _buildChaptersTab(BookDetail book) {
    if (book.chapters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'لا توجد فصول متوفرة لهذا الكتاب حالياً.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: book.chapters.length,
      itemBuilder: (context, index) {
        final chapter = book.chapters[index];
        return _buildChapterRowItem(context, book, chapter, index);
      },
    );
  }

  Widget _buildChapterRowItem(
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
      if (!isActive) {
        await audioProvider.playChapterAudio(
          bookId: book.id,
          chapter: chapter,
          chapters: book.chapters,
          bookTitle: book.title,
          bookCoverUrl: book.imageUrl,
          author: book.author,
        );
      }
      if (context.mounted) {
        Navigator.pushNamed(context, AppRoutes.audioPlayer);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? _T.gold.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Circle Index Indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? _T.gold : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Chapter details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title,
                  style: TextStyle(
                    color: isActive ? _T.gold : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(chapter.duration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Double Actions: Play (Listen) and Read
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: onTapPlay,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? _T.gold
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPlaying
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPlaying ? Icons.pause_rounded : Icons.headset_rounded,
                        size: 14,
                        color: isPlaying ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPlaying ? 'مؤقت' : 'استمع',
                        style: TextStyle(
                          color: isPlaying ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Read button
              GestureDetector(
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'اقرأ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
    );
  }

  // ── REVIEWS TAB ──────────────────────────────────────────────────────────
  Widget _buildReviewsTab(BookDetail book) {
    return Column(
      children: [
        // Add review block
        GestureDetector(
          onTap: _showAddReviewSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: _T.gold.withValues(alpha: 0.7),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'أضف مراجعتك للعمل...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Reviews List
        if (_isReviewsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: _T.gold)),
          )
        else if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'لا توجد تعليقات بعد.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _ReviewCard(
                review: review,
                onLike: _toggleLike,
                onReply: (r) => _showAddReviewSheet(replyTo: r),
              );
            },
          ),
      ],
    );
  }

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

  Widget _goldBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: _T.gold.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _T.gold.withValues(alpha: 0.25)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: _T.gold,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
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
        margin: EdgeInsets.only(bottom: 12, right: isReply ? 36 : 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + date + stars
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: review.avatarUrl.isNotEmpty
                      ? NetworkImage(review.avatarUrl)
                      : null,
                  backgroundColor: _T.gold.withValues(alpha: 0.1),
                  child: review.avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: _T.gold,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            review.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            review.timeAgo,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: _T.gold,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review text
            Text(
              review.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),

            // Actions: Like + Reply
            Row(
              children: [
                GestureDetector(
                  onTap: () => onLike(review),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: review.isLikedByMe
                          ? _T.gold.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: review.isLikedByMe
                            ? _T.gold.withValues(alpha: 0.3)
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
                              ? _T.gold
                              : Colors.white.withValues(alpha: 0.6),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${review.likes}',
                          style: TextStyle(
                            color: review.isLikedByMe
                                ? _T.gold
                                : Colors.white.withValues(alpha: 0.6),
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
                    icon: const Icon(Icons.reply_rounded, size: 14),
                    label: const Text('رد', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.5),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                widget.replyTargetName == null
                    ? 'أضف تقييمك'
                    : 'رد على ${widget.replyTargetName}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Star Selector
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
                            color: _T.gold,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Text Field
              TextField(
                controller: widget.commentCtrl,
                focusNode: widget.focusNode,
                maxLines: 4,
                minLines: 2,
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: widget.replyTargetName == null
                      ? 'اكتب تعليقك هنا...'
                      : 'اكتب ردك هنا...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'إرسال التقييم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
