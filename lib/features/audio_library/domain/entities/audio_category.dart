import 'package:flutter/material.dart';

class AudioCategory {
  final String id;
  final String name;
  final IconData icon;

  const AudioCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  static List<AudioCategory> get mockCategories => const [
        AudioCategory(id: 'stories', name: 'روايات', icon: Icons.menu_book),
        AudioCategory(id: 'business', name: 'أعمال', icon: Icons.business),
        AudioCategory(id: 'history', name: 'تاريخ', icon: Icons.account_balance),
        AudioCategory(id: 'self_dev', name: 'تطوير الذات', icon: Icons.psychology),
        AudioCategory(id: 'kids', name: 'أطفال', icon: Icons.child_care),
      ];
}
