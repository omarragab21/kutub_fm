import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/firebase_storage_url_resolver.dart';
import '../providers/auth_provider.dart';

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

    final imageUrl = _nullableStringField(data, const [
      'imageUrl',
      'image',
      'icon',
      'iconUrl',
    ]);

    return CategoryItem(
      id: document.id,
      title: title,
      iconUrl: imageUrl,
      imageUrl: imageUrl,
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
    if (source.contains('horror') || source.contains('رعب')) {
      return Icons.flash_on;
    }
    if (source.contains('classic') || source.contains('كلاسيكي')) {
      return Icons.favorite_border;
    }
    if (source.contains('romance') || source.contains('رومانسية')) {
      return Icons.favorite;
    }
    if (source.contains('korean') || source.contains('كوري')) {
      return Icons.translate;
    }
    if (source.contains('self') || source.contains('ذات')) {
      return Icons.psychology;
    }
    if (source.contains('religion') || source.contains('دين')) {
      return Icons.brightness_3;
    }
    if (source.contains('poetry') || source.contains('شعر')) {
      return Icons.menu_book;
    }
    if (source.contains('family') || source.contains('الأسرة')) {
      return Icons.child_care;
    }
    if (source.contains('letter') || source.contains('رسائل')) {
      return Icons.email;
    }
    if (source.contains('philosophy') || source.contains('فلسفة')) {
      return Icons.insights;
    }
    if (source.contains('theat') || source.contains('مسرح')) {
      return Icons.theater_comedy;
    }
    if (source.contains('novel') || source.contains('رواية')) {
      return Icons.explore;
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
          .collection('interested')
          .orderBy('createdAt')
          .get();

      final tempCategories = snapshot.docs
          .map(CategoryItem.fromFirestore)
          .toList();

      final categories = await Future.wait(
        tempCategories.map((item) async {
          String? resolvedIconUrl;
          if (item.iconUrl != null) {
            resolvedIconUrl = await FirebaseStorageUrlResolver.resolve(
              item.iconUrl!,
            );
          }
          return CategoryItem(
            id: item.id,
            title: item.title,
            iconUrl: resolvedIconUrl,
            imageUrl: resolvedIconUrl,
            bookCount: item.bookCount,
            fallbackIcon: item.fallbackIcon,
            isLarge: item.isLarge,
          );
        }),
      );

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
        _loadError = 'تعذر تحميل الاهتمامات الآن';
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
      Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
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
      Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
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
        return 'ليس لديك صلاحية للوصول إلى الاهتمامات';
      case 'unavailable':
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت وحاول مرة أخرى';
      default:
        return 'تعذر الاتصال بقاعدة البيانات';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Progress and Skip
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '1/2',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: _skipToHome,
                            child: const Text(
                              'تخطي',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Middle Content Area (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 70),
                        const Text(
                          'اختر اهتماماتك',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'أخبرنا بما يلفت انتباهك، ودعنا نأخذك إلى كتب وحكايات وأصوات صنعت لتلامس شغفك.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildInterestsSection(theme),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),

                // 3. Fixed Bottom Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            (_isSaving ||
                                _isLoadingCategories ||
                                _categories.isEmpty)
                            ? null
                            : _continueToHome,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC00E),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'التالي',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                color: Colors.white.withOpacity(0.6),
                                size: 18,
                              ),
                              Text(
                                'عودة للخلف',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestsSection(ThemeData theme) {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFC00E)),
        ),
      );
    }

    if (_loadError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white70, size: 36),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadCategories,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
              ),
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
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'لا توجد اهتمامات متاحة الآن',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      children: _categories.map(_buildInterestChip).toList(),
    );
  }

  Widget _buildInterestChip(CategoryItem category) {
    final isSelected = _selectedCategoryIds.contains(category.id);
    const primaryGold = Color(0xFFFFC00E);
    final color = isSelected ? primaryGold : Colors.white;

    return GestureDetector(
      onTap: () => _toggleCategory(category.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryGold
              : const Color(0xFF333333), // RGB 51, 51, 51
          borderRadius: BorderRadius.circular(26), // radius 26
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            _buildChipIcon(category, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildChipIcon(CategoryItem category, bool isSelected) {
    final iconColor = isSelected ? Colors.black : Colors.white;
    if (category.iconUrl != null && category.iconUrl!.endsWith('.svg')) {
      return SvgPicture.network(
        category.iconUrl!,
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        placeholderBuilder: (context) =>
            Icon(category.fallbackIcon, color: iconColor, size: 18),
      );
    } else if (category.iconUrl != null) {
      return Image.network(
        category.iconUrl!,
        width: 18,
        height: 18,
        color: iconColor,
        errorBuilder: (context, error, stackTrace) =>
            Icon(category.fallbackIcon, color: iconColor, size: 18),
      );
    }

    return Icon(category.fallbackIcon, color: iconColor, size: 18);
  }
}
