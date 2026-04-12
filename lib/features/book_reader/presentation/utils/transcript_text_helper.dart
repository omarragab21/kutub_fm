import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transcript_segment.dart';

class TranscriptTextHelper {
  static List<TextSpan> buildTextSpans(
    List<TranscriptSegment> segments, {
    double fontSize = 18,
    int? activeId,
  }) {
    return segments.map((segment) {
      final isArabic = _isArabic(segment.text);
      final bool isActive = activeId == segment.id;
      
      TextStyle style = _getStyleForType(segment.type).copyWith(
        fontSize: fontSize,
        height: 1.6,
      );

      // Apply Font Based on Language
      if (isArabic) {
        style = GoogleFonts.amiri(textStyle: style);
      } else {
        style = GoogleFonts.manrope(textStyle: style);
      }

      // Apply Active Highlighting or Base Color
      if (isActive) {
        style = style.copyWith(
          color: AppTheme.primary,
          backgroundColor: AppTheme.primary.withOpacity(0.2), // Mock visual sync
        );
      } else {
        style = style.copyWith(
          color: isActive ? AppTheme.primary : AppTheme.onSurface,
        );
      }

      return TextSpan(
        text: segment.text + ' ',
        style: style,
      );
    }).toList();
  }

  static TextStyle _getStyleForType(TranscriptSegmentType type) {
    switch (type) {
      case TranscriptSegmentType.bold:
        return const TextStyle(fontWeight: FontWeight.bold);
      case TranscriptSegmentType.highlight:
        return const TextStyle(
          backgroundColor: AppTheme.primaryContainer,
          color: Colors.black,
        );
      case TranscriptSegmentType.normal:
      default:
        return const TextStyle(fontWeight: FontWeight.normal);
    }
  }

  static bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  static TextDirection getTextDirection(String text) {
    return _isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }
}
