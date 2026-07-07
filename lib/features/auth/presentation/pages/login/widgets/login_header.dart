import 'package:flutter/material.dart';
import '../../../../../../core/widgets/kotob_fm_logo.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const Center(child: KotobFMLogo(height: 56)),
        const SizedBox(height: 24),
        Text(
          'تسجيل الدخول',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 8),
        Text(
          'ادخل إلى مكتبتك الصوتية وواصل رحلتك',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
