import 'package:flutter/material.dart';

class LoginButtons extends StatelessWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onPhoneLoginPressed;
  final bool isLoading;

  const LoginButtons({
    super.key,
    this.onLoginPressed,
    this.onPhoneLoginPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: isLoading ? null : onLoginPressed,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Text('تسجيل الدخول'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onPhoneLoginPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
          ),
          icon: const Icon(Icons.phone_android_rounded, size: 22),
          label: const Text('تسجيل الدخول برقم الهاتف'),
        ),
      ],
    );
  }
}
