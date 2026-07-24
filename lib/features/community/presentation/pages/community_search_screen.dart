import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_HashtagItem> _hashtags = [];
  List<_HashtagItem> _filteredHashtags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHashtags();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadHashtags() async {
    try {
      final interestsSnapshot = await FirebaseFirestore.instance
          .collection('interested')
          .get();

      final postsSnapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .get();

      final interestPostCounts = <String, int>{};
      for (final doc in postsSnapshot.docs) {
        final hashtags = List<String>.from(doc.data()['hashtags'] ?? []);
        for (final tag in hashtags) {
          interestPostCounts[tag] = (interestPostCounts[tag] ?? 0) + 1;
        }
      }

      final items = interestsSnapshot.docs.map((doc) {
        final data = doc.data();
        final title = data['name'] as String? ?? '';
        final count = interestPostCounts[title] ?? 0;
        return _HashtagItem(
          id: doc.id,
          title: title,
          postCount: count,
        );
      }).toList();

      items.sort((a, b) => b.postCount.compareTo(a.postCount));

      setState(() {
        _hashtags = items;
        _filteredHashtags = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading hashtags: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredHashtags = _hashtags;
      } else {
        _filteredHashtags = _hashtags
            .where((item) => item.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040707),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFBD10),
                        ),
                      )
                    : _filteredHashtags.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                fontFamily: 'ThmanyahSans',
                                color: const Color(0xFFBDBDBD),
                                fontSize: 16.sp,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredHashtags.length,
                            itemBuilder: (context, index) {
                              return _buildHashtagItem(_filteredHashtags[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Directionality(
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
              'بحث في المجتمع',
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/community/imgSearch01.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFFBDBDBD),
                  fontSize: 14.sp,
                  fontFamily: 'ThmanyahSans',
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث عن ما تريد...',
                  hintStyle: TextStyle(
                    color: const Color(0xFFBDBDBD),
                    fontSize: 14.sp,
                    fontFamily: 'ThmanyahSans',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagItem(_HashtagItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFBDBDBD)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#${item.title}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFFF4F4F4),
                  fontSize: 18.sp,
                  fontFamily: 'ThmanyahSans',
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.postCount} منشور',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFFBDBDBD),
                  fontSize: 16.sp,
                  fontFamily: 'ThmanyahSans',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          SvgPicture.asset(
            'assets/community_hashtag.svg',
            width: 30,
            height: 30,
          ),
        ],
      ),
    );
  }
}

class _HashtagItem {
  final String id;
  final String title;
  final int postCount;

  _HashtagItem({
    required this.id,
    required this.title,
    required this.postCount,
  });
}
