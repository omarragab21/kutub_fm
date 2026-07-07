import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailsScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final List<Map<String, dynamic>> _comments = [
    {
      'name': 'سامر العلي',
      'date': '24/5/2026',
      'avatar': 'assets/community/imgAvatar.png',
      'likes': 3,
      'content':
          'أتفق معك تمامًا! الرواية من أروع ما قرأت في حياتي. ماركيز عبقري بكل معنى الكلمة.',
    },
    {
      'name': 'ليلى حسن',
      'date': '15/7/2026',
      'avatar': 'assets/community/imgAvatar1.png',
      'likes': 4,
      'content':
          'قصة رائعة تحمل بين طياتها الكثير من المشاعر والأفكار العميقة. أحببت كل شخصية فيها.',
    },
    {
      'name': 'خالد يوسف',
      'date': '2/9/2026',
      'avatar': 'assets/community/imgAvatar2.png',
      'likes': 5,
      'content':
          'الأسلوب السلس والوصف الدقيق جعلاني أعيش الأحداث وكأنني جزء منها. أنصح الجميع بقراءتها.',
    },
    {
      'name': 'منى عبد الله',
      'date': '18/10/2026',
      'avatar': 'assets/community/imgAvatar3.png',
      'likes': 6,
      'content':
          'لم أتوقع أن تجمع الرواية بين التشويق والفلسفة بهذا الشكل. تجربة قراءة لا تُنسى.',
    },
    {
      'name': 'عمر محمد',
      'date': '30/11/2026',
      'avatar': 'assets/community/imgAvatar4.png',
      'likes': 7,
      'content':
          'الرموز والرسائل العميقة في الرواية فتحت لي آفاقًا جديدة للفهم والتأمل. عمل مبدع بحق.',
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
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  children: [
                    _buildReviewCard(widget.post),
                    const SizedBox(height: 24),
                    Text(
                      'التعليقات',
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFF4F4F4),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._comments
                        .map((comment) => _buildCommentItem(comment))
                        .toList(),
                  ],
                ),
              ),
              _buildCommentInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Spacer(),
          SizedBox(width: 40),
          Text(
            'تفاصيل المنشور',
            style: TextStyle(
              fontFamily: 'ThmanyahSans',
              color: const Color(0xFFF4F4F4),
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 41,
              height: 41,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(50),
              ),
              child: SvgPicture.asset(
                'assets/community/imgVector12.svg',
                width: 17,
                height: 17,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ), // Placeholder to balance back button
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info & Review Badge
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: Image.asset(
                  post['avatar'] ?? 'assets/community/imgAvatar.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['user_name'] ?? 'مستخدم',
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFF4F4F4),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post['date'] ?? 'الآن',
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFBDBDBD),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (post['is_review'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating
          if (post['rating'] != null) ...[
            Row(
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: SvgPicture.asset(
                    i < (post['rating'] ?? 5)
                        ? 'assets/community/imgVector.svg'
                        : 'assets/community/imgVector1.svg',
                    width: 17,
                    height: 17,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
          ],

          // Review Content
          Text(
            post['content'] ?? '',
            style: TextStyle(
              fontFamily: 'ThmanyahSans',
              color: const Color(0xFFF4F4F4),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Embedded Book Card
          if (post['book_cover'] != null)
            Container(
              height: 58,
              padding: const EdgeInsets.only(
                right: 16,
                left: 8,
                top: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF333333)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/nav_books.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
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
                            fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.asset(
                      post['book_cover'],
                      width: 31,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Bottom Actions Row (Reversed)
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
                '${post['comments'] ?? 0}',
              ),
              const SizedBox(width: 16),
              _buildActionIcon(
                'assets/community/imgVector5.svg',
                '${post['likes'] ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: Image.asset(
                  comment['avatar'],
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['name'],
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFF4F4F4),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment['date'],
                      style: TextStyle(
                        fontFamily: 'ThmanyahSans',
                        color: const Color(0xFFBDBDBD),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionIcon(
                'assets/community/imgVector13.svg', // Heart icon
                '${comment['likes']}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comment['content'],
            style: TextStyle(
              fontFamily: 'ThmanyahSans',
              color: const Color(0xFFF4F4F4),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(String iconPath, String count) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Color(0xFFBDBDBD),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontFamily: 'ThmanyahSans',
            color: const Color(0xFFBDBDBD),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        border: Border(top: BorderSide(color: const Color(0xFF333333))),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFBD10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/post_details/imgVector14.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF1F1F1F),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF333333)),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              child: TextField(
                style: const TextStyle(
                  fontFamily: 'ThmanyahSans',
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب تعليق...',
                  hintStyle: TextStyle(
                    fontFamily: 'ThmanyahSans',
                    color: const Color(0xFFBDBDBD),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
