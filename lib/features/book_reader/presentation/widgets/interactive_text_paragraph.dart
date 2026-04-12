import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/reader_sentence.dart';

class InteractiveTextParagraph extends StatelessWidget {
  final List<ReaderSentence> paragraphSentences;
  final int? activeSentenceId;
  final ValueChanged<int> onSentenceTap;
  final VoidCallback onClearSelection;

  const InteractiveTextParagraph({
    super.key,
    required this.paragraphSentences,
    required this.activeSentenceId,
    required this.onSentenceTap,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    if (paragraphSentences.isEmpty) return const SizedBox.shrink();

    // Decide paragraph direction based on the first sentence
    final isRTL = paragraphSentences.first.isRTL;
    
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Tapping the clear space around the text clears selection
        onTap: () {
          if (activeSentenceId != null) {
            onClearSelection();
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: RichText(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            textAlign: isRTL ? TextAlign.right : TextAlign.left,
            text: TextSpan(
              children: paragraphSentences.map((sentence) {
                final isSelected = activeSentenceId == sentence.globalIndex;
                
                return TextSpan(
                  text: '${sentence.text} ',
                  style: GoogleFonts.amiri(
                    color: isSelected ? Colors.white : AppTheme.primary.withOpacity(0.9),
                    fontSize: 22,
                    height: 1.8, // Comfortable reading height
                    backgroundColor: isSelected 
                        ? AppTheme.primary.withOpacity(0.4) 
                        : Colors.transparent,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      onSentenceTap(sentence.globalIndex);
                    },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
