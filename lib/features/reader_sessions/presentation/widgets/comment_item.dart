import 'package:flutter/material.dart';

import '../../domain/entities/reader_comment.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({
    super.key,
    required this.comment,
    required this.timestampLabelBuilder,
    required this.onReplyTap,
    this.depth = 0,
  });

  final ReaderComment comment;
  final String Function(DateTime) timestampLabelBuilder;
  final ValueChanged<ReaderComment> onReplyTap;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final leftInset = depth * 18.0;

    return Padding(
      padding: EdgeInsetsDirectional.only(start: leftInset, bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: depth == 0
              ? const Color(0xFF14110D)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(comment.userAvatarUrl),
                  backgroundColor: const Color(0xFF2A2118),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timestampLabelBuilder(comment.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onReplyTap(comment),
                  child: const Text('رد'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              comment.content,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.65,
              ),
            ),
            if (comment.replies.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final reply in comment.replies)
                CommentItem(
                  comment: reply,
                  timestampLabelBuilder: timestampLabelBuilder,
                  onReplyTap: onReplyTap,
                  depth: depth + 1,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
