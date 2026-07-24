import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/storage/firebase_storage_url_resolver.dart';

class _BookOption {
  final String id;
  final String title;
  final String author;
  final String coverUrl;

  _BookOption({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
  });
}

class _InterestOption {
  final String id;
  final String title;

  _InterestOption({required this.id, required this.title});
}

class CreateCommunityPostScreen extends StatefulWidget {
  const CreateCommunityPostScreen({super.key});

  @override
  State<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final FocusNode _hashtagFocusNode = FocusNode();
  final LayerLink _hashtagLayerLink = LayerLink();

  final List<_BookOption> _books = [];
  final List<_InterestOption> _interests = [];
  final List<_InterestOption> _selectedHashtags = [];
  List<_InterestOption> _filteredInterests = [];

  _BookOption? _selectedBook;
  int _rating = 0;
  bool _isLoading = true;
  bool _isPublishing = false;
  bool _showHashtagSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _hashtagController.addListener(_onHashtagChanged);
    _hashtagFocusNode.addListener(_onHashtagFocusChanged);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Future.wait([
        _loadBooks(),
        _loadInterests(),
      ]);
    } catch (e) {
      _showSnackBar('تعذر تحميل البيانات');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) {
      final allDocs = await FirebaseFirestore.instance.collection('books').get();
      _books.addAll(await Future.wait(allDocs.docs.map(_bookFromDoc)));
    } else {
      _books.addAll(await Future.wait(snapshot.docs.map(_bookFromDoc)));
    }
  }

  Future<_BookOption> _bookFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final contributors = data['contributors'] as List<dynamic>? ?? [];
    final coverUrl = await FirebaseStorageUrlResolver.resolve(
      data['imageUrl'] as String? ?? '',
    );

    return _BookOption(
      id: doc.id,
      title: data['title'] as String? ?? '',
      author: _getAuthorFromContributors(contributors),
      coverUrl: coverUrl,
    );
  }

  String _getAuthorFromContributors(List<dynamic> contributors) {
    if (contributors.isEmpty) return '';
    for (final c in contributors) {
      if (c is Map<String, dynamic> && c['role'] == 'AUTHOR') {
        return c['nameSnapshot'] ?? '';
      }
    }
    final first = contributors.first;
    if (first is Map<String, dynamic>) {
      return first['nameSnapshot'] ?? '';
    }
    return '';
  }

  Future<void> _loadInterests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('interested')
        .orderBy('createdAt')
        .get();

    _interests.addAll(
      snapshot.docs.map((doc) {
        final data = doc.data();
        final title = _stringField(
          data,
          const ['name', 'title', 'nameAr', 'arabicName'],
          fallback: doc.id,
        );
        return _InterestOption(id: doc.id, title: title);
      }).toList(),
    );
  }

  String _stringField(
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

  void _onHashtagChanged() {
    final raw = _hashtagController.text.trim().toLowerCase();
    final query = raw.startsWith('#') ? raw.substring(1) : raw;
    if (query.isEmpty) {
      setState(() {
        _filteredInterests = [];
        _showHashtagSuggestions = false;
      });
      return;
    }

    final selectedIds = _selectedHashtags.map((h) => h.id).toSet();
    final matches = _interests
        .where(
          (interest) =>
              !selectedIds.contains(interest.id) &&
              (interest.title.toLowerCase().contains(query) ||
                  interest.id.toLowerCase().contains(query)),
        )
        .toList();

    setState(() {
      _filteredInterests = matches;
      _showHashtagSuggestions = matches.isNotEmpty;
    });
  }

  void _addCustomHashtag() {
    final raw = _hashtagController.text.trim();
    final title = raw.startsWith('#') ? raw.substring(1) : raw;
    if (title.isEmpty) return;
    if (_selectedHashtags.any((h) => h.title == title)) {
      _hashtagController.clear();
      return;
    }
    _addHashtag(_InterestOption(id: 'custom_$title', title: title));
  }

  void _onHashtagFocusChanged() {
    if (!_hashtagFocusNode.hasFocus) {
      setState(() => _showHashtagSuggestions = false);
    }
  }

  void _addHashtag(_InterestOption interest) {
    setState(() {
      if (!_selectedHashtags.any((h) => h.id == interest.id)) {
        _selectedHashtags.add(interest);
      }
      _hashtagController.clear();
      _filteredInterests = [];
      _showHashtagSuggestions = false;
    });
  }

  void _removeHashtag(_InterestOption interest) {
    setState(() => _selectedHashtags.removeWhere((h) => h.id == interest.id));
  }

  Future<Map<String, String>> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'name': 'مستخدم كتب FM',
        'photoUrl': 'https://i.pravatar.cc/150?img=65',
      };
    }

    String name = user.displayName ?? '';
    String photoUrl = user.photoURL ?? '';

    if (name.isEmpty || photoUrl.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (name.isEmpty) name = data?['name'] ?? '';
          if (photoUrl.isEmpty) photoUrl = data?['photoUrl'] ?? '';
        }
      } catch (e) {
        debugPrint('Error getting user profile: $e');
      }
    }

    if (name.isEmpty) name = 'مستخدم كتب FM';
    if (photoUrl.isEmpty) photoUrl = 'https://i.pravatar.cc/150?img=65';

    return {'name': name, 'photoUrl': photoUrl};
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showSnackBar('اكتب محتوى المنشور أولاً');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userProfile = await _getUserProfile();

      final book = _selectedBook;
      final data = <String, dynamic>{
        'userId': user?.uid ?? 'unknown',
        'userName': userProfile['name'],
        'userAvatarUrl': userProfile['photoUrl'],
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'likedBy': <String>[],
        'comments': <Map<String, dynamic>>[],
        'isReview': book != null && _rating > 0,
        'rating': book != null ? _rating : 0,
        'hashtags': _selectedHashtags.map((h) => h.title).toList(),
        'hashtagIds': _selectedHashtags.map((h) => h.id).toList(),
      };

      if (book != null) {
        data['bookId'] = book.id;
        data['bookTitle'] = book.title;
        data['bookAuthor'] = book.author;
        data['bookCover'] = book.coverUrl;
      }

      await FirebaseFirestore.instance.collection('community_posts').add(data);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error publishing post: $e');
      _showSnackBar('تعذر نشر المنشور');
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showBookPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'اختر كتاباً',
                    style: TextStyle(
                      fontFamily: 'ThmanyahSans',
                      color: const Color(0xFFF4F4F4),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            book.coverUrl,
                            width: 40,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 40,
                              height: 56,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        title: Text(
                          book.title,
                          style: TextStyle(
                            fontFamily: 'ThmanyahSans',
                            color: const Color(0xFFF4F4F4),
                            fontSize: 14.sp,
                          ),
                        ),
                        subtitle: Text(
                          book.author,
                          style: TextStyle(
                            fontFamily: 'ThmanyahSans',
                            color: const Color(0xFFBDBDBD),
                            fontSize: 12.sp,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedBook = book);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _hashtagController.removeListener(_onHashtagChanged);
    _hashtagController.dispose();
    _hashtagFocusNode.removeListener(_onHashtagFocusChanged);
    _hashtagFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040707),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 40.h),
                          _buildHeader(),
                          SizedBox(height: 50.h),
                          _buildLabel('محتوى المنشور'),
                          _buildContentField(),
                          SizedBox(height: 20.h),
                          _buildLabel('ربط بكتاب ( إختياري )'),
                          _buildBookSelector(),
                          SizedBox(height: 20.h),
                          if (_selectedBook != null) ...[
                            _buildRatingSection(),
                            SizedBox(height: 20.h),
                          ],
                          _buildLabel('أضف هشتاج'),
                          CompositedTransformTarget(
                            link: _hashtagLayerLink,
                            child: _buildHashtagField(),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _buildPublishButton(),
                  ),
                ],
              ),
              if (_showHashtagSuggestions)
                CompositedTransformFollower(
                  link: _hashtagLayerLink,
                  showWhenUnlinked: false,
                  followerAnchor: Alignment.topRight,
                  targetAnchor: Alignment.bottomRight,
                  offset: const Offset(0, 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    child: _buildHashtagSuggestions(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 41,
              height: 41,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(50),
              ),
              child: SvgPicture.asset(
                'assets/arrow_back.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFF4F4F4),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Text(
            'إنشاء منشور',
            style: TextStyle(
              color: const Color(0xFFF4F4F4),
              fontSize: 18.sp,
              fontFamily: 'ThmanyahSans',
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: const Color(0xFFBDBDBD),
          fontSize: 14.sp,
          fontFamily: 'ThmanyahSans',
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Container(
      width: double.infinity,
      height: 158,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        textAlign: TextAlign.right,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          color: const Color(0xFFF4F4F4),
          fontSize: 14.sp,
          fontFamily: 'ThmanyahSans',
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'انشر للعالم ما يلهمك...',
          hintStyle: TextStyle(
            color: const Color(0xFFF4F4F4).withValues(alpha: 0.5),
            fontSize: 14.sp,
            fontFamily: 'ThmanyahSans',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildBookSelector() {
    return GestureDetector(
      onTap: _isLoading ? null : _showBookPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.keyboard_arrow_down,
              color: const Color(0xFFF4F4F4),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedBook?.title ?? 'اختر كتاباً',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFFF4F4F4),
                  fontSize: 14.sp,
                  fontFamily: 'ThmanyahSans',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'تقييم الكتاب',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFFBDBDBD),
              fontSize: 14.sp,
              fontFamily: 'ThmanyahSans',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final isFilled = index < _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.only(left: 1.68),
                  child: SvgPicture.asset(
                    isFilled
                        ? 'assets/community/imgVector.svg'
                        : 'assets/community/imgVector1.svg',
                    width: 30,
                    height: 30,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _addCustomHashtag,
                child: Icon(
                  Icons.add,
                  color: const Color(0xFFF4F4F4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _hashtagController,
                  focusNode: _hashtagFocusNode,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: const Color(0xFFF4F4F4),
                    fontSize: 14.sp,
                    fontFamily: 'ThmanyahSans',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب هاشتاج...',
                    hintStyle: TextStyle(
                      color: const Color(0xFFF4F4F4).withValues(alpha: 0.5),
                      fontSize: 14.sp,
                      fontFamily: 'ThmanyahSans',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (_) {
                    if (_filteredInterests.isNotEmpty) {
                      _addHashtag(_filteredInterests.first);
                    } else {
                      _addCustomHashtag();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        if (_selectedHashtags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: _selectedHashtags.map(_buildHashtagChip).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHashtagSuggestions() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _filteredInterests.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final interest = _filteredInterests[index];
          return ListTile(
            dense: true,
            title: Text(
              '#${interest.title}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFFF4F4F4),
                fontSize: 14.sp,
                fontFamily: 'ThmanyahSans',
              ),
            ),
            onTap: () => _addHashtag(interest),
          );
        },
      ),
    );
  }

  Widget _buildHashtagChip(_InterestOption hashtag) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _removeHashtag(hashtag),
            child: Icon(
              Icons.close,
              color: const Color(0xFFF4F4F4),
              size: 18,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '#${hashtag.title}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFFF4F4F4),
              fontSize: 10.sp,
              fontFamily: 'ThmanyahSans',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isPublishing || _isLoading ? null : _publish,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFBD10),
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: const Color(0xFFFFBD10).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
        ),
        child: _isPublishing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFF1F1F1F),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/sent.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1F1F1F),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نشر الآن',
                    style: TextStyle(
                      color: const Color(0xFF1F1F1F),
                      fontSize: 16.sp,
                      fontFamily: 'ThmanyahSans',
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
