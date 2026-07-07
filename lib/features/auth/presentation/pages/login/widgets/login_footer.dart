import 'package:flutter/material.dart';

class LoginFooter extends StatelessWidget {
  final VoidCallback? onRegisterPressed;
  final bool isLoading;

  const LoginFooter({
    super.key,
    this.onRegisterPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        TextButton(
          onPressed: isLoading ? null : onRegisterPressed,
          child: const Text('إنشاء حساب'),
        ),
      ],
    );
  }
}
