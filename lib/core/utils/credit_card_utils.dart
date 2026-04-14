class CreditCardUtils {
  static String formatCardNumber(String input) {
    input = input.replaceAll(' ', '');
    // Group by 4
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      buffer.write(input[i]);
      if ((i + 1) % 4 == 0 && i + 1 != input.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
