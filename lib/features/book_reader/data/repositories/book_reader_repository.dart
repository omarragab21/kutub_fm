import '../../domain/entities/reader_sentence.dart';
import '../services/pdf_extraction_service.dart';

class BookReaderRepository {
  final PdfExtractionService _pdfService;

  BookReaderRepository({PdfExtractionService? pdfService})
      : _pdfService = pdfService ?? PdfExtractionService();

  Future<List<ReaderSentence>> loadBookFromAsset(String assetPath) async {
    final rawText = await _pdfService.extractTextFromAsset(assetPath);
    return _pdfService.parseIntoSentences(rawText);
  }
}
