import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/kotob_fm_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authStatus = context.watch<AuthProvider>().status;
    _navigateWhenReady(authStatus);
  }

  void _navigateWhenReady(AuthStatus status) {
    if (_hasNavigated ||
        status == AuthStatus.initial ||
        status == AuthStatus.loading ||
        status == AuthStatus.error) {
      return;
    }

    _hasNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final route = switch (status) {
        AuthStatus.guest => AppRoutes.login,
        AuthStatus.authenticated =>
          context.read<AuthProvider>().isCategorySelectionCompleted
              ? AppRoutes.home
              : AppRoutes.categorySelection,
        AuthStatus.emailNotVerified => AppRoutes.emailVerification,
        AuthStatus.unauthenticated => AppRoutes.onboarding,
        AuthStatus.initial ||
        AuthStatus.loading ||
        AuthStatus.error => AppRoutes.onboarding,
      };

      Navigator.pushReplacementNamed(context, route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const KotobFMLogo(height: 90),
                const SizedBox(height: 24),
                Text(
                  'THE DIGITAL CURATOR',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    letterSpacing: 4.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 80),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                    minHeight: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.status == AuthStatus.error
                      ? authProvider.errorMessage ?? 'حدث خطأ أثناء المصادقة'
                      : 'جاري تحميل مكتبتك الخاصة...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: authProvider.status == AuthStatus.error
                        ? Colors.redAccent
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
