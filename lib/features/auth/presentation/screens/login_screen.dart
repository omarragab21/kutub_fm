import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/dialogs/loading_dialog.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showEmailForm = false;
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

  Future<void> _loginWithEmail() async {
    FocusScope.of(context).unfocus();
    if (!_autovalidate) {
      setState(() => _autovalidate = true);
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    LoadingDialog.show(context, message: 'جاري تسجيل الدخول...');
    try {
      await authProvider.login(
        email: email,
        password: password,
      );
    } catch (_) {
    } finally {
      if (mounted) LoadingDialog.hide(context);
    }

    if (!mounted) return;

    if (authProvider.status == AuthStatus.error && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (authProvider.status == AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(context, AppRoutes.emailVerification);
    } else if (authProvider.status == AuthStatus.authenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.authSuccess);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    LoadingDialog.show(context, message: 'جاري تسجيل الدخول بجوجل...');
    try {
      await authProvider.signInWithGoogle();
    } catch (_) {}
    if (mounted) LoadingDialog.hide(context);

    if (!mounted) return;
    if (authProvider.status == AuthStatus.authenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.authSuccess);
    } else if (authProvider.status == AuthStatus.error && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _signInWithFacebook() async {
    final authProvider = context.read<AuthProvider>();
    LoadingDialog.show(context, message: 'جاري تسجيل الدخول بفيسبوك...');
    try {
      await authProvider.signInWithFacebook();
    } catch (_) {}
    if (mounted) LoadingDialog.hide(context);

    if (!mounted) return;
    if (authProvider.status == AuthStatus.authenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.authSuccess);
    } else if (authProvider.status == AuthStatus.error && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال بريد إلكتروني صحيح أولاً لإرسال رابط استعادة كلمة المرور'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    LoadingDialog.show(context, message: 'جاري إرسال طلب استعادة كلمة المرور...');
    try {
      await authProvider.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رابط استعادة كلمة المرور لبريدك الإلكتروني'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) LoadingDialog.hide(context);
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showEmailForm ? _buildEmailForm() : _buildLoginOptions(),
        ),
      ),
    );
  }

  Widget _buildLoginOptions() {
    return Column(
      key: const ValueKey('options'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تسجيل الدخول',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        // Google Button
        _buildSocialButton(
          text: 'حساب جوجل',
          iconPath: 'assets/google_icon.svg',
          onPressed: _signInWithGoogle,
        ),
        const SizedBox(height: 12),
        // Facebook Button
        _buildSocialButton(
          text: 'فيسبوك',
          iconPath: 'assets/facebook_icon.svg',
          onPressed: _signInWithFacebook,
        ),
        const SizedBox(height: 12),
        // Email Button
        _buildSocialButton(
          text: 'البريد الإلكتروني',
          iconPath: 'assets/email_icon.svg',
          onPressed: () {
            setState(() {
              _showEmailForm = true;
            });
          },
        ),
        const SizedBox(height: 12),
        // Phone Button
        _buildSocialButton(
          text: 'رقم الهاتف',
          icon: const Icon(Icons.smartphone_rounded, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.phoneLogin);
          },
        ),
        const SizedBox(height: 36),
        // Footer: ليس لديك حساب؟ إنشاء حساب جديد
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ليس لديك حساب؟ ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, AppRoutes.register);
              },
              child: const Text(
                'إنشاء حساب جديد',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        key: const ValueKey('emailForm'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تسجيل بالبريد الإلكتروني',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textDirection: TextDirection.ltr,
            decoration: _inputDecoration(
              hintText: 'example@gmail.com',
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset('assets/email_icon.svg', width: 20, height: 20),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'برجاء إدخال البريد الإلكتروني';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'البريد الإلكتروني غير صحيح';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textDirection: TextDirection.ltr,
            decoration: _inputDecoration(
              hintText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white54,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'برجاء إدخال كلمة المرور';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          // Forgot Password Link
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _resetPassword,
              child: const Text(
                'نسيت كلمة المرور؟',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Yellow Submit Button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _loginWithEmail,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC00E),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Back Link: عودة للخلف
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showEmailForm = false;
                  _autovalidate = false;
                });
              },
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
              label: const Text(
                'عودة للخلف',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    String? iconPath,
    Widget? icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconPath != null
              ? SvgPicture.asset(iconPath, width: 20, height: 20)
              : (icon ?? const SizedBox.shrink()),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
