import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/dialogs/loading_dialog.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/validators/auth_validators.dart';
import '../../providers/auth_provider.dart';

class LoginScreenController {
  LoginScreenController({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.enableAutovalidate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback enableAutovalidate;

  Future<void> login(BuildContext context) async {
    FocusScope.of(context).unfocus();
    enableAutovalidate();

    if (!(formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();

    LoadingDialog.show(context, message: 'جاري تسجيل الدخول...');

    try {
      await authProvider.login(
        email: AuthValidators.normalizeEmail(emailController.text),
        password: passwordController.text.trim(),
      );
    } catch (_) {
      // Handled by Provider
    } finally {
      if (context.mounted) {
        LoadingDialog.hide(context);
      }
    }

    if (!context.mounted) return;

    if (authProvider.status == AuthStatus.error &&
        authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _navigateForStatus(context, authProvider);
  }

  Future<void> resetPassword(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _ResetPasswordDialog(initialEmail: emailController.text),
    );

    if (email == null || email.trim().isEmpty || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();

    LoadingDialog.show(context, message: 'جاري إرسال الرابط...');

    try {
      await authProvider.resetPassword(email);
    } catch (_) {
      // Handled by Provider
    } finally {
      if (context.mounted) {
        LoadingDialog.hide(context);
      }
    }

    if (!context.mounted) return;

    final error = authProvider.errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني',
        ),
        backgroundColor: error == null ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateForStatus(BuildContext context, AuthProvider authProvider) {
    if (authProvider.status == AuthStatus.guest) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else if (authProvider.status == AuthStatus.authenticated) {
      final nextRoute = authProvider.isCategorySelectionCompleted
          ? AppRoutes.home
          : AppRoutes.categorySelection;
      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (_) => false);
    } else if (authProvider.status == AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(context, AppRoutes.emailVerification);
    }
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(
        context,
        AuthValidators.normalizeEmail(_emailController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('استعادة كلمة المرور'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            hintText: 'name@example.com',
            labelText: 'البريد الإلكتروني',
          ),
          validator: AuthValidators.validateLoginEmail,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('إرسال')),
      ],
    );
  }
}
