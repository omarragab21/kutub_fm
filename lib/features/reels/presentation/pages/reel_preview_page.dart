import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_theme.dart';
import 'reels_feed_page.dart';

class ReelPreviewArgs {
  final String videoPath;
  final String sentenceText;
  final String start;
  final String end;
  final String audioUrl;
  final String coverUrl;
  final String logoUrl;
  final String downloadUrl;
  final String type;
  final String bookTitle;
  final String author;

  const ReelPreviewArgs({
    required this.videoPath,
    required this.sentenceText,
    required this.start,
    required this.end,
    required this.audioUrl,
    required this.coverUrl,
    required this.logoUrl,
    required this.downloadUrl,
    required this.type,
    this.bookTitle = '',
    this.author = '',
  });
}

class ReelPreviewPage extends StatefulWidget {
  final ReelPreviewArgs args;

  const ReelPreviewPage({
    super.key,
    required this.args,
  });

  @override
  State<ReelPreviewPage> createState() => _ReelPreviewPageState();
}

class _ReelPreviewPageState extends State<ReelPreviewPage> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _hasSavedToCreations = false;
  bool _isSavingToCreations = false;
  bool _isSavingToGallery = false;
  bool _showPlayOverlay = false;
  bool _isPublishing = false;
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.args.bookTitle);
    _descController = TextEditingController(text: widget.args.sentenceText);
    _initializePlayer();
    _checkIfSavedInCreations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveToGallery();
    });
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.args.videoPath));
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      log('Error initializing video player in ReelPreviewPage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تشغيل مقطع الفيديو: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _checkIfSavedInCreations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('user_creations')
          .where('userId', isEqualTo: user.uid)
          .where('downloadUrl', isEqualTo: widget.args.downloadUrl)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty && mounted) {
        setState(() {
          _hasSavedToCreations = true;
        });
      }
    } catch (e) {
      log('Error checking creations status: $e');
    }
  }

  Future<void> _shareReel() async {
    HapticFeedback.mediumImpact();
    try {
      final file = File(widget.args.videoPath);
      if (!await file.exists()) {
        throw Exception('ملف الفيديو غير موجود محلياً لمشاركته.');
      }
      
      final textShare = 'شاهد هذا الاقتباس الصوتي المميز من تطبيق كتب FM:\n"${widget.args.sentenceText}"';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.args.videoPath)],
          text: textShare,
          subject: 'مشاركة ريل كتب FM',
        ),
      );
    } catch (e) {
      log('Error sharing file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء مشاركة الفيديو: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    HapticFeedback.mediumImpact();
    if (_isSavingToGallery) return;

    setState(() {
      _isSavingToGallery = true;
    });

    try {
      // Request permission and save
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final request = await Gal.requestAccess(toAlbum: true);
        if (!request) {
          throw Exception('تم رفض صلاحيات الوصول إلى معرض الصور.');
        }
      }

      await Gal.putVideo(widget.args.videoPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ مقطع الريل بنجاح في الاستوديو! 🎥✨'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      log('Error saving to gallery: $e');
      if (mounted) {
        String friendlyError = 'تعذر حفظ الفيديو في الاستوديو.';
        if (e.toString().contains('denied')) {
          friendlyError = 'يرجى تفعيل صلاحيات الاستوديو من إعدادات الهاتف لحفظ الفيديو.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$friendlyError ($e)'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToGallery = false;
        });
      }
    }
  }

  Future<void> _addToCreations() async {
    HapticFeedback.mediumImpact();
    if (_hasSavedToCreations || _isSavingToCreations) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً لإضافة المقطع إلى إبداعاتك.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _isSavingToCreations = true;
    });

    try {
      final docData = {
        'userId': user.uid,
        'type': widget.args.type,
        'source': 'audio_sentence',
        'sentenceText': widget.args.sentenceText,
        'audioUrl': widget.args.audioUrl,
        'coverUrl': widget.args.coverUrl,
        'logoUrl': widget.args.logoUrl,
        'start': widget.args.start,
        'end': widget.args.end,
        'localVideoPath': widget.args.videoPath,
        'downloadUrl': widget.args.downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('user_creations').add(docData);

      if (mounted) {
        setState(() {
          _hasSavedToCreations = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المقطع إلى إبداعاتك بنجاح! ⭐📁'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      log('Error saving creation log to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ المقطع في إبداعاتك: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToCreations = false;
        });
      }
    }
  }

  Future<void> _publishAsReel() async {
    HapticFeedback.mediumImpact();
    
    // Pause video player during publishing input
    if (_isInitialized && _videoController.value.isPlaying) {
      _videoController.pause();
      setState(() {
        _showPlayOverlay = true;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  left: 24,
                  right: 24,
                  top: 16,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Icon(
                          Icons.publish_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'نشر كـ مقطع ريلز',
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title input field
                    const Text(
                      'عنوان مقطع الريل (اسم الكتاب):',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.amiri(color: Colors.white, fontSize: 16),
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        hintText: 'أدخل عنوان الكتاب...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description input field
                    const Text(
                      'الوصف / الاقتباس:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      style: GoogleFonts.amiri(color: Colors.white, fontSize: 16, height: 1.4),
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        hintText: 'أكتب اقتباساً أو وصفاً للمقطع...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Publish Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isPublishing
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);

                                final title = _titleController.text.trim();
                                final desc = _descController.text.trim();
                                if (title.isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('عنوان مقطع الريل مطلوب.'),
                                      backgroundColor: Colors.amber,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  _isPublishing = true;
                                });

                                try {
                                  final docData = {
                                    'bookTitle': title,
                                    'author': widget.args.author.isNotEmpty
                                        ? widget.args.author
                                        : 'كاتب كتب FM',
                                    'quote': desc,
                                    'imageUrl': widget.args.coverUrl,
                                    'videoUrl': widget.args.downloadUrl,
                                    'likes': 0,
                                    'comments': 0,
                                    'shares': 0,
                                    'categoryName': widget.args.type == 'quote'
                                        ? 'اقتباس'
                                        : widget.args.type == 'philosophy'
                                            ? 'فلسفة'
                                            : 'قراءة',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };

                                  await FirebaseFirestore.instance
                                      .collection('reels')
                                      .add(docData);

                                  if (mounted) {
                                    // Close modal sheet
                                    navigator.pop();
                                    
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('تم نشر مقطع الريل بنجاح! 🚀🎬'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // Pop back to home (root) and push the Reels feed
                                    navigator.popUntil((route) => route.isFirst);
                                    navigator.push(
                                      MaterialPageRoute(builder: (context) => const ReelsFeedPage()),
                                    );
                                  }
                                } catch (e) {
                                  log('Error publishing reel: $e');
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('فشل نشر مقطع الريل: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } finally {
                                  setModalState(() {
                                    _isPublishing = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isPublishing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'نشر الآن',
                                style: GoogleFonts.amiri(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Resume playing if closed without publishing and video is not playing
      if (mounted && _isInitialized && !_videoController.value.isPlaying && !_isPublishing) {
        _videoController.play();
        setState(() {
          _showPlayOverlay = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
        _showPlayOverlay = true;
      } else {
        _videoController.play();
        _showPlayOverlay = false;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    if (_isInitialized) {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── VIDEO PLAYER BACKGROUND ──────────────────────────────────────
            GestureDetector(
              onTap: _togglePlayPause,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isInitialized)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),

                  // Muted play overlay icon
                  if (_showPlayOverlay)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── TOP GRADIENT OVERLAY & CLOSE BUTTON ──────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 20,
                  right: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'معاينة مقطع الريل',
                      style: GoogleFonts.amiri(
                        color: AppTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to balance close button
                  ],
                ),
              ),
            ),

            // ── BOTTOM INFO & CONTROLS OVERLAY ──────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 24,
                  right: 24,
                  top: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sentence Text Quote block
                    Container(
                      padding: const EdgeInsets.only(right: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: AppTheme.primary, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.args.sentenceText,
                            style: GoogleFonts.amiri(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  widget.args.type == 'quote'
                                      ? 'اقتباس'
                                      : widget.args.type == 'philosophy'
                                          ? 'فلسفة'
                                          : 'قراءة',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.timer_outlined,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.args.start} - ${widget.args.end}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Primary Publish button
                    _buildActionButton(
                      icon: Icons.publish_rounded,
                      label: 'نشر كـ مقطع ريلز',
                      onTap: _publishAsReel,
                      isLoading: _isPublishing,
                      isSecondary: false,
                    ),
                    const SizedBox(height: 12),

                    // Actions Row (Share, Save to Gallery)
                    Row(
                      children: [
                        // Share Button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.share_rounded,
                            label: 'مشاركة المقطع',
                            onTap: _shareReel,
                            isLoading: false,
                            isSecondary: true,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Save to Gallery Button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.save_alt_rounded,
                            label: 'حفظ في المعرض',
                            onTap: _saveToGallery,
                            isLoading: _isSavingToGallery,
                            isSecondary: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Creations Button (Full width, secondary style)
                    _buildActionButton(
                      icon: _hasSavedToCreations ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                      label: _hasSavedToCreations ? 'تمت الإضافة إلى إبداعاتي' : 'إضافة إلى إبداعاتي',
                      onTap: _addToCreations,
                      isLoading: _isSavingToCreations,
                      isSecondary: true,
                      isCompleted: _hasSavedToCreations,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isLoading,
    required bool isSecondary,
    bool isCompleted = false,
  }) {
    final themeColor = isCompleted ? Colors.green : AppTheme.primary;
    final contentColor = isSecondary 
        ? Colors.white 
        : (isCompleted ? Colors.white : Colors.black);

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (isLoading || isCompleted) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary 
              ? Colors.white.withValues(alpha: 0.15) 
              : themeColor,
          foregroundColor: contentColor,
          disabledBackgroundColor: isCompleted 
              ? Colors.green.withValues(alpha: 0.7) 
              : Colors.white.withValues(alpha: 0.08),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSecondary 
                ? BorderSide(color: Colors.white.withValues(alpha: 0.25)) 
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: contentColor,
                ),
              )
            : Icon(icon, size: 20, color: contentColor),
        label: Text(
          label,
          style: GoogleFonts.amiri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
