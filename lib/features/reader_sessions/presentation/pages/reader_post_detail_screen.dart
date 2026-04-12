import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/reader_comment.dart';
import '../providers/reader_sessions_provider.dart';
import '../widgets/comment_item.dart';
import '../widgets/post_card.dart';

class ReaderPostDetailArgs {
  const ReaderPostDetailArgs({required this.postId});

  final String postId;
}

class ReaderPostDetailScreen extends StatefulWidget {
  const ReaderPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<ReaderPostDetailScreen> createState() => _ReaderPostDetailScreenState();
}

class _ReaderPostDetailScreenState extends State<ReaderPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  ReaderComment? _replyTarget;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final provider = context.read<ReaderSessionsProvider>();
    provider.addComment(
      postId: widget.postId,
      content: _commentController.text,
      parentCommentId: _replyTarget?.id,
    );
    _commentController.clear();
    setState(() {
      _replyTarget = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderSessionsProvider>();
    final post = provider.findPostById(widget.postId);

    if (post == null) {
      return const Scaffold(
        body: Center(child: Text('تعذر العثور على هذا المنشور')),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090806),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('تفاصيل المنشور'),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyTarget != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF17130E),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'رد على ${_replyTarget!.userName}',
                            style: const TextStyle(
                              color: Color(0xFFD9AF68),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _replyTarget = null;
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'أضف تعليقاً...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.36),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF14110D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(18)),
                            borderSide: BorderSide(color: Color(0xFFD9AF68)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _submitComment,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD9AF68),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(54, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            PostCard(
              post: post,
              timestampLabel: provider.formatTimestamp(post.createdAt),
              onTap: () {},
              onLikeTap: () => provider.toggleLike(post.id),
              onCommentTap: () {},
            ),
            const SizedBox(height: 22),
            Text(
              'التعليقات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (post.comments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF14110D),
                ),
                child: Text(
                  'ابدأ الحوار. لا توجد تعليقات بعد.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
                ),
              )
            else
              for (final comment in post.comments)
                CommentItem(
                  comment: comment,
                  timestampLabelBuilder: provider.formatTimestamp,
                  onReplyTap: (target) {
                    setState(() {
                      _replyTarget = target;
                    });
                  },
                ),
          ],
        ),
      ),
    );
  }
}
