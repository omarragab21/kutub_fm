import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ChapterListItem extends StatelessWidget {
  final String title;
  final String duration;
  final bool isCompleted;
  final bool isCurrent;
  final int index;

  const ChapterListItem({
    super.key,
    required this.title,
    required this.duration,
    required this.index,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent 
          ? AppTheme.primary.withOpacity(0.1) 
          : (index % 2 == 0 ? Colors.transparent : AppTheme.surfaceContainerHighest.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Play indicator or index
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCurrent ? AppTheme.primary : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCurrent 
                ? const Icon(Icons.play_arrow, color: Colors.black, size: 18)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCompleted ? AppTheme.primary : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          // Title and Duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCurrent ? AppTheme.primary : (isCompleted ? Colors.white70 : Colors.white),
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    decoration: isCompleted ? TextDecoration.none : TextDecoration.none,
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Checkmark for completed
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppTheme.primary, size: 16),
        ],
      ),
    );
  }
}

class CommentListItem extends StatelessWidget {
  final String name;
  final String avatar;
  final String text;
  final String time;
  final int likes;

  const CommentListItem({
    super.key,
    required this.name,
    required this.avatar,
    required this.text,
    required this.time,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
