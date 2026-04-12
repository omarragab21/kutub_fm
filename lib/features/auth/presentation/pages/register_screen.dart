import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header Section with Asymmetric Clip
            Stack(
              children: [
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 310,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                    ),
                    child: Stack(
                      children: [
                        // Background Image
                        Opacity(
                          opacity: 0.2,
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCyS1Xq2jgjzu4r6-o8uETpfXGMYAOiluZjH_94Mt64t1q1Q_8BlqMAmkpaiILDdfYrKTp7Rm6zSWvfvDEGQ4Imm1hJwqzx3-bLKgPb_2x2_ipkZfMD9hFZFCBOp44wA4GSyGkuBYy4N4dUX5s-U50QTTpesg2GV26hcLv0fMPamcaXOi4VMgleuRLmEBY-kLsKfqqmqpT9wq328G9PP0zeq9Ug9bH4fJI73Lok_eYk1smxYa5ZAdZg6pYDbYvIK9tMNi-n3GSTh20',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                theme.colorScheme.surface.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      const Color(0xFFF2CA50),
                                      const Color(0xFFD4AF37),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'كتب FM',
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontSize: 48,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ابدأ رحلتك في عالم الكتب والصوت',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Column(
                children: [
                  // Benefit Highlights (Bento-style)
                  Row(
                    children: [
                      Expanded(child: _buildBenefitCard(theme, Icons.headphones, 'استمع للكتب', theme.colorScheme.tertiary)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBenefitCard(theme, Icons.auto_stories, 'اقرأ دائماً', theme.colorScheme.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBenefitCard(theme, Icons.podcasts, 'بث مباشر FM', theme.colorScheme.error)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Registration Form
                  _buildInputWrapper(
                    theme,
                    child: TextField(
                      controller: _nameController,
                      decoration: _inputDecoration(theme, 'الاسم الكامل', Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputWrapper(
                    theme,
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(theme, 'البريد الإلكتروني', Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputWrapper(
                    theme,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        theme,
                        'كلمة المرور',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputWrapper(
                    theme,
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(theme, 'تأكيد كلمة المرور', Icons.lock_reset_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.categorySelection);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 8,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      child: const Text('إنشاء حساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Social Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('أو التسجيل بواسطة', style: theme.textTheme.labelSmall),
                      ),
                      Expanded(child: Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social Buttons
                  Row(
                    children: [
                      Expanded(child: _buildSocialButton(theme, 'Google', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCL3Z0wrd9UCcCo7t2TXywdd1v1UM4iKcIEdIdeewu7PKDxSb4PJNUZeTLZwyL4Xl5A2x7gUWQZPRp0f_14RxJggxePIMWaWu6MZdg-kbb2HeFt8XhKGK3DqcwC1Ic4NRgisFHaF8SQjwbn90FEv8gd1F4DRDb-mZeJo9f5N9BM75403nbsnw1_INpsuXeOLyycZ91n_kzwI-ypYEZrBYTxclG5fcIUI0bp7Bvx8cnQRpk50a21NZjXyVQ87RICVf50Du4QwWPb5PE')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSocialButton(theme, 'Apple', null, icon: Icons.apple)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('لديك حساب بالفعل؟', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: Text(
                          'تسجيل الدخول',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard(ThemeData theme, IconData icon, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B1B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInputWrapper(ThemeData theme, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      suffixIcon: suffix,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSocialButton(ThemeData theme, String label, String? imageUrl, {IconData? icon}) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageUrl != null)
            Image.network(imageUrl, width: 20, height: 20)
          else if (icon != null)
            Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height * 0.85);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
