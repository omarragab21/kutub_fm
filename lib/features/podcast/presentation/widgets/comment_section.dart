import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/podcast_comment.dart';
import '../providers/podcast_provider.dart';

class CommentSection extends StatefulWidget {
  final String episodeId;
  final List<PodcastComment> comments;

  const CommentSection({
    super.key,
    required this.episodeId,
    required this.comments,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    context.read<PodcastProvider>().addComment(widget.episodeId, text);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مناقشات الأفكار (${widget.comments.length})',
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 24),
        // Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'شارك أفكارك حول هذه الحلقة...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                onPressed: _submitComment,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Comments List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.comments.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Colors.white10),
          ),
          itemBuilder: (context, index) {
            return _buildCommentItem(widget.comments[index], theme);
          },
        ),
      ],
    );
  }

  Widget _buildCommentItem(PodcastComment comment, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(comment.userAvatarUrl),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTime(comment.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 12),
              // Replies
              if (comment.replies.isNotEmpty)
                Column(
                  children: comment.replies
                      .map((reply) => Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: _buildCommentItem(reply, theme),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}
