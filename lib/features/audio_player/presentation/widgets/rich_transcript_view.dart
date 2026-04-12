import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transcript_segment.dart';

class RichTranscriptView extends StatelessWidget {
  final TranscriptDocument transcript;
  final Duration currentPosition;
  final Function(Duration)? onSegmentTap;

  const RichTranscriptView({
    super.key,
    required this.transcript,
    required this.currentPosition,
    this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: transcript.segments.map((segment) {
                final isActive = segment.contains(currentPosition);
                return _buildSegmentSpan(segment, isActive);
              }).toList(),
            ),
          ),
          const SizedBox(height: 100), // Padding at bottom for controls
        ],
      ),
    );
  }

  InlineSpan _buildSegmentSpan(TranscriptSegment segment, bool isActive) {
    final bool isArabic = _isArabic(segment.text);
    
    // Base style configuration
    TextStyle style = _getStyleForType(segment.type).copyWith(
      color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant.withOpacity(0.6),
      backgroundColor: isActive ? AppTheme.primary.withOpacity(0.15) : null,
      height: 1.6,
    );

    // Apply specific fonts
    if (isArabic) {
      style = GoogleFonts.amiri(
        textStyle: style,
        fontSize: segment.type == TranscriptSegmentType.heading ? 28 : 22,
        fontWeight: segment.type == TranscriptSegmentType.heading ? FontWeight.bold : FontWeight.normal,
      );
    } else {
      style = GoogleFonts.manrope(
        textStyle: style,
        fontSize: segment.type == TranscriptSegmentType.heading ? 24 : 18,
        fontWeight: segment.type == TranscriptSegmentType.heading ? FontWeight.bold : FontWeight.normal,
      );
    }

    return WidgetSpan(
      child: GestureDetector(
        onTap: () => onSegmentTap?.call(segment.start),
        child: Text.rich(
          TextSpan(
            text: segment.text + ' ',
            style: style,
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  TextStyle _getStyleForType(TranscriptSegmentType type) {
    switch (type) {
      case TranscriptSegmentType.heading:
        return const TextStyle(fontWeight: FontWeight.bold);
      case TranscriptSegmentType.quote:
        return const TextStyle(fontStyle: FontStyle.italic);
      case TranscriptSegmentType.emphasis:
        return const TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline);
      case TranscriptSegmentType.note:
        return const TextStyle(fontSize: 14, color: Colors.white38);
      default:
        return const TextStyle();
    }
  }

  bool _isArabic(String text) {
    // Basic Arabic range check
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}
