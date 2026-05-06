import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/validators/auth_validators.dart';
import '../../../../core/dialogs/loading_dialog.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _autovalidate = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_autovalidate) {
      setState(() {
        _autovalidate = true;
      });
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();

    LoadingDialog.show(context, message: 'جاري تسجيل الدخول...');

    try {
      await authProvider.login(
        email: AuthValidators.normalizeEmail(_emailController.text),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      // Handled by Provider
    } finally {
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }

    if (!mounted) return;

    if (authProvider.status == AuthStatus.error &&
        authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage!,
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _navigateForStatus(authProvider.status);
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();

    LoadingDialog.show(context, message: 'جاري تسجيل الدخول بجوجل...');

    try {
      await authProvider.signInWithGoogle();
    } catch (e) {
      // Handled by Provider
    } finally {
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }

    if (!mounted) return;

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

    _navigateForStatus(authProvider.status);
  }

  Future<void> _continueAsGuest() async {
    final authProvider = context.read<AuthProvider>();

    LoadingDialog.show(context, message: 'جاري الدخول كزائر...');

    try {
      await authProvider.continueAsGuest();
    } catch (e) {
      // Handled by Provider
    } finally {
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }

    if (!mounted) return;

    if (authProvider.status == AuthStatus.error &&
        authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage!,
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _navigateForStatus(authProvider.status);
  }

  Future<void> _resetPassword() async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة كلمة المرور'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
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
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(
                  context,
                  AuthValidators.normalizeEmail(emailController.text),
                );
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    emailController.dispose();

    if (email == null || email.trim().isEmpty || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    LoadingDialog.show(context, message: 'جاري إرسال الرابط...');

    try {
      await authProvider.resetPassword(email);
    } catch (e) {
      // Handled by Provider
    } finally {
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }

    if (!mounted) return;
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

  void _navigateForStatus(AuthStatus status) {
    if (status == AuthStatus.authenticated || status == AuthStatus.guest) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else if (status == AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(context, AppRoutes.emailVerification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: theme.colorScheme.primary,
                        size: 72,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'تسجيل الدخول',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ادخل إلى مكتبتك الصوتية وواصل رحلتك',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.email],
                        decoration: _inputDecoration(
                          context,
                          label: 'البريد الإلكتروني',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: AuthValidators.validateLoginEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textDirection: TextDirection.ltr,
                        decoration: _inputDecoration(
                          context,
                          label: 'كلمة المرور',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: AuthValidators.validateLoginPassword,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: isLoading ? null : _resetPassword,
                          child: const Text('نسيت كلمة المرور؟'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: isLoading ? null : _login,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('تسجيل الدخول'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('تسجيل الدخول بجوجل'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: isLoading ? null : _continueAsGuest,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        child: const Text('الدخول كزائر'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.register,
                                  ),
                            child: const Text('إنشاء حساب'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
