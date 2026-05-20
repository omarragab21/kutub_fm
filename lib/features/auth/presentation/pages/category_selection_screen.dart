import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/viewmodels/home_view_model.dart';

class CategoryItem {
  final String id;
  final String title;
  final String? iconUrl;
  final String? imageUrl;
  final String? bookCount;
  final IconData fallbackIcon;
  final bool isLarge;

  CategoryItem({
    required this.id,
    required this.title,
    this.iconUrl,
    this.imageUrl,
    this.bookCount,
    required this.fallbackIcon,
    this.isLarge = false,
  });

  factory CategoryItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final title = _stringField(data, const [
      'name',
      'title',
      'nameAr',
      'arabicName',
    ], fallback: document.id);

    return CategoryItem(
      id: document.id,
      title: title,
      iconUrl: _nullableStringField(data, const ['icon', 'iconUrl']),
      imageUrl: _nullableStringField(data, const ['image', 'imageUrl']),
      bookCount: _bookCountLabel(data['bookCount']),
      fallbackIcon: _fallbackIconFor(document.id, title),
      isLarge: data['isLarge'] == true,
    );
  }

  static String _stringField(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static String? _nullableStringField(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static String? _bookCountLabel(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return '${value.toInt()} كتاب متاح';
    return null;
  }

  static IconData _fallbackIconFor(String id, String title) {
    final source = '$id $title'.toLowerCase();
    if (source.contains('fiction') || source.contains('روا')) {
      return Icons.auto_stories;
    }
    if (source.contains('history') || source.contains('تاريخ')) {
      return Icons.history_edu;
    }
    if (source.contains('self') || source.contains('ذات')) {
      return Icons.psychology_alt;
    }
    if (source.contains('business') || source.contains('اقتصاد')) {
      return Icons.trending_up;
    }
    if (source.contains('children') || source.contains('أطفال')) {
      return Icons.child_care;
    }
    if (source.contains('technology') || source.contains('تقنية')) {
      return Icons.memory;
    }
    if (source.contains('science') || source.contains('علوم')) {
      return Icons.science;
    }
    if (source.contains('religion') || source.contains('دين')) {
      return Icons.mosque;
    }
    return Icons.category;
  }
}

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _selectedCategoryIds = {};

  List<CategoryItem> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _loadError;

  static const String _fallbackCommunityImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDN5HITfoUosvbHw1AQ8y4RRGDNXaF2TGC14-O6QbzHyKv9eThscCrhmOoY5VTrlXGGBXOhPhe5FyBmo5wqzq5LJ0Dyfu5J8u9sZKMX2j0eumz_Fn3p46RYtTQ76l9j04X87efUomtmmN7KDK65NVi8hcEJ17WgU4yp4NT2u8L7_0BoprEo2u7TKR4q1Bvc6qaoBVzgCxvwiUigLpJffrJpvLYu0jCvvol_PWge9ODU_pakMcETXgUifR8eENWhhsKYBOyel6wB_lU';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _loadError = null;
    });

    try {
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('createdAt')
          .get();

      final categories = snapshot.docs
          .map(CategoryItem.fromFirestore)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _mapFirebaseError(error);
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'تعذر تحميل التصنيفات الآن';
        _isLoadingCategories = false;
      });
    }
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  Future<void> _continueToHome() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _saveSelectedCategories(skipped: false);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      await context.read<HomeViewModel>().fetchHomeData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar(_mapFirebaseError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('تعذر حفظ اختياراتك الآن');
    }
  }

  Future<void> _skipToHome() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _saveSelectedCategories(skipped: true);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      await context.read<HomeViewModel>().fetchHomeData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  Future<void> _saveSelectedCategories({required bool skipped}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = <String, dynamic>{
      'categorySelectionCompleted': true,
      'categorySelectionSkipped': skipped,
      'categorySelectionUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!skipped) {
      final selectedCategories = _categories
          .where((category) => _selectedCategoryIds.contains(category.id))
          .toList(growable: false);

      data['favoriteCategoryIds'] = selectedCategories
          .map((category) => category.id)
          .toList(growable: false);
      data['favoriteCategories'] = selectedCategories
          .map((category) => category.title)
          .toList(growable: false);
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية للوصول إلى التصنيفات';
      case 'unavailable':
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت وحاول مرة أخرى';
      default:
        return 'تعذر الاتصال بقاعدة البيانات';
    }
  }

  String get _communityImageUrl {
    for (final category in _categories) {
      if (_selectedCategoryIds.contains(category.id) &&
          category.imageUrl != null) {
        return category.imageUrl!;
      }
    }

    for (final category in _categories) {
      if (category.imageUrl != null) return category.imageUrl!;
    }

    return _fallbackCommunityImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.6,
                ),
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
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
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.1),
                              ),
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
                                      BoxShadow(
                                        color: theme.colorScheme.primary,
                                        blurRadius: 8,
                                      ),
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

                    _buildCategoriesSection(theme),

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
                              _communityImageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              opacity: const AlwaysStoppedAnimation(0.6),
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.auto_stories,
                                    color: theme.colorScheme.primary,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    theme.colorScheme.surface,
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
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
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
                    theme.colorScheme.surface.withValues(alpha: 0),
                    theme.colorScheme.surface,
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
                        onPressed:
                            (_isSaving ||
                                _isLoadingCategories ||
                                _loadError != null ||
                                _categories.isEmpty)
                            ? null
                            : _continueToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                          shadowColor: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text(
                                'متابعة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isSaving ? null : _skipToHome,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تخطي الآن',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_back,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
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

  Widget _buildCategoriesSection(ThemeData theme) {
    if (_isLoadingCategories) {
      return SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_loadError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF353534).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              color: theme.colorScheme.onSurfaceVariant,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadCategories,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF353534).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          'لا توجد تصنيفات متاحة الآن',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return _buildBentoGrid(theme);
  }

  Widget _buildBentoGrid(ThemeData theme) {
    final rows = <Widget>[];
    var index = 0;

    while (index < _categories.length) {
      final category = _categories[index];
      final useLargeCard = category.isLarge || index == 4;

      if (useLargeCard) {
        rows.add(_buildLargeCategoryCard(theme, category));
        index++;
      } else {
        final nextIndex = index + 1;
        final hasSmallPair =
            nextIndex < _categories.length &&
            !_categories[nextIndex].isLarge &&
            nextIndex != 4;

        rows.add(
          Row(
            children: [
              Expanded(child: _buildCategoryCard(theme, category)),
              if (hasSmallPair) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryCard(theme, _categories[nextIndex]),
                ),
              ] else ...[
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        );
        index += hasSmallPair ? 2 : 1;
      }

      if (index < _categories.length) {
        rows.add(const SizedBox(height: 12));
      }
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
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 32,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
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
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: _buildCategoryIcon(
                      theme,
                      category,
                      isSelected: isSelected,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    category.title,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: _buildCategoryIcon(
                      theme,
                      category,
                      isSelected: isSelected,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.title,
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category.bookCount != null)
                          Text(
                            category.bookCount!,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              )
            else
              Icon(
                Icons.chevron_left,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(
    ThemeData theme,
    CategoryItem category, {
    required bool isSelected,
    required double size,
  }) {
    final iconColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    if (category.iconUrl == null) {
      return Icon(category.fallbackIcon, color: iconColor, size: size);
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Image.network(
        category.iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(category.fallbackIcon, color: iconColor, size: size);
        },
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
