import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/storage/firebase_storage_url_resolver.dart';
import '../../domain/entities/book_detail_model.dart';
import 'book_details_page.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  List<BookDetail> _books = [];
  List<Map<String, dynamic>> _authors = [];
  String _avatarUrl = '';
  bool _showAuthors = false; // Used for Publisher toggle
  bool _isDescriptionExpanded = false;

  bool get _isPublisher =>
      widget.args.displayName == 'فريق بوفو' ||
      widget.args.roleLabel.contains('ناشر') ||
      widget.args.roleLabel.contains('نشر') ||
      widget.args.roleLabel.toLowerCase().contains('publisher');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isPublisher = _isPublisher;

      // Fetch all books from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('books')
          .get();

      final List<BookDetail> fetchedBooks = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final book = BookDetail.fromFirestore(data, doc.id, []);

        // Resolve cover image URL
        final resolvedImg = await FirebaseStorageUrlResolver.resolve(
          book.imageUrl,
        );

        final resolvedBook = BookDetail(
          id: book.id,
          title: book.title,
          author: book.author,
          authorId: book.authorId,
          authorImage: book.authorImage,
          authorFullNameRussian: book.authorFullNameRussian,
          authorLife: book.authorLife,
          description: book.description,
          rating: book.rating,
          playCount: book.playCount,
          duration: book.duration,
          category: book.category,
          interests: book.interests,
          imageUrl: resolvedImg,
          chapters: book.chapters,
          comments: book.comments,
          pages: book.pages,
          language: book.language,
          shortQuote: book.shortQuote,
          translator: book.translator,
          translatorId: book.translatorId,
          narrator: book.narrator,
          narratorId: book.narratorId,
          publisherId: book.publisherId,
          publisherName: book.publisherName,
          publisherLogo: book.publisherLogo,
          audioUrl: book.audioUrl,
          pdfUrl: book.pdfUrl,
        );
        fetchedBooks.add(resolvedBook);
      }

      if (isPublisher) {
        // Filter books by publisherId or publisherName (robust fallback)
        _books = fetchedBooks
            .where((b) =>
                (b.publisherId.isNotEmpty && b.publisherId == widget.args.creatorId) ||
                (b.publisherName.isNotEmpty &&
                    b.publisherName == widget.args.displayName))
            .toList();

        // Resolve publisher avatar/logo from their published books
        if (_books.isNotEmpty) {
          final firstWithLogo = _books.firstWhere(
            (b) => b.publisherLogo.isNotEmpty,
            orElse: () => _books.first,
          );
          if (firstWithLogo.publisherLogo.isNotEmpty) {
            _avatarUrl = await FirebaseStorageUrlResolver.resolve(
              firstWithLogo.publisherLogo,
            );
          }
        }

        // Extract unique authors who have books published by this publisher
        final Map<String, Map<String, dynamic>> uniqueAuthors = {};
        for (final book in _books) {
          final doc = querySnapshot.docs.firstWhere((d) => d.id == book.id);
          final contributors =
              doc.data()['contributors'] as List<dynamic>? ?? [];
          for (final c in contributors) {
            if (c is Map<String, dynamic> && c['role'] == 'AUTHOR') {
              final authorId = c['contributorId'] ?? c['id'] ?? '';
              final name = c['nameSnapshot'] ?? '';
              final img = c['imageSnapshot'] ?? '';
              if (authorId.isNotEmpty && !uniqueAuthors.containsKey(authorId)) {
                uniqueAuthors[authorId] = {
                  'id': authorId,
                  'name': name,
                  'image': img,
                  'booksCount': 0,
                  'followers': 20, // Default fallback followers count
                };
              }
            }
          }
        }

        // Calculate count of books published by this publisher for each unique author
        for (final authorId in uniqueAuthors.keys) {
          final count = _books.where((b) => b.authorId == authorId).length;
          uniqueAuthors[authorId]!['booksCount'] = count;
        }

        // Resolve avatar image URLs for each extracted author
        final authorList = uniqueAuthors.values.toList();
        for (final auth in authorList) {
          final resolvedAvatar = await FirebaseStorageUrlResolver.resolve(
            auth['image'] as String? ?? '',
          );
          auth['image'] = resolvedAvatar;
        }
        _authors = authorList;
      } else {
        // Contributor / Author: filter books where contributorId matches creatorId
        _books = fetchedBooks.where((book) {
          final doc = querySnapshot.docs.firstWhere((d) => d.id == book.id);
          final contributors =
              doc.data()['contributors'] as List<dynamic>? ?? [];
          return contributors.any((c) {
            if (c is Map<String, dynamic>) {
              final contributorId = c['contributorId'] ?? c['id'] ?? '';
              return contributorId == widget.args.creatorId;
            }
            return false;
          });
        }).toList();

        // Resolve author's avatar from book contributors imageSnapshot
        if (_books.isNotEmpty) {
          String rawImg = '';
          for (final book in _books) {
            final doc = querySnapshot.docs.firstWhere((d) => d.id == book.id);
            final contributors =
                doc.data()['contributors'] as List<dynamic>? ?? [];
            final self = contributors.firstWhere(
              (c) =>
                  c is Map<String, dynamic> &&
                  (c['contributorId'] ?? c['id']) == widget.args.creatorId,
              orElse: () => null,
            );
            if (self != null &&
                self['imageSnapshot'] != null &&
                self['imageSnapshot'].toString().trim().isNotEmpty) {
              rawImg = self['imageSnapshot'];
              break;
            }
          }
          if (rawImg.isNotEmpty) {
            _avatarUrl = await FirebaseStorageUrlResolver.resolve(rawImg);
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublisher = _isPublisher;

    final bioText = isPublisher
        ? 'المنتج الأكبر للكتب الصوتية باللغة العربية في العالم\nصوت..صورة..محتوى..تسويق.\nكل ما تحتاجه علامتك التجارية في مكان واحد.\nنساعد الشركات، ودور النشر، وصنّاع المحتوى على تحويل أفكارهم إلى محتوى احترافي يُسمع، ويُشاهد، ويُسوّق بفاعلية.\nمن إنتاج الكتب الصوتية والبودكاست، إلى تصوير الفيديوهات، وإدارة محتوى السوشيال ميديا، وبناء الحملات التسويقية الرقمية.'
        : 'نساعد الشركات، ودور النشر، وصنّاع المحتوى على تحويل أفكارهم إلى محتوى احترافي يُسمع، ويُشاهد، ويُسوّق بفاعلية.\nمن إنتاج الكتب الصوتية والبودكاست، إلى تصوير الفيديوهات، وإدارة محتوى السوشيال ميديا، وبناء الحملات التسويقية الرقمية.';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF040707),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Cover Banner & Profile Avatar Area
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blurred Background Banner
                  Container(
                    height: 312,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF040707),
                      image: _avatarUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: AssetImage(
                                isPublisher
                                    ? 'assets/publisher_bofo.png'
                                    : 'assets/avatar_fawzy.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),

                  // Overlaying gradients to blend banner smoothly
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.50, -0.04),
                          end: Alignment(0.50, 1.00),
                          colors: [
                            Color(0xFF040707),
                            Color(0x19040707),
                            Color(0xFF040707),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Action/Navigation Bar
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Action Buttons: Share (Right side under RTL)
                        GestureDetector(
                          onTap: () {
                            SharePlus.instance.share(ShareParams(text: 'تحقق من ${widget.args.displayName} على كتب إف إم!'));
                          },
                          child: Container(
                            width: 41,
                            height: 41,
                            decoration: ShapeDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: const CircleBorder(),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/share.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Back Arrow (Left side under RTL)
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 41,
                            height: 41,
                            decoration: ShapeDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: const CircleBorder(),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/arrow_back.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Card (Avatar & Name)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 204,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 9,
                      children: [
                        // Avatar Image
                        Container(
                          width: 100,
                          height: 100,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: _avatarUrl.isNotEmpty
                                ? Image.network(
                                    _avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              isPublisher
                                                  ? 'assets/publisher_bofo.png'
                                                  : 'assets/avatar_fawzy.png',
                                              fit: BoxFit.cover,
                                            ),
                                  )
                                : Image.asset(
                                    isPublisher
                                        ? 'assets/publisher_bofo.png'
                                        : 'assets/avatar_fawzy.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),

                        // Name Text
                        Text(
                          widget.args.displayName,
                          style: const TextStyle(
                            color: Color(0xFFF4F4F4),
                            fontSize: 26,
                            fontFamily: 'ThmanyahSans',
                            fontWeight: FontWeight.w700,
                            height: 1.50,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bio Details Fading Card
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          bioText,
                          textAlign: TextAlign.right,
                          maxLines: _isDescriptionExpanded ? null : 4,
                          overflow: _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.clip,
                          style: const TextStyle(
                            color: Color(0xFFF4F4F4),
                            fontSize: 16,
                            fontFamily: 'ThmanyahSans',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                      ),
                      if (!_isDescriptionExpanded)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0xFF040707)],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab Toggles (Books / Authors)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: isPublisher
                    ? _buildPublisherToggle()
                    : _buildAuthorBooksLabel(),
              ),
            ),

            // Dynamic Content Area (List / Grid / Loading / Error)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: _buildContentSliver(isPublisher),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublisherToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 4,
      children: [
        // Tab: Authors
        GestureDetector(
          onTap: () {
            setState(() {
              _showAuthors = true;
            });
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: ShapeDecoration(
                color: _showAuthors
                    ? const Color(0xFFFFBD10)
                    : const Color(0xFF1F1F1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Center(
                child: Text(
                  'المؤلفون',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _showAuthors
                        ? const Color(0xFF1F1F1F)
                        : const Color(0xFFF4F4F4),
                    fontSize: 14,
                    fontFamily: 'ThmanyahSans',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Tab: Books
        GestureDetector(
          onTap: () {
            setState(() {
              _showAuthors = false;
            });
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: ShapeDecoration(
                color: !_showAuthors
                    ? const Color(0xFFFFBD10)
                    : const Color(0xFF1F1F1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Center(
                child: Text(
                  'الكتب',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: !_showAuthors
                        ? const Color(0xFF1F1F1F)
                        : const Color(0xFFF4F4F4),
                    fontSize: 14,
                    fontFamily: 'ThmanyahSans',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorBooksLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: ShapeDecoration(
              color: const Color(0xFFFFBD10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: const Center(
              child: Text(
                'الكتب',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontSize: 14,
                  fontFamily: 'ThmanyahSans',
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSliver(bool isPublisher) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60.0),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFBD10)),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Text(
                'حدث خطأ أثناء تحميل البيانات',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFBD10),
                  foregroundColor: const Color(0xFF1F1F1F),
                ),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (isPublisher && _showAuthors) {
      // Authors view
      if (_authors.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: Center(
              child: Text(
                'لا يوجد مؤلفين الآن',
                style: TextStyle(
                  color: Color(0xFFF4F4F4),
                  fontSize: 16,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final author = _authors[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreatorDetailsPage(
                    args: CreatorDetailsArgs(
                      creatorId: author['id'] ?? '',
                      displayName: author['name'] ?? '',
                      roleLabel: 'مؤلف',
                    ),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              height: 70,
              padding: const EdgeInsets.all(8),
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Color(0xFF333333)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Right side: Avatar and Name (First in Row children for RTL)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        // Author Avatar
                        Container(
                          width: 54,
                          height: 54,
                          decoration: ShapeDecoration(
                            shape: const CircleBorder(),
                          ),
                          child: ClipOval(
                            child: (author['image'] as String).isNotEmpty
                                ? Image.network(
                                    author['image']!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              'assets/avatar_placeholder.png',
                                              fit: BoxFit.cover,
                                            ),
                                  )
                                : Image.asset(
                                    'assets/avatar_placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        // Author Name
                        Expanded(
                          child: Text(
                            author['name'] ?? '',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFFF4F4F4),
                              fontSize: 16,
                              fontFamily: 'ThmanyahSans',
                              fontWeight: FontWeight.w700,
                              height: 1.50,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Left side: Followers and Books tags (Second in Row children for RTL)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      // Followers count tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF1F1F1F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${author['followers']} متابع',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFFF4F4F4),
                              fontSize: 12,
                              fontFamily: 'ThmanyahSans',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                            ),
                          ),
                        ),
                      ),
                      // Books count tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFFFBD10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${author['booksCount']} كتاب',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF1F1F1F),
                              fontSize: 12,
                              fontFamily: 'ThmanyahSans',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }, childCount: _authors.length),
      );
    }

    // Books view
    if (_books.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60.0),
          child: Center(
            child: Text(
              'لا توجد كتب الآن',
              style: TextStyle(
                color: Color(0xFFF4F4F4),
                fontSize: 16,
                fontFamily: 'ThmanyahSans',
              ),
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final book = _books[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailsPage(bookId: book.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 114 / 148,
                child: Stack(
                  children: [
                    // Book Cover
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: const Color(0xFF1F1F1F),
                        child: book.imageUrl.isNotEmpty
                            ? Image.network(
                                book.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.book,
                                        color: Colors.white24,
                                        size: 40,
                                      ),
                                    ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.book,
                                  color: Colors.white24,
                                  size: 40,
                                ),
                              ),
                      ),
                    ),

                    // Heart / Favorite Button Overlay
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
                                  index == 1
                                      ? const Color(0xFFFF4B4B)
                                      : Colors.white,
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
              // Book Title
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF4F4F4),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
              const SizedBox(height: 2),
              // Book Author
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFF4F4F4).withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
            ],
          ),
        );
      }, childCount: _books.length),
    );
  }
}
