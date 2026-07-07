import 'package:flutter/material.dart';

class LoginResetPasswordButton extends StatelessWidget {
  const LoginResetPasswordButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        child: const Text('نسيت كلمة المرور؟'),
      ),
    );
  }
}
