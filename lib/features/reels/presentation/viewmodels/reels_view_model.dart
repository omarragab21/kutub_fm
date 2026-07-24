import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/reel_model.dart';

class ReelsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _category;
  final String? initialReelId;
  List<Reel> _reels = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _reelsSubscription;
  bool _isPageActive = false;
  bool _isUploading = false;
  String? _uploadError;

  bool get isPageActive => _isPageActive;
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;

  void setPageActive(bool active) {
    if (_isPageActive == active) return;
    _isPageActive = active;
    if (_isPageActive) {
      _controllers[_currentIndex]?.play();
    } else {
      _controllers[_currentIndex]?.pause();
    }
    notifyListeners();
  }
  PageController? _pageController;

  /// Cache of pre-warmed VideoPlayerControllers keyed by reel index.
  /// We keep a window of [current-1, current, current+1].
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> _initialized = {};

  List<Reel> get reels => _reels;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get category => _category;

  PageController get pageController {
    _pageController ??= PageController(initialPage: _currentIndex);
    return _pageController!;
  }

  ReelsViewModel({String? category, this.initialReelId}) : _category = category {
    loadReels();
  }

  // ─── Public API for widgets ────────────────────────────────────────────────

  /// Returns the controller for [index] if it has been initialized.
  VideoPlayerController? controllerAt(int index) => _controllers[index];

  /// Whether the controller at [index] has finished initializing.
  bool isInitializedAt(int index) => _initialized[index] ?? false;

  // ─── Loading ───────────────────────────────────────────────────────────────

  Future<void> loadReels() async {
    _isLoading = true;
    _currentIndex = 0;
    notifyListeners();

    _disposeAllControllers();
    await _reelsSubscription?.cancel();

    try {
      final query = _firestore.collection('reels').orderBy('createdAt', descending: true);

      _reelsSubscription = query.snapshots().listen((querySnapshot) {
        List<Reel> fetched = [];
        if (querySnapshot.docs.isNotEmpty) {
          fetched = querySnapshot.docs.map((doc) {
            return Reel.fromFirestore(
              doc.id,
              doc.data(),
            );
          }).toList();
        } else {
          fetched = Reel.defaultReelsList;
        }

        if (_category != null && _category!.isNotEmpty) {
          fetched = fetched
              .where(
                (r) =>
                    r.categoryName.isEmpty ||
                    r.categoryName == _category ||
                    _category == 'الكل',
              )
              .toList();
        }

        _reels = fetched.isNotEmpty ? fetched : Reel.defaultReelsList;

        if (initialReelId != null) {
          final index = _reels.indexWhere((r) => r.id == initialReelId);
          if (index != -1) {
            _currentIndex = index;
          }
        }
        _isLoading = false;
        notifyListeners();

        _warmUpWindow(_currentIndex);
      }, onError: (e) {
        debugPrint('Error loading reels stream: $e');
        _reels = Reel.defaultReelsList;
        _isLoading = false;
        notifyListeners();
        _warmUpWindow(_currentIndex);
      });
    } catch (e) {
      debugPrint('Error establishing reels stream: $e');
      _reels = Reel.defaultReelsList;
      _isLoading = false;
      notifyListeners();
      _warmUpWindow(_currentIndex);
    }
  }

  void clearCategoryFilter() {
    _category = null;
    loadReels();
  }

  // ─── Page change ──────────────────────────────────────────────────────────

  void onPageChanged(int index) {
    final previous = _currentIndex;
    _currentIndex = index;

    // Play current, pause previous
    _controllers[index]?.play();
    _controllers[previous]?.pause();

    // Pre-warm neighbors
    _warmUpWindow(index);

    // Evict controllers that are now too far away (index <= current-2)
    _evictDistant(index);

    notifyListeners();
  }

  // ─── Controller lifecycle ─────────────────────────────────────────────────

  /// Ensure controllers exist for [center-1, center, center+1].
  void _warmUpWindow(int center) {
    for (int i = center - 1; i <= center + 1; i++) {
      if (i < 0 || i >= _reels.length) continue;
      if (_controllers.containsKey(i)) continue; // already warming or ready
      _initControllerAt(i);
    }
  }

  void _initControllerAt(int index) {
    final reel = _reels[index];
    final videoUrl = reel.videoUrl;

    final controller = videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        : VideoPlayerController.asset(videoUrl);

    _controllers[index] = controller;
    _initialized[index] = false;

    controller.initialize().then((_) {
      if (!_controllers.containsKey(index)) return; // evicted while loading
      controller.setLooping(true);
      _initialized[index] = true;

      // Auto-play if this turned out to be the current index and tab is active
      if (index == _currentIndex && _isPageActive) {
        controller.play();
      }
      notifyListeners();
    }).catchError((e) {
      debugPrint('Error initializing controller[$index]: $e');
    });
  }

  /// Dispose controllers for indices that are more than 1 away from [current].
  void _evictDistant(int current) {
    final toEvict =
        _controllers.keys.where((i) => (i - current).abs() > 1).toList();
    for (final i in toEvict) {
      _controllers[i]?.dispose();
      _controllers.remove(i);
      _initialized.remove(i);
    }
  }

  void _disposeAllControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _initialized.clear();
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _reelsSubscription?.cancel();
    _disposeAllControllers();
    _pageController?.dispose();
    super.dispose();
  }

  // ─── Reel upload ──────────────────────────────────────────────────────────

  Future<String?> pickAndUploadVideo(ImageSource source) async {
    if (_isUploading) return 'جاري رفع فيديو آخر حالياً';
    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    String? result;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 20),
      );

      if (picked == null) {
        _isUploading = false;
        notifyListeners();
        return null;
      }

      final file = File(picked.path);
      final controller = VideoPlayerController.file(file);
      try {
        await controller.initialize();
        final duration = controller.value.duration;
        if (duration > const Duration(seconds: 20)) {
          result = 'مدة الفيديو تتجاوز 20 ثانية. الرجاء اختيار مقطع أقصر.';
          _isUploading = false;
          notifyListeners();
          return result;
        }
      } catch (e) {
        result = 'تعذر قراءة معلومات الفيديو.';
        _isUploading = false;
        notifyListeners();
        return result;
      } finally {
        await controller.dispose();
      }

      final fileName = picked.path.split('/').last;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_reels/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final uploadTask = await storageRef.putFile(file);
      final videoUrl = await uploadTask.ref.getDownloadURL();

      final user = FirebaseAuth.instance.currentUser;
      await _firestore.collection('reels').add({
        'videoUrl': videoUrl,
        'imageUrl': '',
        'bookTitle': 'فيديو من المستخدم',
        'author': user?.displayName ?? user?.email ?? 'مستخدم كتب FM',
        'quote': '',
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'createdAt': FieldValue.serverTimestamp(),
        if (user != null) 'createdBy': user.uid,
      });

      result = null;
    } catch (e) {
      debugPrint('Error uploading reel: $e');
      result = 'حدث خطأ أثناء رفع الفيديو: $e';
    } finally {
      _isUploading = false;
      _uploadError = result;
      notifyListeners();
    }
    return result;
  }

  // ─── Unused stubs ─────────────────────────────────────────────────────────

  void likeReel(String id) => notifyListeners();
  void shareReel(String id) => notifyListeners();
}
