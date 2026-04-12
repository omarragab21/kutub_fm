import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../audio_player/domain/entities/audio_story.dart';

class AudioListItem extends StatelessWidget {
  final AudioStory book;
  final VoidCallback onTap;

  const AudioListItem({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Thumbnail Cover
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  book.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF201A12),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.title, // subtitle
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(book.totalDurationSeconds),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.more_horiz, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours hrs $minutes mins';
    }
    return '$minutes mins';
  }
}
