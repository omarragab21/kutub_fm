import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final bool showLogo;

  const AuthBackground({super.key, required this.child, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Stack: Grid Image fading to black at bottom + Logo overlay
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset(
                    'assets/background_image.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 395.h,
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.85),
                            Colors.black,
                          ],
                          stops: const [0.0, 0.35, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                  if (showLogo)
                    Positioned(
                      bottom: 24.h,
                      right: 24.w,
                      child: Image.asset(
                        'assets/app_logo.png',
                        width: 93.w,
                        height: 45.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 5.h),
              // Body Content Container
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 11.w),
                child: child,
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
