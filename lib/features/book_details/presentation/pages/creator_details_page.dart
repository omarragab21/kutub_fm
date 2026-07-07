import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kutub_fm/features/book_reader/presentation/pages/book_reader_screen.dart';

class CreatorDetailsArgs {
  const CreatorDetailsArgs({
    required this.creatorId,
    required this.displayName,
    required this.roleLabel,
  });

  final String creatorId;
  final String displayName;
  final String roleLabel;
}

class CreatorDetailsPage extends StatefulWidget {
  const CreatorDetailsPage({super.key, required this.args});

  final CreatorDetailsArgs args;

  @override
  State<CreatorDetailsPage> createState() => _CreatorDetailsPageState();
}

class _CreatorDetailsPageState extends State<CreatorDetailsPage> {
  bool _showAuthors = false; // Used for Publisher toggle

  @override
  Widget build(BuildContext context) {
    // Determine if publisher based on roleLabel (or just hardcode based on the dummy text)
    final isPublisher =
        widget.args.displayName == 'فريق بوفو' ||
        widget.args.roleLabel.contains('ناشر');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0C0C),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Blurred Header
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Blurred Background
                  ClipRect(
                    child: Container(
                      height: 312,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            isPublisher
                                ? 'assets/publisher_bofo.png'
                                : 'assets/avatar_fawzy.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                isPublisher
                                    ? const Color(0x4DFFBD10)
                                    : const Color(0x4D4361EE),
                                const Color(0xFF0C0C0C).withValues(alpha: 0.8),
                                const Color(0xFF0C0C0C),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SafeArea(
                    child: Column(
                      children: [
                        // Top Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/arrow_back.svg',
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    width: 18,
                                    height: 18,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/share.svg',
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/heart.svg',
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset(
                              isPublisher
                                  ? 'assets/publisher_bofo.png'
                                  : 'assets/avatar_fawzy.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          widget.args.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            isPublisher
                                ? 'المنتج الأكبر للكتب الصوتية باللغة العربية في العالم\nصوت..صورة..محتوى..تسويق.\nكل ما تحتاجه علامتك التجارية في مكان واحد.\nنساعد الشركات، ودور النشر، وصنّاع المحتوى على تحويل أفكارهم إلى محتوى احترافي يُسمع، ويُشاهد، ويُسوّق بفاعلية.\nمن إنتاج الكتب الصوتية والبودكاست، إلى تصوير الفيديوهات، وإدارة محتوى السوشيال ميديا، وبناء الحملات التسويقية الرقمية.'
                                : 'نورهان فوزي هي مؤلفة ومبدعة متخصصة في إنتاج المحتوى الصوتي والمرئي باللغة العربية. تتميز بخبرتها في تحويل الأفكار إلى محتوى احترافي يجمع بين الصوت والصورة والتسويق، وتعمل على دعم الشركات ودور النشر وصنّاع المحتوى لتحقيق تواصل فعال مع جمهورهم من خلال الكتب الصوتية، البودكاست، الفيديوهات، وإدارة الحملات التسويقية الرقمية.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Toggle Buttons or Books Label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: isPublisher
                    ? _buildPublisherToggle()
                    : _buildAuthorBooksLabel(),
              ),
            ),

            // Content Grid or List
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: isPublisher && _showAuthors
                  ? _buildAuthorsList()
                  : _buildBooksGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublisherToggle() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => _showAuthors = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _showAuthors
                      ? const Color(0xFFFFBD10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'المؤلفون',
                  style: TextStyle(
                    color: _showAuthors ? const Color(0xFF1F1F1F) : const Color(0xFFBDBDBD),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showAuthors = false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: !_showAuthors
                      ? const Color(0xFFFFBD10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'الكتب',
                  style: TextStyle(
                    color: !_showAuthors ? const Color(0xFF1F1F1F) : const Color(0xFFBDBDBD),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorBooksLabel() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFBD10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          'الكتب',
          style: TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBooksGrid() {
    final isPublisher =
        widget.args.displayName == 'فريق بوفو' ||
        widget.args.roleLabel.contains('ناشر');

    final books = [
      {
        'title': 'ألف ليلة وليلة',
        'author': isPublisher ? 'غير معروف' : widget.args.displayName,
        'cover': 'assets/cover_thousand_nights.png',
      },
      {
        'title': 'مدن الملح',
        'author': isPublisher ? 'عبد الرحمن منيف' : widget.args.displayName,
        'cover': 'assets/cover_salt_cities.png',
      },
      {
        'title': 'الخبز الحافي',
        'author': isPublisher ? 'محمد شكري' : widget.args.displayName,
        'cover': 'assets/cover_barefoot_bread.png',
      },
      {
        'title': 'رجال في الشمس',
        'author': isPublisher ? 'غسان كنفاني' : widget.args.displayName,
        'cover': 'assets/cover_men_in_sun.png',
      },
      {
        'title': 'ذاكرة الجسد',
        'author': isPublisher ? 'أحلام مستغانمي' : widget.args.displayName,
        'cover': 'assets/cover_memory_body.png',
      },
      {
        'title': 'في قلبي أنثى عبرية',
        'author': isPublisher ? 'خولة حمدي' : widget.args.displayName,
        'cover': 'assets/cover_jewish_girl.png',
      },
    ];

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final book = books[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 114 / 148,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      book['cover']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/heart.svg',
                              width: 14,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                index == 1 ? const Color(0xFFFF4B4B) : Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book['title']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book['author']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        );
      }, childCount: books.length),
    );
  }

  Widget _buildAuthorsList() {
    // Dummy authors list
    final authors = [
      {'name': 'احمد العربي', 'books': '12 كتاب', 'followers': '20 متابع'},
      {'name': 'ليلى حسن', 'books': '18 كتاب', 'followers': '35 متابع'},
      {'name': 'سامر العلي', 'books': '22 كتاب', 'followers': '50 متابع'},
      {'name': 'نورهان فوزي', 'books': '9 كتب', 'followers': '15 متابع'},
      {'name': 'سارة محمد', 'books': '16 كتاب', 'followers': '40 متابع'},
    ];

    final authorImages = [
      'assets/avatar_arabic.png',
      'assets/avatar_hassan.png',
      'assets/avatar_ali.png',
      'assets/avatar_fawzy.png',
      'assets/avatar_sarah.png',
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final author = authors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(authorImages[index % authorImages.length]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  author['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
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
                  author['books']!,
                  style: const TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  author['followers']!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }, childCount: authors.length),
    );
  }
}
