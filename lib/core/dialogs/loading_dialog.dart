import 'package:flutter/material.dart';

class LoadingDialog {
  static bool _isShowing = false;

  static Future<void> show(BuildContext context, {String? message}) async {
    if (_isShowing) return;
    _isShowing = true;

    final theme = Theme.of(context);

    // showDialog returns a Future when the dialog is dismissed.
    // We don't await it here so the caller can continue its async work.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 24,
            ),
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    message ?? 'جاري التحميل...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (!_isShowing) return;
    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {
      // Ignored
    } finally {
      _isShowing = false;
    }
  }
}
