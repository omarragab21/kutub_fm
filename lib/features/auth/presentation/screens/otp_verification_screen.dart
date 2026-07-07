import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
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
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authSuccess,
        (_) => false,
      );
    }
  }

  String _getOtp() {
    return _controllers.map((c) => c.text.trim()).join();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final otp = _getOtp();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برجاء إدخال كود التحقق كاملاً (6 أرقام)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _lastErrorMessage = null;
    await context.read<AuthProvider>().verifyPhoneOtp(otp);
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
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;
    final pendingPhone = authProvider.pendingPhoneNumber ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تأكيد رقم الهاتف',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'أدخل كود التحقق المكون من 6 أرقام إلى رقم:\n\u200e$pendingPhone',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // 6-digit OTP fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPinField(0),
                SizedBox(width: 5.w),
                _buildPinField(1),
                SizedBox(width: 5.w),
                _buildPinField(2),
                SizedBox(width: 10.w),
                Container(
                  width: 19.w,
                  height: 1.h,
                  color: const Color.fromRGBO(217, 217, 217, 1),
                ),
                SizedBox(width: 10.w),
                _buildPinField(3),
                SizedBox(width: 5.w),
                _buildPinField(4),
                SizedBox(width: 5.w),
                _buildPinField(5),
              ],
            ),
            const SizedBox(height: 32),
            // Yellow Button "إرسال كود التحقق"
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: isLoading ? null : _verifyOtp,
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
            const SizedBox(height: 12),
            // Black/Outline Button: إعادة إرسال الكود
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isLoading ? null : _resendOtp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'إعادة إرسال الكود',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Footer link: عودة للخلف
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
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
      ),
    );
  }

  Widget _buildPinField(int index) {
    return SizedBox(
      width: 44.w,
      height: 44.w,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color.fromRGBO(238, 238, 238, 1),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.black,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 1.0),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }
}
