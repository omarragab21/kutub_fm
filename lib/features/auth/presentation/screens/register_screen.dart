import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/dialogs/loading_dialog.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  Future<void> _registerWithEmail() async {
    FocusScope.of(context).unfocus();
    if (!_autovalidate) {
      setState(() => _autovalidate = true);
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = email.split('@').first; // Auto-generate name from email

    LoadingDialog.show(context, message: 'جاري إنشاء الحساب...');
    try {
      await authProvider.register(name: name, email: email, password: password);
    } catch (_) {
    } finally {
      if (mounted) LoadingDialog.hide(context);
    }

    if (!mounted) return;

    if (authProvider.status == AuthStatus.error &&
        authProvider.errorMessage != null) {
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
    } else if (authProvider.status == AuthStatus.error &&
        authProvider.errorMessage != null) {
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
    } else if (authProvider.status == AuthStatus.error &&
        authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
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
          child: _showEmailForm ? _buildEmailForm() : _buildSignupOptions(),
        ),
      ),
    );
  }

  Widget _buildSignupOptions() {
    return Column(
      key: const ValueKey('options'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 10.h),
        Text(
          'إنشاء حساب جديد',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 24.h),
        // Google Button
        _buildSocialButton(
          text: 'حساب جوجل',
          iconPath: 'assets/google_icon.svg',
          onPressed: _signInWithGoogle,
        ),
        SizedBox(height: 12.h),
        // Facebook Button
        _buildSocialButton(
          text: 'فيسبوك',
          iconPath: 'assets/facebook_icon.svg',
          onPressed: _signInWithFacebook,
        ),
        SizedBox(height: 12.h),
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
        SizedBox(height: 12.h),
        // Phone Button
        _buildSocialButton(
          text: 'رقم الهاتف',
          icon: Icon(
            Icons.smartphone_outlined,
            color: Colors.white,
            size: 22.r,
          ),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.phoneLogin);
          },
        ),
        SizedBox(height: 36.h),
        // Footer: لديك حساب بالفعل؟ تسجيل الدخول
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'لديك حساب بالفعل؟ ',
              style: TextStyle(color: Colors.white, fontSize: 15.sp),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: Text(
                'تسجيل الدخول',
                style: TextStyle(
                  color: const Color(0xFF54B1FF),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
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
                child: SvgPicture.asset(
                  'assets/email_icon.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'برجاء إدخال البريد الإلكتروني';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value.trim())) {
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
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white54,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white54,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'برجاء إدخال كلمة المرور';
              }
              if (value.length < 6) {
                return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          // Yellow Submit Button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _registerWithEmail,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC00E),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إنشاء حساب جديد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white70,
              ),
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
        side: const BorderSide(color: Color(0xFFC5C5C5), width: 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        minimumSize: Size.fromHeight(50.h),
        padding: EdgeInsets.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconPath != null
              ? SvgPicture.asset(iconPath, width: 22.w, height: 22.h)
              : (icon ?? const SizedBox.shrink()),
          SizedBox(width: 12.w),
          Text(
            text,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
