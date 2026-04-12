import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/reel_model.dart';
import 'reels_action_button.dart';
import 'waveform_widget.dart';
import '../../../../core/theme/app_theme.dart';

class ReelItemWidget extends StatefulWidget {
  final Reel reel;
  final bool isVisible;

  const ReelItemWidget({
    super.key,
    required this.reel,
    this.isVisible = false,
  });

  @override
  State<ReelItemWidget> createState() => _ReelItemWidgetState();
}

class _ReelItemWidgetState extends State<ReelItemWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.reel.videoUrl;
    if (videoUrl.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    } else {
      _controller = VideoPlayerController.asset(videoUrl);
    }
    
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _initialized = true;
          if (widget.isVisible) {
            _controller.play();
            _controller.setLooping(true);
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(ReelItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.play();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCommentsBottomSheet() {
    _controller.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF131313),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'التعليقات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: 5,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final mockComments = [
                      {'name': 'أحمد علي', 'comment': 'الكتاب رائع جداً، أنصح الجميع بقراءته والاستماع إليه.', 'time': 'منذ ساعتين'},
                      {'name': 'سارة محمد', 'comment': 'الاقتباس جميل ويمس القلب.', 'time': 'منذ 5 ساعات'},
                      {'name': 'يوسف خالد', 'comment': 'هل يوجد جزء ثاني؟', 'time': 'منذ يوم'},
                      {'name': 'منى حسن', 'comment': 'أحببت طريقة السرد.', 'time': 'منذ يومين'},
                      {'name': 'عمر أحمد', 'comment': 'شكراً على هذا المقطع المميز!', 'time': 'منذ أسبوع'},
                    ];
                    final comment = mockComments[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=${index + 10}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment['name']!,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    comment['time']!,
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment['comment']!,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.favorite_border, color: Colors.white54, size: 16),
                          onPressed: () {},
                        )
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 8,
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'أضف تعليقاً...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white10,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primary.withAlpha(25),
                        ),
                        icon: const Icon(Icons.send, color: AppTheme.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (widget.isVisible && mounted) {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        if (_initialized) {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video / Image Background
          if (_initialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Image.network(
              widget.reel.imageUrl,
              fit: BoxFit.cover,
            ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Play Icon Overlay when paused
          if (_initialized && !_controller.value.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),

        // Content
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left Actions (for RTL feel, we place them on the left)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ReelsActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                    label: '${widget.reel.likes + (_isLiked ? 1 : 0)}',
                    onTap: () {
                      setState(() {
                        _isLiked = !_isLiked;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ReelsActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${widget.reel.comments}',
                    onTap: _showCommentsBottomSheet,
                  ),
                  const SizedBox(height: 24),
                  ReelsActionButton(
                    icon: Icons.share,
                    label: 'ارسال',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  ReelsActionButton(
                    icon: Icons.bookmark,
                    label: 'حفظ',
                    onTap: () {},
                  ),
                  const SizedBox(height: 80), // Offset from bottom
                ],
              ),
              const Spacer(),
              // Right Info
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.graphic_eq, color: AppTheme.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'استمع الآن',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.reel.bookTitle,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            color: AppTheme.primary,
                          ),
                    ),
                    Text(
                      widget.reel.author,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(right: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: AppTheme.primary, width: 2),
                        ),
                      ),
                      child: Text(
                        widget.reel.quote,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const WaveformWidget(color: AppTheme.primary),
                    const SizedBox(height: 60), // Space for system nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}
