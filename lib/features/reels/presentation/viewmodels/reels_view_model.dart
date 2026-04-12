import 'package:flutter/material.dart';
import '../../domain/entities/reel_model.dart';

class ReelsViewModel extends ChangeNotifier {
  List<Reel> _reels = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  List<Reel> get reels => _reels;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;

  ReelsViewModel() {
    loadReels();
  }

  Future<void> loadReels() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    _reels = List.generate(10, (index) => Reel.mock(index));
    
    _isLoading = false;
    notifyListeners();
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void likeReel(String id) {
    // Implement like logic
    notifyListeners();
  }

  void shareReel(String id) {
    // Implement share logic
    notifyListeners();
  }
}
