import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/audio_category.dart';

class CategoryCard extends StatelessWidget {
  final AudioCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 100,
        margin: const EdgeInsets.symmetric(vertical: 8), // For shadow breathing room
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primary.withOpacity(0.15) 
              : AppTheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 2,
              )
            else
              const BoxShadow(
                color: Colors.transparent,
                blurRadius: 0,
                spreadRadius: 0,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: isSelected ? AppTheme.primary : Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                category.id, // e.g. "Stories" in english
                style: TextStyle(
                  color: AppTheme.primary.withOpacity(0.8),
                  fontSize: 10,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
