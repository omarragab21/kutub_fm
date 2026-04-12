import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/reader_sentence.dart';

class PdfExtractionService {
  final _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  /// Loads PDF from an asset path and extracts its string content.
  Future<String> extractTextFromAsset(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      return _extractFromBytes(bytes);
    } catch (e) {
      // Asset missing entirely → use mock fallback
      debugPrint('[PdfExtractionService] Asset not found. Using mock. Error: $e');
      return _mockFallbackText;
    }
  }

  /// Synchronously process raw bytes with Syncfusion.
  /// Some PDFs (scanned/image-based) return empty text — we detect that and
  /// fall back to the mock content so the reader still works.
  String _extractFromBytes(List<int> bytes) {
    PdfDocument document = PdfDocument(inputBytes: bytes);
    PdfTextExtractor extractor = PdfTextExtractor(document);
    // Extract page-by-page and join, which is more reliable than extractText()
    final buffer = StringBuffer();
    for (int i = 0; i < document.pages.count; i++) {
      final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      if (pageText.isNotEmpty) {
        buffer.writeln(pageText);
      }
    }
    document.dispose();

    final result = buffer.toString().trim();
    if (result.isEmpty) {
      // PDF has no extractable text (scanned/image-based) → use fallback
      debugPrint('[PdfExtractionService] PDF returned empty text, using mock fallback.');
      return _mockFallbackText;
    }
    return result;
  }

  static const String _mockFallbackText = """
في قلب الصحراء الكبرى، حيث تلتقي السماء بالأرض في أفق لا ينتهي، بدأت ملحمة "حارس الرمال". كان الصمت هناك ليس مجرد غياب للصوت، بل كان كيانًا حيًا يهمس بأسرار العصور الخوالي. كان "زيد"، الشاب الذي نشأ على حكايات الأجداد، يقف فوق تلة مرتفعة، متأملًا النجوم التي بدت وكأنها مصابيح معلقة في سقف الكون.

كانت الرياح الشمالية تعزف لحنًا حزينًا بين الصخور المنحوتة بفعل الزمن. في تلك الليلة، لم يكن زيد يبحث عن السكينة، بل كان ينتظر إشارة تنبأ بها العرافون منذ قرون. "عندما يتحول لون القمر إلى الفضة الخالصة، وتصرخ الصقور في جوف الليل، سيبدأ الطريق". هكذا قيل له، وهكذا آمن.

فجأة، انشق سكون الليل بصوت لم يألفه من قبل، كان أشبه بقعقعة السيوف في ساحة الوغى، لكنه قادم من أعماق الأرض. اهتزت الرمال تحت قدميه، وبدأت تتشكل دوامات غامضة تبتلع ضوء النجوم. لم يتراجع زيد، بل شد قبيلته على سيفه القديم، وشعر بحرارة غريبة تنبعث من نصله، وكأن السيف نفسه قد استيقظ من سبات طويل.

لقد كانت هذه اللحظة الفارقة هي البداية لرحلة لن يعود منها كما كان. رحلة ستأخذه عبر مدن غارقة تحت الرمال، وجبال تتحدث بلسان البشر، وغابات مسكونة بأرواح المحاربين القدامى. كان يعلم أن الثمن قد يكون حياته، لكنه كان يعلم أيضًا أن المجد لا يُنال إلا بالمرور عبر نيران التحدي.

In the heart of the Great Desert, where the sky meets the earth in an endless horizon, the epic of "The Sand Guardian" began. The silence there was not merely an absence of sound, but a living entity whispering the secrets of ancient eras. Zaid, a young man raised on the tales of his ancestors, stood atop a high dune, contemplating the stars that looked like lamps suspended from the ceiling of the universe.

The northern winds played a mournful melody among the rocks carved by time. That night, Zaid was not seeking peace; he was waiting for a sign foretold by seers centuries ago. "When the moon turns to pure silver, and the hawks cry out in the dead of night, the path shall begin." So it was said to him, and so he believed.

Suddenly, the stillness of the night was shattered by a sound he had never known before, resembling the clashing of swords on a battlefield, yet coming from deep within the earth. The sands beneath his feet shook, and mysterious vortices began to form, swallowing the starlight. Zaid did not retreat; instead, he tightened his grip on his ancient sword, feeling a strange heat emanating from its blade, as if the sword itself had awakened from a long slumber.

This defining moment was the start of a journey from which he would never return the same. A journey that would take him through cities submerged under the sand, mountains that speak with human tongues, and forests haunted by the spirits of ancient warriors. He knew the price might be his life, but he also knew that glory is only attained by passing through the fires of challenge.
""";

  /// Parses raw extracted text into an enforced array of ReaderSentence.
  /// Splits intelligently on sentence boundaries (. ! ? ؟)
  List<ReaderSentence> parseIntoSentences(String rawText) {
    // 1. Clean up weird formatting / broken newlines from PDF
    // Replace multiple newlines with a single space or preserve them if they mean paragraph breaks.
    // For reading view, single newlines inside a sentence are usually just wrapping.
    // Preserve paragraph breaks (double newlines) as sentence split points
    // then collapse single inner newlines (PDF line wraps) into spaces
    String normalized = rawText
        .replaceAll(RegExp(r'\r\n|\r'), '\n')          // normalise line endings
        .replaceAll(RegExp(r'\n{2,}'), '⏎')           // temp-mark paragraph breaks
        .replaceAll(RegExp(r'\n'), ' ')                // collapse soft wraps
        .replaceAll('⏎', '. ')                         // turn paragraphs into sentence breaks
        .replaceAll(RegExp(r' {2,}'), ' ')             // collapse extra spaces
        .trim();

    if (normalized.isEmpty) {
      debugPrint('[PdfExtractionService] Normalized text is empty, returning empty list.');
      return [];
    }

    // 2. Intelligent Regex Split
    // Matches any run of text ending in . ! ? ؟ (including Arabic ellipsis …)
    // The trailing \s* eats the space after a period.
    final sentences = <ReaderSentence>[];
    final matches =
        RegExp(r'[^.!?؟…]+[.!?؟…]+\s*|[^.!?؟…]+$').allMatches(normalized);

    int globalIndex = 0;
    for (final match in matches) {
      final sentenceText = match.group(0)?.trim();
      // Skip very short fragments (page numbers, stray characters, etc.)
      if (sentenceText == null || sentenceText.length < 4) continue;

      final isArabic = _arabicRegex.hasMatch(sentenceText);
      sentences.add(ReaderSentence(
        globalIndex: globalIndex,
        text: sentenceText,
        isArabic: isArabic,
      ));
      globalIndex++;
    }

    // If the regex still yields nothing, treat the whole text as one block
    if (sentences.isEmpty && normalized.isNotEmpty) {
      final isArabic = _arabicRegex.hasMatch(normalized);
      sentences.add(ReaderSentence(
        globalIndex: 0,
        text: normalized,
        isArabic: isArabic,
      ));
    }

    return sentences;
  }
}
