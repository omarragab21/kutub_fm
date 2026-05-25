import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _autovalidate = false;
  bool _navigated = false;
  String? _lastErrorMessage;
  AuthProvider? _authProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = Provider.of<AuthProvider>(context);
    if (_authProvider != newProvider) {
      _authProvider?.removeListener(_onAuthStateChanged);
      _authProvider = newProvider;
      _authProvider?.addListener(_onAuthStateChanged);
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthStateChanged);
    _phoneController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final provider = _authProvider;
    if (provider == null) return;

    if (provider.status == AuthStatus.error &&
        provider.errorMessage != null &&
        _lastErrorMessage != provider.errorMessage) {
      _lastErrorMessage = provider.errorMessage;
      log('PhoneLoginScreen: Authentication error - ${provider.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (provider.hasPhoneVerificationId &&
        provider.status != AuthStatus.loading &&
        !_navigated) {
      _navigated = true;
      Navigator.pushNamed(context, AppRoutes.otpVerification).then((_) {
        _navigated = false;
      });
    }
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();

    if (!_autovalidate) {
      setState(() {
        _autovalidate = true;
      });
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.replaceAll(' ', '').trim();
    _lastErrorMessage = null;
    await context.read<AuthProvider>().sendPhoneOtp(phone);
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                        Icons.phone_android_rounded,
                        color: theme.colorScheme.primary,
                        size: 72,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'تسجيل الدخول برقم الهاتف',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'أدخل رقم هاتفك لتلقي رمز التحقق (OTP) عبر رسالة نصية قصيرة.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: _inputDecoration(
                          context,
                          label: 'رقم الهاتف',
                          hint: '+201012345678',
                          icon: Icons.phone_enabled_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'برجاء إدخال رقم الهاتف';
                          }
                          final clean = value.replaceAll(' ', '').trim();
                          if (!clean.startsWith('+')) {
                            return 'يجب أن يبدأ رقم الهاتف بـ + ومفتاح الدولة';
                          }
                          if (clean.length < 10) {
                            return 'رقم الهاتف غير صحيح (10 أرقام على الأقل)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: isLoading ? null : _sendOtp,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                'إرسال كود التحقق',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'تريد العودة؟',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('تسجيل الدخول بالبريد'),
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
    required String hint,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
