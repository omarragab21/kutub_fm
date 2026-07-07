import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  Future<void> _checkVerification(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkEmailVerification();

    if (!context.mounted) return;
    if (authProvider.status == AuthStatus.authenticated) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.authSuccess, (_) => false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'لم يتم تفعيل البريد بعد'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _resendVerification(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.resendVerificationEmail();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authProvider.errorMessage ?? 'تم إرسال رسالة التفعيل مرة أخرى',
        ),
        backgroundColor: authProvider.errorMessage != null ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userEmail = authProvider.user?.email ?? '';
    final isLoading = authProvider.status == AuthStatus.loading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'فعل بريدك الإلكتروني',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'أرسلنا رسالة تفعيل إلى:\n$userEmail\nافتح الرسالة واضغط على رابط التفعيل للبدء.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Yellow Button: تحقق من البريد
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: isLoading ? null : () => _checkVerification(context),
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
                        'تحقق من البريد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Black/Outline Button: إعادة إرسال رسالة التفعيل
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isLoading ? null : () => _resendVerification(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'إعادة إرسال رسالة التفعيل',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Footer link: عودة للخلف (تسجيل الخروج والرجوع)
            Center(
              child: TextButton.icon(
                onPressed: isLoading ? null : () => _logout(context),
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
    );
  }
}
