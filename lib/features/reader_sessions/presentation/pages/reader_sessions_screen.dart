import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/reader_sessions_provider.dart';
import '../widgets/post_card.dart';
import 'reader_post_detail_screen.dart';

class ReaderSessionsScreen extends StatefulWidget {
  const ReaderSessionsScreen({super.key});

  @override
  State<ReaderSessionsScreen> createState() => _ReaderSessionsScreenState();
}

class _ReaderSessionsScreenState extends State<ReaderSessionsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderSessionsProvider>();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090806),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text(
            'المجتمع',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            if (Navigator.canPop(context))
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            const _FeedBackdrop(),
            SafeArea(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Search Field
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14110D),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ابحث في المجتمع',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.search,
                                        color: Color(0xFFD9AF68),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // 2. Create Post inline Card
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14110D),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'انشر للعالم ما يلهمك...',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).pushNamed(AppRoutes.readerCreatePost);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFD9AF68),
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                            ),
                                            icon: const Icon(Icons.edit_rounded, size: 16),
                                            label: const Text(
                                              'إنشاء منشور',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // 3. Section Header
                                Text(
                                  'أحدث المنشورات',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (provider.posts.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 80,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.forum_outlined,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'لا توجد منشورات اليوم',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'لا توجد منشورات خالص حالياً في مجلس القراء.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                            sliver: SliverList.separated(
                              itemCount: provider.posts.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final post = provider.posts[index];
                                return _Reveal(
                                  delay: Duration(milliseconds: 40 * index),
                                  child: PostCard(
                                    post: post,
                                    timestampLabel: provider.formatTimestamp(
                                      post.createdAt,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.readerPostDetail,
                                        arguments: ReaderPostDetailArgs(
                                          postId: post.id,
                                        ),
                                      );
                                    },
                                    onLikeTap: () =>
                                        provider.toggleLike(post.id),
                                    onCommentTap: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.readerPostDetail,
                                        arguments: ReaderPostDetailArgs(
                                          postId: post.id,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedBackdrop extends StatelessWidget {
  const _FeedBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -40,
          child: _GlowOrb(
            size: 280,
            color: const Color(0xFFD9AF68).withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          top: 260,
          left: -60,
          child: _GlowOrb(
            size: 220,
            color: const Color(0xFF7B8D62).withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.05),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 260),
        child: widget.child,
      ),
    );
  }
}
