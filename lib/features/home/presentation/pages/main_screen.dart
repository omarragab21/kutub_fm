import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kutub_fm/core/layout/widgets/app_bottom_navigation_bar.dart';
import 'package:kutub_fm/core/navigation/app_bottom_nav_tab.dart';
import 'package:kutub_fm/core/navigation/app_navigation_state.dart';
import 'package:kutub_fm/features/home/presentation/pages/book_world_screen.dart';
import 'package:kutub_fm/features/home/presentation/viewmodels/home_view_model.dart';

import '../../../community/presentation/pages/community_screen.dart';
import '../../../radio/presentation/pages/fm_radio_screen.dart';
import '../../../reels/presentation/pages/reels_feed_page.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const AppBottomNavTab initialTab = AppBottomNavTab.home;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppNavigationState>().setSelectedTab(MainScreen.initialTab);
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
    final navigationState = context.watch<AppNavigationState>();
    final selectedIndex = navigationState.selectedTabIndex;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content
          _buildPage(selectedIndex),

          // Custom Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: const AppBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    return IndexedStack(
      index: index,
      children: const [
        CommunityScreen(),
        FMRadioScreen(),
        HomeScreen(),
        BookWorldScreen(),
        ReelsFeedPage(),
      ],
    );
  }
}
