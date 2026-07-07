import 'package:flutter/material.dart';

import '../../../../../../core/validators/auth_validators.dart';
import 'login_text_field.dart';

class LoginPasswordField extends StatelessWidget {
  const LoginPasswordField({
    super.key,
    required this.controller,
    required this.obscurePassword,
    required this.onToggleVisibility,
  });

  final TextEditingController controller;
  final bool obscurePassword;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return LoginTextField(
      controller: controller,
      label: 'كلمة المرور',
      icon: Icons.lock_outline_rounded,
      obscureText: obscurePassword,
      autofillHints: const [AutofillHints.password],
      validator: AuthValidators.validateLoginPassword,
      suffixIcon: IconButton(
        onPressed: onToggleVisibility,
        icon: Icon(
          obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    );
  }
}
