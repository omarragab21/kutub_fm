import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/widgets/auth_background.dart';

class OnboardingDiscoverScreen extends StatelessWidget {
  const OnboardingDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // Tagline text matching design
            const Text(
              'منصة واحدة تجمع بين الكتب المقروءة،\nالكتب الصوتية، البودكاست، والريلز.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            // Yellow Button "بدء الرحلة الآن"
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.register);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC00E),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'بدء الرحلة الآن',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Bottom Link: لديك حساب بالفعل؟ تسجيل الدخول
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'لديك حساب بالفعل؟ ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
