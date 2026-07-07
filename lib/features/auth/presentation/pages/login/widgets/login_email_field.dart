import 'package:flutter/material.dart';

import '../../../../../../core/validators/auth_validators.dart';
import 'login_text_field.dart';

class LoginEmailField extends StatelessWidget {
  const LoginEmailField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return LoginTextField(
      controller: controller,
      label: 'البريد الإلكتروني',
      icon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      validator: AuthValidators.validateLoginEmail,
    );
  }
}
