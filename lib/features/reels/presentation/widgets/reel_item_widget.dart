import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/reel_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../viewmodels/reels_view_model.dart';
import 'reels_action_button.dart';
import 'waveform_widget.dart';
import '../../../../core/theme/app_theme.dart';

class ReelItemWidget extends StatefulWidget {
  final Reel reel;
  final bool isVisible;

  const ReelItemWidget({
    super.key,
    required this.reel,
    this.isVisible = false,
  });

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
    final reelRef = FirebaseFirestore.instance.collection('reels').doc(widget.reel.id);
    final likeRef = reelRef.collection('likes').doc(userId);
    
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _localLikesCount = (_localLikesCount - 1).clamp(0, double.infinity).toInt();
      } else {
        _isLiked = true;
        _localLikesCount++;
      }
    });
    
    try {
      if (_isLiked) {
        await likeRef.set({
          'createdAt': FieldValue.serverTimestamp(),
        });
        await reelRef.update({
          'likes': FieldValue.increment(1),
        });
      } else {
        await likeRef.delete();
        await reelRef.update({
          'likes': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Rollback on error
      setState(() {
        if (_isLiked) {
          _isLiked = false;
          _localLikesCount = (_localLikesCount - 1).clamp(0, double.infinity).toInt();
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

  @override
  Widget build(BuildContext context) {
    // Watch the ViewModel so this widget rebuilds when controllers change
    final vm = context.watch<ReelsViewModel>();
    final idx = vm.reels.indexWhere((r) => r.id == widget.reel.id);
    final controller = idx != -1 ? vm.controllerAt(idx) : null;
    final initialized = idx != -1 && vm.isInitializedAt(idx);

    return GestureDetector(
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
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.image, color: Colors.white24, size: 48),
                  );
                },
              ),
            ),
          ],

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Play Icon Overlay when paused (only show for visible reel)
          if (widget.isVisible && initialized && controller != null && !controller.value.isPlaying)
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

        // Content
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left Actions (for RTL feel, we place them on the left)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ReelsActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                    label: '$_localLikesCount',
                    onTap: _toggleLike,
                  ),
                  const SizedBox(height: 24),
                  ReelsActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${widget.reel.comments}',
                    onTap: _showCommentsBottomSheet,
                  ),
                  const SizedBox(height: 24),
                  ReelsActionButton(
                    icon: Icons.share,
                    label: 'ارسال',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  ReelsActionButton(
                    icon: Icons.bookmark,
                    label: 'حفظ',
                    onTap: () {},
                  ),
                  const SizedBox(height: 80), // Offset from bottom
                ],
              ),
              const Spacer(),
              // Right Info
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.graphic_eq, color: AppTheme.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'استمع الآن',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.reel.bookTitle,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontSize: 28,
                                    color: AppTheme.primary,
                                  ),
                            ),
                            Text(
                              widget.reel.author,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.only(right: 16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: AppTheme.primary, width: 2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    widget.reel.quote,
                                    textAlign: TextAlign.right,
                                    maxLines: _isExpanded ? null : 2,
                                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (widget.reel.quote.length > 80) ...[
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isExpanded = !_isExpanded;
                                        });
                                      },
                                      child: Text(
                                        _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const WaveformWidget(color: AppTheme.primary),
                    const SizedBox(height: 60), // Space for system nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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

      final reelRef = FirebaseFirestore.instance.collection('reels').doc(widget.reelId);

      await reelRef.collection('comments').add({
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'comment': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await reelRef.update({
        'comments': FieldValue.increment(1),
      });

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
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final commentData = docs[index].data() as Map<String, dynamic>;
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
                                  : FileImage(File(userImage)) as ImageProvider)
                              : null,
                          child: userImage.isEmpty
                              ? const Icon(Icons.person, color: Colors.white, size: 18)
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
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeAgo,
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                commentText,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
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
