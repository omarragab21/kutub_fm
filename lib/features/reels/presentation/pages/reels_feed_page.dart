import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/reels_view_model.dart';
import '../widgets/reel_item_widget.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:kutub_fm/core/navigation/app_bottom_nav_tab.dart';
import 'package:kutub_fm/core/navigation/app_navigation_state.dart';

class ReelsFeedPage extends StatelessWidget {
  final String? category;
  final String? initialReelId;

  const ReelsFeedPage({super.key, this.category, this.initialReelId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReelsViewModel(category: category, initialReelId: initialReelId),
      child: const _ReelsFeedView(),
    );
  }
}

class _ReelsFeedView extends StatelessWidget {
  const _ReelsFeedView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReelsViewModel>();
    final navState = context.watch<AppNavigationState>();
    final isReelsTabActive = navState.selectedTab == AppBottomNavTab.reels;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<ReelsViewModel>().setPageActive(isReelsTabActive);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // Feed
            if (viewModel.isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            else if (viewModel.reels.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.category != null
                            ? 'لا توجد مقاطع ريلز في تصنيف "${viewModel.category}" حالياً'
                            : 'لا توجد مقاطع ريلز حالياً',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تابعنا لإضافة مقاطع جديدة قريباً',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      if (viewModel.category != null) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: viewModel.clearCategoryFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          icon: const Icon(Icons.explore_outlined, size: 18),
                          label: const Text(
                            'استكشف كل الريلز',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              PageView.builder(
                controller: viewModel.pageController,
                scrollDirection: Axis.vertical,
                itemCount: viewModel.reels.length,
                onPageChanged: viewModel.onPageChanged,
                itemBuilder: (context, index) {
                  return ReelItemWidget(
                    reel: viewModel.reels[index],
                    isVisible: viewModel.currentIndex == index,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

