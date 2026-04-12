class ReaderSentence {
  final int globalIndex;
  final String text;
  final bool isArabic;

  const ReaderSentence({
    required this.globalIndex,
    required this.text,
    required this.isArabic,
  });

  // Determines text direction purely by checking characters
  bool get isRTL => isArabic;
}
