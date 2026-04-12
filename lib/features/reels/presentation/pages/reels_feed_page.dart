import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/reels_view_model.dart';
import '../widgets/reel_item_widget.dart';
import '../../../../core/theme/app_theme.dart';

class ReelsFeedPage extends StatelessWidget {
  const ReelsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReelsViewModel(),
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
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
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
                    const Text(
                      'ريلز الكتب',
                      style: TextStyle(
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
