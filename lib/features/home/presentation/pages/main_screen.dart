import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kutub_fm/features/reels/presentation/pages/reels_feed_page.dart';
import 'package:kutub_fm/features/radio/presentation/pages/fm_radio_screen.dart';
import 'package:kutub_fm/features/reader_sessions/presentation/pages/reader_sessions_screen.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';
import 'package:kutub_fm/core/navigation/app_navigation_state.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _onItemTapped(int index) {
    context.read<AppNavigationState>().setSelectedIndex(index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<HomeViewModel>();
      if (!viewModel.isLoading &&
          viewModel.categories.isEmpty &&
          viewModel.recommendedBooks.isEmpty) {
        viewModel.fetchHomeData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationState = context.watch<AppNavigationState>();
    final selectedIndex = navigationState.selectedTabIndex;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Main Content
          _buildPage(selectedIndex),

          // Custom Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavBar(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF353534).withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(theme, 'assets/home_smile.svg', index: 0),
          _buildNavItem(theme, 'assets/community.svg', index: 1),
          _buildNavItem(theme, 'assets/audio_wave.svg', index: 2),
          _buildNavItem(theme, 'assets/play.svg', index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    ThemeData theme,
    String svgAssetPath, {
    required int index,
  }) {
    final isSelected =
        context.watch<AppNavigationState>().selectedTabIndex == index;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withValues(
            alpha: 0.6,
          );

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: Colors.transparent, // Expand tap area
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SvgPicture.asset(
          svgAssetPath,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          width: isSelected ? 26 : 22,
          height: isSelected ? 26 : 22,
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ReaderSessionsScreen();
      case 2:
        return const FMRadioScreen();
      case 3:
        return const ReelsFeedPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
