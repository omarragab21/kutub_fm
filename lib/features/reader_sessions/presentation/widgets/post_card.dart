import 'package:flutter/material.dart';

import '../../domain/entities/reader_post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.timestampLabel,
    required this.onTap,
    required this.onLikeTap,
    required this.onCommentTap,
  });

  final ReaderPost post;
  final String timestampLabel;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context) {
    final typeStyle = _typeStyle(post.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF14110D),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(post.userAvatarUrl),
                    backgroundColor: const Color(0xFF2A2118),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timestampLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: typeStyle.backgroundColor,
                    ),
                    child: Text(
                      post.type.label,
                      style: TextStyle(
                        color: typeStyle.foregroundColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (post.bookTitle != null &&
                  post.bookTitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF1D1812),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFFD9AF68),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.bookTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD9AF68),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _ActionChip(
                    icon: post.isLikedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${post.likeCount}',
                    active: post.isLikedByMe,
                    onTap: onLikeTap,
                  ),
                  const SizedBox(width: 10),
                  _ActionChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.totalCommentCount}',
                    active: false,
                    onTap: onCommentTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PostTypeStyle _typeStyle(ReaderPostType type) {
    switch (type) {
      case ReaderPostType.quote:
        return const _PostTypeStyle(
          backgroundColor: Color(0xFF2A2117),
          foregroundColor: Color(0xFFD9AF68),
        );
      case ReaderPostType.discussion:
        return const _PostTypeStyle(
          backgroundColor: Color(0xFF1A2528),
          foregroundColor: Color(0xFF8BD2E2),
        );
      case ReaderPostType.review:
        return const _PostTypeStyle(
          backgroundColor: Color(0xFF1E2319),
          foregroundColor: Color(0xFF98D588),
        );
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFF06A6A) : const Color(0xFFD9AF68);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostTypeStyle {
  const _PostTypeStyle({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
}
