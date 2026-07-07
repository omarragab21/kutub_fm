import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 'post_1',
      'user_name': 'ليلى حسن',
      'date': '10/6/2026',
      'avatar': 'assets/community/imgAvatar.png',
      'is_review': true,
      'rating': 5,
      'content':
          'كتاب غني بالأفكار ويدفعك للتفكير في طبيعة الإنسان والمجتمع. سرد متقن وشخصيات عميقة.',
      'book_title': 'ظل الريح',
      'book_author': 'كارلوس زافون',
      'book_cover': 'assets/community/imgImage27.png',
      'likes': 28,
      'comments': 15,
    },
    {
      'id': 'post_2',
      'user_name': 'مازن عبد الله',
      'date': '3/7/2026',
      'avatar': 'assets/community/imgAvatar1.png',
      'is_review': true,
      'rating': 5,
      'content':
          'قصة ملهمة تجمع بين الخيال والواقع، تحمل رسائل قوية عن الصداقة والوفاء.',
      'book_title': 'الأمير الصغير',
      'book_author': 'أنطوان دو سانت إكزوبيري',
      'book_cover': 'assets/community/imgImage28.png',
      'likes': 42,
      'comments': 10,
    },
    {
      'id': 'post_3',
      'user_name': 'سارة أحمد',
      'date': '15/5/2026',
      'avatar': 'assets/community/imgAvatar2.png',
      'is_review': true,
      'rating': 4,
      'content':
          'عمل أدبي رائع يتناول قضايا الهوية والذاكرة بطريقة فلسفية وعميقة.',
      'book_title': 'موسم الهجرة إلى الشمال',
      'book_author': 'الطيب صالح',
      'book_cover': 'assets/community/imgImage29.png',
      'likes': 50,
      'comments': 22,
    },
    {
      'id': 'post_4',
      'user_name': 'سامر العلي',
      'date': '24/5/2026',
      'avatar': 'assets/community/imgProperty1Variant2.png',
      'is_review': true,
      'rating': 5,
      'content':
          'رواية استثنائية، أعادت تشكيل نظرتي للحياة والحب والوجود أسلوب ساحر ومترجم بشكل رائع. أنصح بها بشدة.',
      'book_title': 'مئة عام من العزلة',
      'book_author': 'أحمد خالد توفيق',
      'book_cover': 'assets/community/imgImage26.png',
      'likes': 35,
      'comments': 20,
    },
  ];

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
                  fontWeight: FontWeight.w400, // Regular
                ),
              ),
            ),
          ],
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
            Align(
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
            if (post['rating'] != null) ...[
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

            // Embedded Book Card
            Container(
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
                    child: Image.asset(
                      post['book_cover'],
                      width: 31,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          post['book_title'],
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
                          post['book_author'],
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
            ),
            const SizedBox(height: 16),

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
                _buildActionIcon(
                  'assets/community/imgVector5.svg',
                  '${post['likes']}',
                ),
              ],
            ),
          ],
        ),
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
