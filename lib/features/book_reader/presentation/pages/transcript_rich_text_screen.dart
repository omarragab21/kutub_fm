import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transcript_segment.dart';
import '../../data/services/transcript_loader.dart';
import '../utils/transcript_text_helper.dart';

class TranscriptRichTextScreen extends StatefulWidget {
  const TranscriptRichTextScreen({super.key});

  @override
  State<TranscriptRichTextScreen> createState() => _TranscriptRichTextScreenState();
}

class _TranscriptRichTextScreenState extends State<TranscriptRichTextScreen> {
  final TranscriptLoader _loader = TranscriptLoader();
  late Future<TranscriptDocument> _transcriptFuture;

  @override
  void initState() {
    super.initState();
    _transcriptFuture = _loader.loadTranscript();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('قارئ النصوص'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<TranscriptDocument>(
        future: _transcriptFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final transcript = snapshot.data!;
          return _buildTranscriptView(transcript);
        },
      ),
    );
  }

  Widget _buildTranscriptView(TranscriptDocument transcript) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Illustration / Spacer
          const SizedBox(height: 20),
          
          // The RichText content
          RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: TranscriptTextHelper.buildTextSpans(
                transcript.segments,
                fontSize: 20,
              ),
            ),
          ),
          
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 20),
          Text(
            'جاري تحميل النص...',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _transcriptFuture = _loader.loadTranscript();
                });
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'لا يوجد محتوى متاح حالياً.',
        style: TextStyle(color: Colors.white38),
      ),
    );
  }
}
