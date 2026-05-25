import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

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
  late Future<_CreatorProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCreator();
  }

  Future<_CreatorProfileData> _loadCreator() async {
    final profile = await _fetchProfile();
    final books = await _fetchBooks(profile);
    return _CreatorProfileData(profile: profile, books: books);
  }

  Future<_CreatorProfile> _fetchProfile() async {
    final id = widget.args.creatorId.trim();
    final fallbackName = widget.args.displayName.trim();
    final collections = [
      'publishers',
      'contributors',
      'authors',
      'readers',
      'narrators',
      'creators',
      'people',
    ];

    if (id.isNotEmpty) {
      for (final collection in collections) {
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(id)
            .get();
        if (doc.exists) {
          return _CreatorProfile.fromMap(
            id: doc.id,
            data: doc.data() ?? const {},
            fallbackName: fallbackName,
            roleLabel: widget.args.roleLabel,
          );
        }
      }
    }

    return _CreatorProfile(
      id: id,
      name: fallbackName.isEmpty ? 'غير معروف' : fallbackName,
      roleLabel: widget.args.roleLabel,
      imageUrl: '',
      bio: '',
      life: '',
    );
  }

  Future<List<_CreatorBook>> _fetchBooks(_CreatorProfile profile) async {
    final id = widget.args.creatorId.trim();
    final name = profile.name.trim();
    final snapshot = await FirebaseFirestore.instance.collection('books').get();
    final books = <_CreatorBook>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_matchesBook(data, id: id, name: name)) continue;
      books.add(_CreatorBook.fromMap(doc.id, data));
    }

    books.sort((a, b) => a.title.compareTo(b.title));
    return books;
  }

  bool _matchesBook(
    Map<String, dynamic> data, {
    required String id,
    required String name,
  }) {
    if (id.isNotEmpty) {
      final publisherIds = [
        data['publisherId'],
        data['publisher_id'],
        _readNested(data, 'publisher.id'),
      ].map((value) => value?.toString()).whereType<String>();
      if (publisherIds.any((value) => value == id)) return true;
    }

    final contributors = data['contributors'] as List<dynamic>? ?? const [];
    for (final contributor in contributors) {
      if (contributor is! Map) continue;
      final contributorId = _readAny(contributor, [
        'id',
        'uid',
        'contributorId',
        'contributor_id',
        'publisherId',
        'publisher_id',
        'personId',
        'person_id',
      ]);
      if (id.isNotEmpty && contributorId == id) return true;

      final contributorName = _readAny(contributor, [
        'nameSnapshot',
        'name',
        'displayName',
      ]);
      if (id.isEmpty && name.isNotEmpty && contributorName == name) {
        return true;
      }
    }

    if (id.isEmpty && name.isNotEmpty) {
      final publisherName =
          data['publisherNameSnapshot']?.toString() ??
          data['publisher']?.toString() ??
          '';
      return publisherName == name;
    }

    return false;
  }

  Object? _readNested(Map<String, dynamic> data, String path) {
    Object? current = data;
    for (final part in path.split('.')) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }

  String _readAny(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          foregroundColor: AppTheme.primary,
          elevation: 0,
          title: Text(widget.args.roleLabel),
        ),
        body: FutureBuilder<_CreatorProfileData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'تعذر تحميل البيانات',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              );
            }

            final data = snapshot.data!;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _profileHeader(data.profile)),
                SliverToBoxAdapter(child: _bioSection(data.profile)),
                SliverToBoxAdapter(child: _booksTitle(data.books.length)),
                if (data.books.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'لا توجد كتب مرتبطة بهذا الحساب بعد.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: data.books.length,
                    itemBuilder: (context, index) =>
                        _bookTile(data.books[index]),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _profileHeader(_CreatorProfile profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
            backgroundImage: profile.imageUrl.isNotEmpty
                ? NetworkImage(profile.imageUrl)
                : null,
            child: profile.imageUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: AppTheme.primary,
                    size: 46,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: AppTheme.primary,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.roleLabel,
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          if (profile.life.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.life,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bioSection(_CreatorProfile profile) {
    if (profile.bio.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          profile.bio,
          style: GoogleFonts.amiri(
            color: AppTheme.onSurface.withValues(alpha: 0.85),
            fontSize: 17,
            height: 1.75,
          ),
        ),
      ),
    );
  }

  Widget _booksTitle(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          Text(
            'الكتب',
            style: GoogleFonts.amiri(
              color: AppTheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '$count كتاب',
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _bookTile(_CreatorBook book) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: book.imageUrl.isEmpty
            ? Container(
                width: 54,
                height: 72,
                color: AppTheme.surface,
                child: const Icon(Icons.book_rounded, color: AppTheme.primary),
              )
            : Image.network(
                book.imageUrl,
                width: 54,
                height: 72,
                fit: BoxFit.cover,
              ),
      ),
      title: Text(
        book.title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        book.category,
        style: const TextStyle(color: AppTheme.onSurfaceVariant),
      ),
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.bookDetails, arguments: book.id);
      },
    );
  }
}

class _CreatorProfileData {
  const _CreatorProfileData({required this.profile, required this.books});

  final _CreatorProfile profile;
  final List<_CreatorBook> books;
}

class _CreatorProfile {
  const _CreatorProfile({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.imageUrl,
    required this.bio,
    required this.life,
  });

  final String id;
  final String name;
  final String roleLabel;
  final String imageUrl;
  final String bio;
  final String life;

  factory _CreatorProfile.fromMap({
    required String id,
    required Map<String, dynamic> data,
    required String fallbackName,
    required String roleLabel,
  }) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = data[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    return _CreatorProfile(
      id: id,
      name: read(['name', 'displayName', 'fullName', 'title']).isNotEmpty
          ? read(['name', 'displayName', 'fullName', 'title'])
          : fallbackName,
      roleLabel: roleLabel,
      imageUrl: read(['imageUrl', 'photoUrl', 'avatarUrl', 'logoUrl']),
      bio: read(['bio', 'biography', 'description', 'about', 'lifeStory']),
      life: read(['life', 'lifeSpan', 'birthDeath', 'dates']),
    );
  }
}

class _CreatorBook {
  const _CreatorBook({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String category;

  factory _CreatorBook.fromMap(String id, Map<String, dynamic> data) {
    final categories = data['categorySnapshots'] as List<dynamic>? ?? const [];
    final category = categories
        .map((item) => item is Map ? item['name']?.toString() ?? '' : '')
        .where((name) => name.isNotEmpty)
        .join('، ');

    return _CreatorBook(
      id: id,
      title: data['title']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      category: category.isNotEmpty ? category : 'كتاب صوتي',
    );
  }
}
