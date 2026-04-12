import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/reader_sentence.dart';
import '../../data/models/transcript_segment.dart';
import '../../data/services/transcript_loader.dart';

class BookReaderViewModel extends ChangeNotifier {
  final TranscriptLoader _loader = TranscriptLoader();

  bool _isLoading = true;
  String? _errorMessage;
  
  List<ReaderSentence> _sentences = [];
  int? _activeSentenceId;
  double _readPercentage = 0.0;
  bool _isControlsVisible = true;

  BookReaderViewModel();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ReaderSentence> get sentences => _sentences;
  int? get activeSentenceId => _activeSentenceId;
  double get readPercentage => _readPercentage;
  bool get isControlsVisible => _isControlsVisible;

  Future<void> loadPdfBook(String assetPath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _loader.loadTranscript();
      
      _sentences = doc.segments.asMap().entries.map((entry) {
        final index = entry.key;
        final segment = entry.value;
        return ReaderSentence(
          globalIndex: index,
          text: segment.text,
          isArabic: _isArabic(segment.text),
        );
      }).toList();

      if (_sentences.isEmpty) {
        _errorMessage = "تعذّر قراءة هذا الملف. السجل فارغ.";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  void toggleControls() {
    // If we have an active sentence highlighted, tapping should clear it FIRST.
    if (_activeSentenceId != null) {
      _activeSentenceId = null;
    } else {
      _isControlsVisible = !_isControlsVisible;
    }
    notifyListeners();
  }

  void selectSentence(int index) {
    if (index >= 0 && index < _sentences.length) {
      HapticFeedback.selectionClick();
      _activeSentenceId = index;
      notifyListeners();
    }
  }

  void updateScrollProgress(double maxExtent, double currentOffset) {
    if (maxExtent > 0) {
      double percentage = currentOffset / maxExtent;
      if (percentage < 0) percentage = 0;
      if (percentage > 1) percentage = 1;
      
      if (_readPercentage != percentage) {
        _readPercentage = percentage;
        notifyListeners();
      }
    }
  }

  void copySelectedSentence() {
    if (_activeSentenceId != null && _activeSentenceId! < _sentences.length) {
      final textToCopy = _sentences[_activeSentenceId!].text;
      Clipboard.setData(ClipboardData(text: textToCopy));
      _activeSentenceId = null;
      notifyListeners();
    }
  }

  Future<void> shareSelectedSentence() async {
    if (_activeSentenceId != null && _activeSentenceId! < _sentences.length) {
      final textToShare = _sentences[_activeSentenceId!].text;
      await Share.share('"$textToShare"');
      _activeSentenceId = null;
      notifyListeners();
    }
  }
}
