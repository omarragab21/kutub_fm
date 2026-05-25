import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
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
    _otpController.dispose();
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
    } else if (provider.status == AuthStatus.authenticated && !_navigated) {
      _navigated = true;
      final nextRoute = provider.isCategorySelectionCompleted
          ? AppRoutes.home
          : AppRoutes.categorySelection;
      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (_) => false);
    }
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (!_autovalidate) {
      setState(() {
        _autovalidate = true;
      });
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final smsCode = _otpController.text.trim();
    _lastErrorMessage = null;
    await context.read<AuthProvider>().verifyPhoneOtp(smsCode);
  }

  Future<void> _resendOtp() async {
    _lastErrorMessage = null;
    final authProvider = context.read<AuthProvider>();
    await authProvider.resendPhoneOtp();
    if (!mounted) return;
    if (authProvider.status != AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إعادة إرسال كود التحقق بنجاح',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;
    final pendingPhone = authProvider.pendingPhoneNumber ?? '';

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
                        Icons.security_rounded,
                        color: theme.colorScheme.primary,
                        size: 72,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'تأكيد رقم الهاتف',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'أدخل كود التحقق المكون من 6 أرقام المرسل إلى الرقم\n$pendingPhone',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: _inputDecoration(
                          context,
                          label: 'رمز التحقق',
                          hint: '******',
                          icon: Icons.lock_open_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'برجاء إدخال رمز التحقق';
                          }
                          if (value.trim().length != 6) {
                            return 'يجب أن يتكون رمز التحقق من 6 أرقام';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'رمز التحقق يجب أن يحتوي على أرقام فقط';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: isLoading ? null : _verifyOtp,
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
                                'تأكيد الدخول',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: isLoading ? null : _resendOtp,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'إعادة إرسال كود التحقق',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
        letterSpacing: 0,
      ),
    );
  }
}
