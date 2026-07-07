import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';

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

    String phone = _phoneController.text.replaceAll(' ', '').trim();
    
    // Normalize phone number to strip any leading zero and ensure +20 prefix
    if (phone.startsWith('+20')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('20')) {
      phone = phone.substring(2);
    }
    
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    
    final finalPhone = '+20$phone';
    
    _lastErrorMessage = null;
    await context.read<AuthProvider>().sendPhoneOtp(finalPhone);
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required Widget prefixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.white, fontSize: 16),
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
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تسجيل برقم الهاتف',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'أدخل رقم هاتفك لتلقي رمز التحقق OTP برسالة نصية قصيرة SMS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Phone Input Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textDirection: TextDirection.ltr,
                decoration: _inputDecoration(
                  hintText: '10500812',
                  prefixIcon: const Icon(Icons.smartphone_rounded, color: Colors.white54),
                  prefixText: '\u200e+20 ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'برجاء إدخال رقم الهاتف';
                  }
                  String clean = value.replaceAll(' ', '').trim();
                  if (clean.startsWith('+20')) {
                    clean = clean.substring(3);
                  } else if (clean.startsWith('20')) {
                    clean = clean.substring(2);
                  }
                  if (clean.startsWith('0')) {
                    clean = clean.substring(1);
                  }
                  if (clean.length < 9) {
                    return 'رقم الهاتف غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              // Submit Button
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _sendOtp,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC00E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.black,
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
              ),
              const SizedBox(height: 20),
              // Footer link: عودة للخلف
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
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
        ),
      ),
    );
  }
}
