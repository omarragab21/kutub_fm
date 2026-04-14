import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingBookCover extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;

  const FloatingBookCover({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
  });

  @override
  State<FloatingBookCover> createState() => _FloatingBookCoverState();
}

class _FloatingBookCoverState extends State<FloatingBookCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _verticalAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Smooth 4s loop
    );

    _verticalAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _shadowAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingBookCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        // Reset to neutral position when paused
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _verticalAnimation,
        _rotationAnimation,
        _scaleAnimation,
        _shadowAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _verticalAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 220,
                height: 330, // 2:3 aspect ratio
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // بلون خافت
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    // Primary shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(_shadowAnimation.value),
                      blurRadius: 50,
                      spreadRadius: -15,
                      offset: Offset(
                        0,
                        25 + _verticalAnimation.value.abs() * 0.5,
                      ),
                    ),
                    // Ambient glow effect when playing
                    if (widget.isPlaying)
                      BoxShadow(
                        color: const Color(0xFFF2CA50).withOpacity(_shadowAnimation.value * 0.25), // 0.025 to 0.075 (faint animated glow)
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    // Subtle colored shadow (faint)
                    BoxShadow(
                      color: const Color(0xFFF2CA50).withOpacity(0.03),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Main image
                      Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFF2CA50).withOpacity(0.3),
                                  const Color(0xFF131313).withOpacity(0.5),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.book,
                                size: 80,
                                color: Color(0xFFF2CA50),
                              ),
                            ),
                          );
                        },
                      ),
                      // Subtle overlay for depth
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                      // Reflective shine effect
                      if (widget.isPlaying)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment(
                                      -1.0 + _rotationAnimation.value * 10,
                                      -0.5,
                                    ),
                                    end: Alignment(
                                      1.0 - _rotationAnimation.value * 10,
                                      0.5,
                                    ),
                                    colors: [
                                      Colors.white.withOpacity(0.1),
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.05),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
