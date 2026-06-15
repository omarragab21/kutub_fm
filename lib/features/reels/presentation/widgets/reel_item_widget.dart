import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/reel_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../viewmodels/reels_view_model.dart';
import 'waveform_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';
import '../../../book_details/domain/entities/book_detail_model.dart';

class ReelItemWidget extends StatefulWidget {
  final Reel reel;
  final bool isVisible;

  const ReelItemWidget({super.key, required this.reel, this.isVisible = false});

  @override
  State<ReelItemWidget> createState() => _ReelItemWidgetState();
}

class _ReelItemWidgetState extends State<ReelItemWidget> {
  bool _isLiked = false;
  late int _localLikesCount;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _localLikesCount = widget.reel.likes;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('reels')
          .doc(widget.reel.id)
          .collection('likes')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _isLiked = likeDoc.exists;
        });
      }
    } catch (e) {
      debugPrint('Error checking like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً للإعجاب.')),
      );
      return;
    }

    final userId = user.uid;
    final reelRef = FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reel.id);
    final likeRef = reelRef.collection('likes').doc(userId);

    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _localLikesCount = (_localLikesCount - 1)
            .clamp(0, double.infinity)
            .toInt();
      } else {
        _isLiked = true;
        _localLikesCount++;
      }
    });

    try {
      if (_isLiked) {
        await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
        await reelRef.update({'likes': FieldValue.increment(1)});
      } else {
        await likeRef.delete();
        await reelRef.update({'likes': FieldValue.increment(-1)});
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Rollback on error
      setState(() {
        if (_isLiked) {
          _isLiked = false;
          _localLikesCount = (_localLikesCount - 1)
              .clamp(0, double.infinity)
              .toInt();
        } else {
          _isLiked = true;
          _localLikesCount++;
        }
      });
    }
  }

  @override
  void didUpdateWidget(ReelItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync likes count if it changed externally (Firestore stream update)
    if (widget.reel.likes != oldWidget.reel.likes) {
      _localLikesCount = widget.reel.likes;
    }
    // Play/pause is handled centrally in ReelsViewModel.onPageChanged
  }

  @override
  void dispose() {
    // Controller lifecycle is managed by ReelsViewModel — do NOT dispose here
    super.dispose();
  }

  void _showCommentsBottomSheet() {
    final vm = context.read<ReelsViewModel>();
    final idx = vm.reels.indexWhere((r) => r.id == widget.reel.id);
    final ctrl = idx != -1 ? vm.controllerAt(idx) : null;
    ctrl?.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CommentsBottomSheet(reelId: widget.reel.id);
      },
    ).then((_) {
      if (widget.isVisible && mounted) {
        ctrl?.play();
      }
    });
  }

  void _onSaveTapped() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ الاقتباس في المحفوظات',
          textDirection: TextDirection.rtl,
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onShareTapped() {
    HapticFeedback.mediumImpact();
    final shareText =
        '🎥 استمعت للتو إلى هذا الاقتباس المميز من كتاب "${widget.reel.bookTitle}":\n\n'
        '${widget.reel.quote}\n\n'
        'بصوت: ${widget.reel.author}\n'
        'عبر تطبيق كتب FM 🎧';
    SharePlus.instance.share(
      ShareParams(text: shareText, subject: 'مشاركة اقتباس كتب FM'),
    );
  }

  Future<void> _onOpenBookTapped() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('جاري فتح الكتاب...'),
          ],
        ),
        duration: Duration(milliseconds: 800),
      ),
    );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('title', isEqualTo: widget.reel.bookTitle)
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final bookId = doc.id;
        final bookData = doc.data();

        final chaptersSnapshot = await doc.reference
            .collection('chapters')
            .orderBy('orderIndex')
            .get();

        final chapters = chaptersSnapshot.docs
            .map((c) => Chapter.fromFirestore(c.data(), c.id))
            .toList();

        final bookDetail = BookDetail.fromFirestore(bookData, bookId, chapters);

        if (!mounted) return;

        Navigator.pushNamed(
          context,
          AppRoutes.bookReader,
          arguments: BookReaderScreenArgs(
            pdfAssetPath: bookDetail.id,
            bookTitle: bookDetail.title,
            audioUrl: bookDetail.chapters.isNotEmpty
                ? bookDetail.chapters[0].audioUrl
                : '',
            chapterId: bookDetail.chapters.isNotEmpty
                ? bookDetail.chapters[0].id
                : '',
            transcript: bookDetail.chapters.isNotEmpty
                ? bookDetail.chapters[0].transcript
                : null,
            bookCoverUrl: bookDetail.imageUrl,
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          AppRoutes.bookReader,
          arguments: BookReaderScreenArgs(
            pdfAssetPath: 'miah_aam',
            bookTitle: widget.reel.bookTitle,
            audioUrl: '',
            chapterId: 'ch1',
            transcript: null,
            bookCoverUrl: widget.reel.imageUrl,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to book: $e');
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.bookReader,
        arguments: BookReaderScreenArgs(
          pdfAssetPath: 'miah_aam',
          bookTitle: widget.reel.bookTitle,
          audioUrl: '',
          chapterId: 'ch1',
          transcript: null,
          bookCoverUrl: widget.reel.imageUrl,
        ),
      );
    }
  }

  Widget _buildCircleAction({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        child: Center(child: Icon(icon, color: iconColor, size: 22)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ViewModel so this widget rebuilds when controllers change
    final vm = context.watch<ReelsViewModel>();
    final idx = vm.reels.indexWhere((r) => r.id == widget.reel.id);
    final controller = idx != -1 ? vm.controllerAt(idx) : null;
    final initialized = idx != -1 && vm.isInitializedAt(idx);

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isWide = screenWidth > 600;

    final double cardWidth = isWide ? 380 : screenWidth;
    final double cardHeight = isWide ? 750 : screenHeight;

    final double bottomInset = isWide ? 16 : (mediaQuery.padding.bottom + 60);

    return Container(
      color: Colors.black, // Feed background is black
      child: Center(
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: isWide
                ? BorderRadius.circular(32)
                : BorderRadius.zero,
            border: isWide
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  )
                : null,
            boxShadow: isWide
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: isWide
                ? BorderRadius.circular(32)
                : BorderRadius.zero,
            clipBehavior: Clip.antiAlias,
            child: GestureDetector(
              onDoubleTap: () {
                if (initialized && controller != null) {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                  setState(() {}); // Rebuild to show/hide play icon
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video / Image Background
                  if (initialized && controller != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  else ...[
                    Container(
                      color: const Color(0xFF151515),
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.network(
                        widget.reel.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.white24,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Gradient Overlay (very light, translucent)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // Play Icon Overlay when paused (only show for visible reel)
                  if (widget.isVisible &&
                      initialized &&
                      controller != null &&
                      !controller.value.isPlaying)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),

                  // Content Overlay
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Stack(
                      children: [
                        // 1. Waveform in the center
                        Center(
                          child: WaveformWidget(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),

                        // 2. Quick Actions vertically stacked on the bottom left (with count labels)
                        Positioned(
                          bottom: bottomInset,
                          left: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCircleAction(
                                icon: _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.white.withValues(alpha: 0.2),
                                iconColor: _isLiked ? Colors.red : Colors.white,
                                onTap: _toggleLike,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _localLikesCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildCircleAction(
                                icon: Icons.chat_bubble_outline,
                                color: Colors.white.withValues(alpha: 0.2),
                                iconColor: Colors.white,
                                onTap: _showCommentsBottomSheet,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.reel.comments.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildCircleAction(
                                icon: Icons.bookmark_border,
                                color: Colors.white.withValues(alpha: 0.2),
                                iconColor: Colors.white,
                                onTap: _onSaveTapped,
                              ),
                              const SizedBox(height: 12),
                              _buildCircleAction(
                                icon: Icons.share,
                                color: Colors.white.withValues(alpha: 0.2),
                                iconColor: Colors.white,
                                onTap: _onShareTapped,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.reel.shares.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. Book reference & quote on the bottom right (with dynamic expand support)
                        Positioned(
                          bottom: bottomInset,
                          right: 16,
                          left: 80, // Leave room for left actions
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.reel.bookTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.reel.author,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                                child: Text(
                                  widget.reel.quote,
                                  maxLines: _isExpanded ? 100 : 2,
                                  overflow: _isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _onOpenBookTapped,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'فتح الكتاب',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final String reelId;

  const _CommentsBottomSheet({required this.reelId});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final appUser = authProvider.appUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً للتعليق.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final userId = user.uid;
      final userName = appUser?.name ?? user.displayName ?? 'مستخدم كتب FM';
      final userImage = appUser?.photoUrl ?? user.photoURL ?? '';

      final reelRef = FirebaseFirestore.instance
          .collection('reels')
          .doc(widget.reelId);

      await reelRef.collection('comments').add({
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'comment': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await reelRef.update({'comments': FieldValue.increment(1)});

      _commentController.clear();
    } catch (e) {
      debugPrint('Error sending comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء إرسال التعليق.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF131313),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'التعليقات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reels')
                  .doc(widget.reelId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد تعليقات بعد. كن أول من يعلق!',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  );
                }
                final docs = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final commentData =
                        docs[index].data() as Map<String, dynamic>;
                    final userName = commentData['userName'] ?? 'مستخدم كتب FM';
                    final commentText = commentData['comment'] ?? '';
                    final userImage = commentData['userImage'] ?? '';
                    final createdAt = commentData['createdAt'] as Timestamp?;
                    final timeAgo = _formatTimestamp(createdAt);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white10,
                          backgroundImage: userImage.isNotEmpty
                              ? (userImage.startsWith('http')
                                    ? NetworkImage(userImage)
                                    : FileImage(File(userImage))
                                          as ImageProvider)
                              : null,
                          child: userImage.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeAgo,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                commentText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      enabled: !_isSending,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'أضف تعليقاً...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          )
                        : const Icon(Icons.send, color: AppTheme.primary),
                    onPressed: _isSending ? null : _sendComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
