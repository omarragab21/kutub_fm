import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/reel_model.dart';

class ReelsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _category;
  List<Reel> _reels = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _reelsSubscription;

  /// Cache of pre-warmed VideoPlayerControllers keyed by reel index.
  /// We keep a window of [current-1, current, current+1].
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> _initialized = {};

  List<Reel> get reels => _reels;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get category => _category;

  ReelsViewModel({String? category}) : _category = category {
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

    // Dispose all existing controllers when list refreshes
    _disposeAllControllers();

    await _reelsSubscription?.cancel();

    try {
      Query query =
          _firestore.collection('reels').orderBy('createdAt', descending: true);

      if (_category != null && _category!.isNotEmpty) {
        query = query.where('categoryName', isEqualTo: _category);
      }

      _reelsSubscription = query.snapshots().listen((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          _reels = querySnapshot.docs.map((doc) {
            return Reel.fromFirestore(
                doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
        } else {
          _reels = [];
        }
        _isLoading = false;
        notifyListeners();

        // Warm up the first two reels after the list arrives
        _warmUpWindow(_currentIndex);
      }, onError: (e) {
        debugPrint('Error loading reels stream: $e');
        _reels = [];
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error establishing reels stream: $e');
      _reels = [];
      _isLoading = false;
      notifyListeners();
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

      // Auto-play if this turned out to be the current index
      if (index == _currentIndex) {
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
    super.dispose();
  }

  // ─── Unused stubs ─────────────────────────────────────────────────────────

  void likeReel(String id) => notifyListeners();
  void shareReel(String id) => notifyListeners();
}
