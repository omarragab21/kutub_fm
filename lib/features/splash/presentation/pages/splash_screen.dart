import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
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
        AuthStatus.guest || AuthStatus.authenticated => AppRoutes.home,
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
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.menu_book,
                      size: 64,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text('كتب FM', style: theme.textTheme.displayLarge),
                ),
                const SizedBox(height: 16),
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
