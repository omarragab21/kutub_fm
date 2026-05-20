import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  Future<void> _checkVerification(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkEmailVerification();

    if (!context.mounted) return;
    if (authProvider.status == AuthStatus.authenticated) {
      final nextRoute = authProvider.isCategorySelectionCompleted
          ? AppRoutes.home
          : AppRoutes.categorySelection;
      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (_) => false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'لم يتم تفعيل البريد بعد'),
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
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final userEmail = authProvider.user?.email;
    final isLoading = authProvider.status == AuthStatus.loading;
    log(authProvider.errorMessage.toString());
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 84,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'فعّل بريدك الإلكتروني',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userEmail == null
                          ? 'أرسلنا رسالة تفعيل إلى بريدك. افتح الرسالة واضغط رابط التفعيل ثم عد إلى التطبيق.'
                          : 'أرسلنا رسالة تفعيل إلى $userEmail. افتح الرسالة واضغط رابط التفعيل ثم عد إلى التطبيق.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    if (authProvider.errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        authProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 36),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () => _checkVerification(context),
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
                          : const Text('تحققت من البريد'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => _resendVerification(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: const Text('إعادة إرسال رسالة التفعيل'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading ? null : () => _logout(context),
                      child: const Text('تسجيل الخروج'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
