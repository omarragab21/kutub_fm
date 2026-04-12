import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/rich_transcript_view.dart';

class TranscriptReaderScreen extends StatelessWidget {
  const TranscriptReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AudioProvider>();
    final transcript = viewModel.transcript;
    final isLoading = viewModel.isLoadingTranscript;
    final error = viewModel.transcriptError;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withValues(alpha: 0.8)),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'النص الكامل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        width: 48,
                      ), // Spacer to balance back button
                    ],
                  ),
                ),

                Expanded(
                  child: _buildContent(
                    context,
                    transcript,
                    isLoading,
                    error,
                    viewModel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic transcript,
    bool isLoading,
    String? error,
    AudioProvider viewModel,
  ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل النص',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (transcript == null || transcript.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد نص متاح لهذا الكتاب.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return RichTranscriptView(
      transcript: transcript,
      currentPosition: Duration(seconds: viewModel.currentPositionSeconds),
      onSegmentTap: (position) {
        viewModel.seekTo(position.inSeconds.toDouble());
      },
    );
  }
}
