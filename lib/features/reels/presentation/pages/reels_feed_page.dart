import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/reels_view_model.dart';
import '../widgets/reel_item_widget.dart';
import '../../../../core/theme/app_theme.dart';

class ReelsFeedPage extends StatelessWidget {
  final String? category;

  const ReelsFeedPage({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReelsViewModel(category: category),
      child: const _ReelsFeedView(),
    );
  }
}

class _ReelsFeedView extends StatelessWidget {
  const _ReelsFeedView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReelsViewModel>();

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

            // Top App Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 20,
                  right: 20,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.primary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.category != null ? 'ريلز - ${viewModel.category}' : 'ريلز الكتب',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

