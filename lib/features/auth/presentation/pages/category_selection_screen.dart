import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';

class CategoryItem {
  final String id;
  final String title;
  final IconData icon;
  final String? bookCount;
  final bool isLarge;

  CategoryItem({
    required this.id,
    required this.title,
    required this.icon,
    this.bookCount,
    this.isLarge = false,
  });
}

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final Set<String> _selectedCategoryIds = {};

  final List<CategoryItem> _categories = [
    CategoryItem(id: 'novels', title: 'روايات', icon: Icons.auto_stories),
    CategoryItem(id: 'self_improvement', title: 'تطوير الذات', icon: Icons.psychology_alt),
    CategoryItem(id: 'history', title: 'تاريخ', icon: Icons.history_edu),
    CategoryItem(id: 'podcasts', title: 'بودكاست', icon: Icons.podcasts),
    CategoryItem(
      id: 'business',
      title: 'أعمال واقتصاد',
      icon: Icons.trending_up,
      bookCount: '142 كتاب متاح',
      isLarge: true,
    ),
    CategoryItem(id: 'philosophy', title: 'فلسفة', icon: Icons.menu_book), // Fallback for temp_preferences_custom
    CategoryItem(id: 'religion', title: 'دين', icon: Icons.mosque),
    CategoryItem(id: 'radio', title: 'إذاعات مباشرة', icon: Icons.radio),
    CategoryItem(id: 'poetry', title: 'شعر', icon: Icons.create), // Fallback for ink_pen
    CategoryItem(id: 'science', title: 'علوم', icon: Icons.science),
    CategoryItem(id: 'kids', title: 'أطفال', icon: Icons.child_care),
  ];

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: GridPainter(color: theme.colorScheme.primary),
              ),
            ),
          ),
          
          // Content
          CustomScrollView(
            slivers: [
              // Sticky App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.colorScheme.background.withValues(alpha: 0.6),
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'كتب FM',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 24,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary,
                                    boxShadow: [
                                      BoxShadow(color: theme.colorScheme.primary, blurRadius: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'اختر اهتماماتك',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 36,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ساعدنا نخصص تجربتك حسب ذوقك لنقدم لك أفضل ما في عالم المعرفة',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Bento Grid
                    _buildBentoGrid(theme),
                    
                    const SizedBox(height: 48),
                    
                    // Decorative Element
                    Container(
                      height: 192,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDN5HITfoUosvbHw1AQ8y4RRGDNXaF2TGC14-O6QbzHyKv9eThscCrhmOoY5VTrlXGGBXOhPhe5FyBmo5wqzq5LJ0Dyfu5J8u9sZKMX2j0eumz_Fn3p46RYtTQ76l9j04X87efUomtmmN7KDK65NVi8hcEJ17WgU4yp4NT2u8L7_0BoprEo2u7TKR4q1Bvc6qaoBVzgCxvwiUigLpJffrJpvLYu0jCvvol_PWge9ODU_pakMcETXgUifR8eENWhhsKYBOyel6wB_lU',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              opacity: const AlwaysStoppedAnimation(0.6),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    theme.colorScheme.background,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'انضم إلى مجتمعنا',
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontSize: 20,
                                      fontStyle: FontStyle.italic,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'أكثر من مليون قارئ ومستمع',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          
          // Fixed Bottom Actions
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.background.withValues(alpha: 0),
                    theme.colorScheme.background,
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Finalize selection logic
                          Navigator.pushReplacementNamed(context, AppRoutes.home);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 8,
                          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        child: const Text('متابعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تخطي الآن',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_back, size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(ThemeData theme) {
    // Manually building the grid to achieve the bento effect from top to bottom
    List<Widget> rows = [];
    
    // Row 1: 2 Small Items
    rows.add(Row(
      children: [
        Expanded(child: _buildCategoryCard(theme, _categories[0])),
        const SizedBox(width: 12),
        Expanded(child: _buildCategoryCard(theme, _categories[1])),
      ],
    ));
    rows.add(const SizedBox(height: 12));
    
    // Row 2: 2 Small Items
    rows.add(Row(
      children: [
        Expanded(child: _buildCategoryCard(theme, _categories[2])),
        const SizedBox(width: 12),
        Expanded(child: _buildCategoryCard(theme, _categories[3])),
      ],
    ));
    rows.add(const SizedBox(height: 12));
    
    // Row 3: 1 Large Item
    rows.add(_buildLargeCategoryCard(theme, _categories[4]));
    rows.add(const SizedBox(height: 12));
    
    // Remaining items in 2-column grid
    for (int i = 5; i < _categories.length; i += 2) {
      if (i + 1 < _categories.length) {
        rows.add(Row(
          children: [
            Expanded(child: _buildCategoryCard(theme, _categories[i])),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard(theme, _categories[i+1])),
          ],
        ));
      } else {
        rows.add(Row(
          children: [
            Expanded(child: _buildCategoryCard(theme, _categories[i])),
            const Expanded(child: SizedBox()),
          ],
        ));
      }
      rows.add(const SizedBox(height: 12));
    }
    
    return Column(children: rows);
  }

  Widget _buildCategoryCard(ThemeData theme, CategoryItem category) {
    final isSelected = _selectedCategoryIds.contains(category.id);
    
    return GestureDetector(
      onTap: () => _toggleCategory(category.id),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF353534).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 32)] : null,
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      category.icon,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    category.title,
                    style: TextStyle(
                      color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
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

  Widget _buildLargeCategoryCard(ThemeData theme, CategoryItem category) {
    final isSelected = _selectedCategoryIds.contains(category.id);
    
    return GestureDetector(
      onTap: () => _toggleCategory(category.id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF353534).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    category.icon,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (category.bookCount != null)
                      Text(
                        category.bookCount!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 10,
                          letterSpacing: -0.5,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Icon(Icons.chevron_left, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 32) {
      for (double j = 0; j < size.height; j += 32) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
