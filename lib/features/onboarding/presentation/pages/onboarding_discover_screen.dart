import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';

class OnboardingData {
  final String badgeText;
  final String title;
  final String subtitle;
  final String centerImage;
  final String leftImage;
  final String rightImage;

  OnboardingData({
    required this.badgeText,
    required this.title,
    required this.subtitle,
    required this.centerImage,
    required this.leftImage,
    required this.rightImage,
  });
}

class OnboardingDiscoverScreen extends StatefulWidget {
  const OnboardingDiscoverScreen({super.key});

  @override
  State<OnboardingDiscoverScreen> createState() => _OnboardingDiscoverScreenState();
}

class _OnboardingDiscoverScreenState extends State<OnboardingDiscoverScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Hardcoded network images for visual variety
  static const imageUrl1 = 'https://lh3.googleusercontent.com/aida-public/AB6AXuAWnomrZ9M3v0Gze3wsZXthx0BaDD9XiI1sKgZsuUfh68xH3o_lBe5F87CGRz9Taa-LEq5unsxqrr-F32GvajSxjWZP_iR28dQ793DHASwthURPzfX1pHnUEzCYWfChclyERBsQKNaUYQ52uXTVlvI7tAfadbyxwpOesBasunlt7wI9D83JYg-Pk6N4NiyQQaYPpXkgfOXBMtcOsiCvw1MfaS59MVULF__dcXvB4-DXi8X56030yPNgcxwZai8GLcky5judAj89K4E';
  static const imageUrl2 = 'https://lh3.googleusercontent.com/aida-public/AB6AXuBI9OQO8Uq3aeRQGP4ogNHZP7emeqOVvxUTuYY8RIjAxkvarFrzIKrF9S-J7t-m2cZFDmjNSYks40aKDKwCHV_lxyzUZsH3qTeAqfuKd3oalC_GbgnVX9_E5IwezH3bKuxD9Cxdc553g4sG1m60LaTf1bnAX-igFtKA6Bbnp6WM27ZTXYDjRk98-I7Tvjwtku00oPCxZchYOzooXxLcm9UP4HtPX9ADiUgzc-muyQ7T7MkN9UP-UZ5AXwUSaupkE_sm4F6s8mMMbWE';
  static const imageUrl3 = 'https://lh3.googleusercontent.com/aida-public/AB6AXuARLu3sUvZhY4fC_Ff6r3Bj3iElmhCOT15xP2ENjl6WP-ftHF6wQfGzYy8rfkmr3JIFZGE7AfU1UyHONNIgfSzPoyfopRLWmdXRQLKRgep9IK5Ys-FX_IyFFl34vaiH3p-5SupI_n2q7w2ywT4QK6g5U_Ua0hrVaauh1JC9uvxtTlU5ltpnJ30RDJEuTdSJR82pMzfyeJMSLvGLNP8-rHo9sqwnhLzoN68nVbzRZKlmb4iEFm472ntCIPnVDh62vavDIq560W8sUQs';

  final List<OnboardingData> _pages = [
    OnboardingData(
      badgeText: 'مكتبة رقمية متميزة',
      title: 'اكتشف عالم الكتب',
      subtitle: 'آلاف العناوين العربية بين يديك، استمتع بالقراءة والاستماع في تجربة فريدة.',
      centerImage: imageUrl2,
      leftImage: imageUrl1,
      rightImage: imageUrl3,
    ),
    OnboardingData(
      badgeText: 'استماع بلا حدود',
      title: 'استمع في أي مكان',
      subtitle: 'كتب صوتية بجودة عالية تناسب أوقات فراغك وتنقلاتك اليومية.',
      centerImage: imageUrl3,
      leftImage: imageUrl2,
      rightImage: imageUrl1,
    ),
    OnboardingData(
      badgeText: 'ابدأ رحلتك',
      title: 'لنبدأ القراءة',
      subtitle: 'أنشئ حسابك الآن وابدأ في تكوين مكتبتك الخاصة بكل سهولة.',
      centerImage: imageUrl1,
      leftImage: imageUrl3,
      rightImage: imageUrl2,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Fixed Background Glows
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            right: -100,
            child: _buildGlow(theme.colorScheme.primary.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            left: -100,
            child: _buildGlow(const Color(0xFF86E1A5).withValues(alpha: 0.05)),
          ),

          // Scrollable Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPageContent(context, theme, _pages[index]);
            },
          ),

          // Fixed Bottom Controls (Gradient Overlay, Indicators, Button)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.0),
                    theme.colorScheme.surface.withValues(alpha: 0.8),
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Page Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildIndicator(theme, _currentIndex == index),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 8,
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentIndex == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_back), // RTL direction arrow
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Header (Title & Skip)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'كتب FM',
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('تخطي'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(BuildContext context, ThemeData theme, OnboardingData data) {
    return Stack(
      children: [
        // Images Parallax Display
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 500,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left Image
                  Transform.translate(
                    offset: const Offset(40, -20),
                    child: Transform.rotate(
                      angle: -12 * 3.14159 / 180,
                      child: Transform.scale(
                        scale: 0.75,
                        child: Opacity(
                          opacity: 0.6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(data.leftImage, width: 200, height: 300, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right Image
                  Transform.translate(
                    offset: const Offset(-40, 20),
                    child: Transform.rotate(
                      angle: 12 * 3.14159 / 180,
                      child: Transform.scale(
                        scale: 0.9,
                        child: Opacity(
                          opacity: 0.8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(data.rightImage, width: 200, height: 300, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Center Image
                  Transform.scale(
                    scale: 1.1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 64,
                            offset: const Offset(0, 32),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(data.centerImage, width: 220, height: 350, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Text Content
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 200.0, left: 32.0, right: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories, color: theme.colorScheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        data.badgeText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 40),
                ),
                const SizedBox(height: 16),
                // Subtitle
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(ThemeData theme, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 32 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

