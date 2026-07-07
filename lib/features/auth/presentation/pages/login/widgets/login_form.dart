import 'package:flutter/material.dart';

import '../../../../../../core/routes/app_routes.dart';
import 'login_buttons.dart';
import 'login_email_field.dart';
import 'login_footer.dart';
import 'login_header.dart';
import 'login_password_field.dart';
import 'login_reset_password_button.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.formKey,
    required this.autovalidate,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePasswordVisibility,
    required this.onResetPasswordPressed,
    required this.onLoginPressed,
  });

  final GlobalKey<FormState> formKey;
  final bool autovalidate;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onResetPasswordPressed;
  final VoidCallback onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: autovalidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LoginHeader(),
          const SizedBox(height: 36),
          LoginEmailField(controller: emailController),
          const SizedBox(height: 16),
          LoginPasswordField(
            controller: passwordController,
            obscurePassword: obscurePassword,
            onToggleVisibility: onTogglePasswordVisibility,
          ),
          LoginResetPasswordButton(
            isLoading: isLoading,
            onPressed: onResetPasswordPressed,
          ),
          const SizedBox(height: 24),
          LoginButtons(
            isLoading: isLoading,
            onLoginPressed: onLoginPressed,
            onPhoneLoginPressed: () {
              Navigator.pushNamed(context, AppRoutes.phoneLogin);
            },
          ),
          const SizedBox(height: 24),
          LoginFooter(
            isLoading: isLoading,
            onRegisterPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.register);
            },
          ),
        ],
      ),
    );
  }
}
