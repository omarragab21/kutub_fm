import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';

class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({super.key});

  @override
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen> {
  Future<void> _startJourney() async {
    final authProvider = context.read<AuthProvider>();
    final nextRoute = authProvider.isCategorySelectionCompleted
        ? AppRoutes.home
        : AppRoutes.categorySelection;
    Navigator.pushNamedAndRemoveUntil(context, nextRoute, (_) => false);
  }

  Future<void> _goBack() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.onboarding,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: AuthBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'تم التسجيل بنجاح',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  SvgPicture.asset(
                    'assets/party.svg',
                    height: 24.h,
                    width: 24.w,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Emoji and welcome message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'مرحباً بك في عالمنا... عالم كتب FM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Yellow Button: بدء الرحلة الآن
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _startJourney,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC00E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'بدء الرحلة الآن',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Footer Link: عودة للخلف
              Center(
                child: TextButton.icon(
                  onPressed: _goBack,
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
      ),
    );
  }
}
