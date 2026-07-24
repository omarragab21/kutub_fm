import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

            // Upload camera icon
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _onCameraTapped(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCameraTapped(BuildContext context) async {
    final source = await _showUploadSourceSheet(context);
    if (source == null || !context.mounted) return;

    final viewModel = context.read<ReelsViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final error = await viewModel.pickAndUploadVideo(source);

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'تم رفع الفيديو بنجاح',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  Future<ImageSource?> _showUploadSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    'تصوير فيديو',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    'اختيار من المعرض',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

