import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/routes/app_routes.dart';
import 'post_details_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<Map<String, dynamic>> _posts = [];
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _seedIfEmpty().then((_) => _listenToPosts());
  }

  Future<void> _seedIfEmpty() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) return;

      final mockPosts = [
        {
          'userName': 'ليلى حسن',
          'userAvatarUrl': 'assets/community/imgAvatar.png',
          'content':
              'كتاب غني بالأفكار ويدفعك للتفكير في طبيعة الإنسان والمجتمع. سرد متقن وشخصيات عميقة.',
          'createdAt': FieldValue.serverTimestamp(),
          'isReview': true,
          'rating': 5,
          'bookTitle': 'ظل الريح',
          'bookAuthor': 'كارلوس زافون',
          'bookCover': 'assets/community/imgImage27.png',
          'likedBy': <String>[],
          'comments': <Map<String, dynamic>>[],
          'hashtags': <String>[],
          'hashtagIds': <String>[],
        },
        {
          'userName': 'مازن عبد الله',
          'userAvatarUrl': 'assets/community/imgAvatar1.png',
          'content':
              'قصة ملهمة تجمع بين الخيال والواقع، تحمل رسائل قوية عن الصداقة والوفاء.',
          'createdAt': FieldValue.serverTimestamp(),
          'isReview': true,
          'rating': 5,
          'bookTitle': 'الأمير الصغير',
          'bookAuthor': 'أنطوان دو سانت إكزوبيري',
          'bookCover': 'assets/community/imgImage28.png',
          'likedBy': <String>[],
          'comments': <Map<String, dynamic>>[],
          'hashtags': <String>[],
          'hashtagIds': <String>[],
        },
        {
          'userName': 'سارة أحمد',
          'userAvatarUrl': 'assets/community/imgAvatar2.png',
          'content':
              'عمل أدبي رائع يتناول قضايا الهوية والذاكرة بطريقة فلسفية وعميقة.',
          'createdAt': FieldValue.serverTimestamp(),
          'isReview': true,
          'rating': 4,
          'bookTitle': 'موسم الهجرة إلى الشمال',
          'bookAuthor': 'الطيب صالح',
          'bookCover': 'assets/community/imgImage29.png',
          'likedBy': <String>[],
          'comments': <Map<String, dynamic>>[],
          'hashtags': <String>[],
          'hashtagIds': <String>[],
        },
        {
          'userName': 'سامر العلي',
          'userAvatarUrl': 'assets/community/imgProperty1Variant2.png',
          'content':
              'رواية استثنائية، أعادت تشكيل نظرتي للحياة والحب والوجود أسلوب ساحر ومترجم بشكل رائع. أنصح بها بشدة.',
          'createdAt': FieldValue.serverTimestamp(),
          'isReview': true,
          'rating': 5,
          'bookTitle': 'مئة عام من العزلة',
          'bookAuthor': 'أحمد خالد توفيق',
          'bookCover': 'assets/community/imgImage26.png',
          'likedBy': <String>[],
          'comments': <Map<String, dynamic>>[],
          'hashtags': <String>[],
          'hashtagIds': <String>[],
        },
      ];

      for (final post in mockPosts) {
        await FirebaseFirestore.instance.collection('community_posts').add(post);
      }
    } catch (e) {
      debugPrint('Error seeding community posts: $e');
    }
  }

  void _listenToPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUid = currentUser?.uid;

      setState(() {
        _posts.clear();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final likedBy = List<String>.from(data['likedBy'] ?? []);
          final isLikedByMe = currentUid != null && likedBy.contains(currentUid);
          final createdAt = data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now();

          _posts.add({
            'id': doc.id,
            'user_name': data['userName'] ?? 'مستخدم كتب FM',
            'date': _formatDate(createdAt),
            'avatar': data['userAvatarUrl'] ?? 'assets/community/imgAvatar.png',
            'is_review': data['isReview'] == true,
            'rating': (data['rating'] as num?)?.toInt() ?? 0,
            'content': data['content'] ?? '',
            'book_title': data['bookTitle'],
            'book_author': data['bookAuthor'],
            'book_cover': data['bookCover'],
            'likes': likedBy.length,
            'comments': (data['comments'] as List?)?.length ?? 0,
            'likedBy': likedBy,
            'isLikedByMe': isLikedByMe,
          });
        }
        _isLoading = false;
      });
    }, onError: (error) {
      debugPrint('Error listening to community posts: $error');
      setState(() => _isLoading = false);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleLike(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final currentUid = currentUser.uid;

    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return;

    final post = _posts[index];
    final likedBy = List<String>.from(post['likedBy'] ?? []);
    final isLiked = likedBy.contains(currentUid);

    setState(() {
      if (isLiked) {
        likedBy.remove(currentUid);
      } else {
        likedBy.add(currentUid);
      }
      _posts[index] = {
        ...post,
        'likedBy': likedBy,
        'likes': likedBy.length,
        'isLikedByMe': !isLiked,
      };
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('community_posts')
          .doc(postId);
      if (isLiked) {
        await docRef.update({'likedBy': FieldValue.arrayRemove([currentUid])});
      } else {
        await docRef.update({'likedBy': FieldValue.arrayUnion([currentUid])});
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
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
              _buildCreatePostSection(),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFBD10)),
                  ),
                )
              else if (_posts.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'لا توجد منشورات بعد\nكن أول من ينشر',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFBDBDBD),
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 80),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              'احدث المنشورات',
                              style: TextStyle(
                                fontFamily: 'ThmanyahSans',
                                color: const Color(0xFFF4F4F4),
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700, // Bold
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PostDetailsScreen(post: _posts[index]),
                                ),
                              );
                            },
                            child: _buildPostCard(_posts[index]),
                          ),
                        ],
                      );
                    }
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PostDetailsScreen(post: _posts[index]),
                          ),
                        );
                      },
                      child: _buildPostCard(_posts[index]),
                    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'المجتمع',
            style: TextStyle(
              fontFamily: 'ThmanyahSans',
              color: const Color(0xFFF4F4F4),
              fontSize: 18.sp,
              fontWeight: FontWeight.w700, // Bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.communitySearch),
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
                child: Text(
                  'ابحث عن ما تريد...',
                  style: TextStyle(
                    fontFamily: 'ThmanyahSans',
                    color: const Color(0xFFBDBDBD),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'انشر للعالم ما يلهمك...',
                style: TextStyle(
                  fontFamily: 'ThmanyahSans',
                  color: const Color(0xFFBDBDBD),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400, // Regular
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.communityCreatePost),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBD10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'إنشاء منشور',
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFF1F1F1F),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500, // Medium
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'assets/community/imgVector13.svg',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        bool isFilled = index < rating;
        return Padding(
          padding: const EdgeInsets.only(left: 1.0),
          child: SvgPicture.asset(
            isFilled
                ? 'assets/community/imgVector.svg'
                : 'assets/community/imgVector1.svg',
            width: 18,
            height: 18,
          ),
        );
      }),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.postDetails, arguments: post);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    post['avatar'],
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['user_name'],
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFFF4F4F4),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700, // Bold
                        ),
                      ),
                      Text(
                        post['date'],
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFFBDBDBD),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400, // Regular
                        ),
                      ),
                    ],
                  ),
                ),
                if (post['is_review'])
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBD10),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Text(
                      'مراجعة',
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFF1F1F1F),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500, // Medium
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Rating Stars
            if (post['rating'] != null && (post['rating'] as num) > 0) ...[
              _buildRatingStars(post['rating']),
              const SizedBox(height: 8),
            ],

            // Content
            Text(
              post['content'],
              style: TextStyle(
                fontFamily: 'ThmanyahSans',
                color: const Color(0xFFF4F4F4),
                fontSize: 16.sp,
                fontWeight: FontWeight.w400, // Regular
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            if (post['book_title'] != null) ...[
              _buildBookCard(post),
              const SizedBox(height: 16),
            ],

            // Bottom Actions Row
            Row(
              children: [
                SvgPicture.asset(
                  'assets/community/imgVector11.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFBDBDBD),
                    BlendMode.srcIn,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.share_outlined,
                  color: const Color(0xFFBDBDBD),
                  size: 20,
                ),
                const SizedBox(width: 16),
                _buildActionIcon(
                  'assets/community/imgVector6.svg',
                  '${post['comments']}',
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _toggleLike(post['id']),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post['isLikedByMe'] == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post['isLikedByMe'] == true
                            ? const Color(0xFFFFBD10)
                            : const Color(0xFFBDBDBD),
                        size: 20,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${post['likes']}',
                        style: TextStyle(
                          fontFamily: 'ThmanyahSans',
                          color: const Color(0xFFBDBDBD),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> post) {
    final cover = post['book_cover'] as String?;
    final isNetworkCover = cover != null &&
        (cover.startsWith('http://') || cover.startsWith('https://'));

    return Container(
      height: 58,
      padding: const EdgeInsets.only(
        right: 16,
        left: 8,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF808080)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: isNetworkCover
                ? Image.network(
                    cover,
                    width: 31,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 31,
                      height: double.infinity,
                      color: const Color(0xFF333333),
                    ),
                  )
                : Image.asset(
                    cover ?? 'assets/community/imgImage26.png',
                    width: 31,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 31,
                      height: double.infinity,
                      color: const Color(0xFF333333),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  post['book_title'] ?? '',
                  style: TextStyle(
                    fontFamily: 'ThmanyahSans',
                    color: const Color(0xFFF4F4F4),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700, // Bold
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  post['book_author'] ?? '',
                  style: TextStyle(
                    fontFamily: 'ThmanyahSans',
                    color: const Color(0xFFBDBDBD),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500, // Medium
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SvgPicture.asset(
            'assets/nav_books.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(String iconAsset, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(iconAsset, width: 20, height: 20),
        const SizedBox(width: 2),
        Text(
          count,
          style: TextStyle(
            fontFamily: 'ThmanyahSans',
            color: const Color(0xFFBDBDBD),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500, // Medium
          ),
        ),
      ],
    );
  }
}
