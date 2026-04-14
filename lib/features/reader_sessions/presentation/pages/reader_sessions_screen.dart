import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/reader_sessions_provider.dart';
import '../widgets/active_users_bar.dart';
import '../widgets/post_card.dart';
import 'reader_post_detail_screen.dart';

class ReaderSessionsScreen extends StatefulWidget {
  const ReaderSessionsScreen({super.key});

  @override
  State<ReaderSessionsScreen> createState() => _ReaderSessionsScreenState();
}

class _ReaderSessionsScreenState extends State<ReaderSessionsScreen> {
  bool _isFabVisible = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderSessionsProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090806),
        floatingActionButton: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isFabVisible ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.readerCreatePost);
                },
                backgroundColor: const Color(0xFFD9AF68),
                foregroundColor: Colors.black,
                label: const Text(
                  'منشور جديد',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                icon: const Icon(Icons.edit_rounded),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            const _FeedBackdrop(),
            SafeArea(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : NotificationListener<UserScrollNotification>(
                      onNotification: (notification) {
                        if (notification.direction == ScrollDirection.idle) {
                          if (!_isFabVisible) {
                            setState(() => _isFabVisible = true);
                          }
                        } else {
                          if (_isFabVisible) {
                            setState(() => _isFabVisible = false);
                          }
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                              child: _FeedHeader(provider: provider),
                            ),
                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.provider});

  final ReaderSessionsProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مجلس القراء',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'شبكة اجتماعية هادئة للقراء: اقتباسات، مراجعات، وأسئلة تفتح حوارات حقيقية حول الكتب.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.66),
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF17130E),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Color(0xFFD9AF68),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFF14110D),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              ActiveUsersBar(
                readers: provider.activeReaders,
                overflowCount: provider.activeReadersOverflow,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      value: '${provider.posts.length}',
                      label: 'منشوراً اليوم',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      value: '${provider.activeReaders.length}+',
                      label: 'قارئاً نشطاً',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _StatChip(value: '3', label: 'أنواع منشورات'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFFD9AF68),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 12,
            ),
          ),
        ],
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
