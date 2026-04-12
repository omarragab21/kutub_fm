import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_provider.dart';
import '../audio/widgets/global_mini_player.dart';
import '../navigation/app_navigation_state.dart';
import '../routes/app_routes.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final navigationState = context.watch<AppNavigationState>();
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final hideForRoutes = <String>{
      AppRoutes.audioPlayer,
      AppRoutes.bookReader,
      AppRoutes.fmStationDetail,
    };

    final showMiniPlayer =
        audioProvider.shouldShowMiniPlayer &&
        !keyboardVisible &&
        !hideForRoutes.contains(navigationState.currentRouteName);
    final bottomOffset = navigationState.isCurrentRoute(AppRoutes.home)
        ? 110.0
        : 16.0 + safeBottom;

    return Stack(
      children: [
        child,
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomOffset,
          child: IgnorePointer(
            ignoring: !showMiniPlayer,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: AnimatedSlide(
                  offset: showMiniPlayer ? Offset.zero : const Offset(0, 1.2),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: showMiniPlayer ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: const GlobalMiniPlayer(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
