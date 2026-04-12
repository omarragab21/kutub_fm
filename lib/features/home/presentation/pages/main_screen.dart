import 'package:flutter/material.dart';
import 'package:kutub_fm/features/profile/presentation/pages/profile_screen.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF353534).withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(theme, Icons.auto_stories, 'المكتبة', index: 0),
          _buildNavItem(theme, Icons.play_circle, 'استمع', index: 1),
          _buildNavItem(theme, Icons.radio, 'راديو', index: 2),
          _buildNavItem(theme, Icons.person, 'الملف', index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    ThemeData theme,
    IconData icon,
    String label, {
    required int index,
  }) {
    final isSelected =
        context.watch<AppNavigationState>().selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
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
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
