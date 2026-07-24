import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/podcast.dart';
import '../../domain/entities/podcast_episode.dart';
import '../../domain/entities/podcast_comment.dart';

class PodcastProvider extends ChangeNotifier {
  final List<Podcast> _podcasts = defaultPodcastsList;
  List<PodcastEpisode> _episodes = [];
  bool _isLoading = false;
  String? _error;

  List<Podcast> get podcasts => List.unmodifiable(_podcasts);

  List<Podcast> get popularPodcasts {
    final list = _podcasts.where((p) => p.isPopular).toList();
    if (list.isNotEmpty) return List.unmodifiable(list);
    return List.unmodifiable(_podcasts);
  }

  List<PodcastEpisode> get trendingEpisodes {
    final trending = <PodcastEpisode>[];
    for (final podcast in _podcasts) {
      for (final season in podcast.seasons) {
        for (final ep in season.episodes) {
          if (ep.isTrending) {
            trending.add(ep);
          }
        }
      }
    }
    if (trending.isNotEmpty) return List.unmodifiable(trending);

    // Fallback to all episodes
    return allEpisodes;
  }

  List<PodcastEpisode> get allEpisodes {
    if (_episodes.isNotEmpty) return List.unmodifiable(_episodes);
    final all = <PodcastEpisode>[];
    for (final p in _podcasts) {
      all.addAll(p.allEpisodes);
    }
    return List.unmodifiable(all);
  }

  List<PodcastEpisode> get episodes => allEpisodes;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Podcast? getPodcastById(String id) {
    try {
      return _podcasts.firstWhere((p) => p.id == id);
    } catch (_) {
      try {
        return _podcasts.firstWhere((p) => p.title == id);
      } catch (_) {
        return null;
      }
    }
  }

  Podcast? getPodcastByTitle(String title) {
    try {
      return _podcasts.firstWhere((p) => p.title == title);
    } catch (_) {
      try {
        return _podcasts.firstWhere((p) => p.id == title);
      } catch (_) {
        return null;
      }
    }
  }

  PodcastEpisode? getEpisodeById(String episodeId) {
    for (final p in _podcasts) {
      for (final s in p.seasons) {
        for (final ep in s.episodes) {
          if (ep.id == episodeId) return ep;
        }
      }
    }
    try {
      return _episodes.firstWhere((e) => e.id == episodeId);
    } catch (_) {
      return null;
    }
  }

  List<PodcastEpisode> episodesForProgram(String programTitle) {
    final podcast = _podcasts.firstWhere(
      (p) => p.title == programTitle || p.id == programTitle,
      orElse: () => _podcasts.first,
    );
    return podcast.allEpisodes;
  }

  PodcastProvider() {
    loadEpisodes();
  }

  Future<void> loadEpisodes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('podcasts')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docs = querySnapshot.docs.toList();
        docs.sort((a, b) {
          final aData = a.data();
          final bData = b.data();
          final aTime = aData['createdAt']?.toString() ?? '';
          final bTime = bData['createdAt']?.toString() ?? '';
          return bTime.compareTo(aTime);
        });

        final List<PodcastEpisode> loadedEpisodes = [];
        for (final doc in docs) {
          final data = doc.data();

          final commentsRaw = data['comments'] as List<dynamic>? ?? [];
          final comments = commentsRaw
              .map((c) => _mapToComment(Map<String, dynamic>.from(c)))
              .toList();

          loadedEpisodes.add(
            PodcastEpisode(
              id: doc.id,
              title: data['title']?.toString() ?? '',
              description: data['description']?.toString() ?? '',
              audioUrl: data['audioUrl']?.toString() ?? '',
              youtubeUrl: data['youtubeUrl']?.toString(),
              imageUrl: data['imageUrl']?.toString() ?? '',
              duration: data['duration']?.toString() ?? '١٠ دقائق',
              category: data['category']?.toString() ?? 'بودكاست',
              views: (data['views'] as num?)?.toInt() ?? 0,
              programTitle: data['programTitle']?.toString() ?? '',
              season: (data['season'] as num?)?.toInt() ?? 1,
              episodeNumber: (data['episodeNumber'] as num?)?.toInt() ?? 1,
              publishedAgo: data['publishedAgo']?.toString(),
              isTrending: data['isTrending'] as bool? ?? false,
              publishedAt: _parseNullableDateTime(
                data['publishedAt'] ?? data['createdAt'],
              ),
              comments: comments,
            ),
          );
        }
        _episodes = loadedEpisodes;
      }
    } catch (e) {
      debugPrint('Firestore podcasts fetch error, using default podcasts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _commentToMap(PodcastComment comment) {
    return {
      'id': comment.id,
      'userName': comment.userName,
      'userAvatarUrl': comment.userAvatarUrl,
      'content': comment.content,
      'createdAt': comment.createdAt.toIso8601String(),
      'replies': comment.replies.map((r) => _commentToMap(r)).toList(),
    };
  }

  PodcastComment _mapToComment(Map<String, dynamic> map) {
    final repliesRaw = map['replies'] as List<dynamic>? ?? [];
    return PodcastComment(
      id: map['id']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      userAvatarUrl: map['userAvatarUrl']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      replies: repliesRaw
          .map((r) => _mapToComment(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }

  DateTime _parseDateTime(dynamic val) {
    return _parseNullableDateTime(val) ?? DateTime.now();
  }

  DateTime? _parseNullableDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  Future<void> addComment(
    String episodeId,
    String content, {
    String? parentCommentId,
  }) async {
    final allEp = allEpisodes;
    final index = allEp.indexWhere((e) => e.id == episodeId);
    if (index == -1) return;

    final newComment = PodcastComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: 'أنت',
      userAvatarUrl: 'https://i.pravatar.cc/150?img=65',
      content: content,
      createdAt: DateTime.now(),
    );

    final episode = allEp[index];
    List<PodcastComment> updatedComments;

    if (parentCommentId == null) {
      updatedComments = [newComment, ...episode.comments];
    } else {
      updatedComments = _addReply(
        episode.comments,
        parentCommentId,
        newComment,
      );
    }

    notifyListeners();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('podcasts')
          .doc(episodeId);
      await docRef.update({
        'comments': updatedComments.map((c) => _commentToMap(c)).toList(),
      });
    } catch (e) {
      debugPrint('Failed to save comment to Firestore: $e');
    }
  }

  List<PodcastComment> _addReply(
    List<PodcastComment> comments,
    String parentId,
    PodcastComment newReply,
  ) {
    return comments.map((comment) {
      if (comment.id == parentId) {
        return comment.copyWith(replies: [...comment.replies, newReply]);
      } else if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _addReply(comment.replies, parentId, newReply),
        );
      }
      return comment;
    }).toList();
  }

  static final List<Podcast> defaultPodcastsList = [
    Podcast(
      id: 'qabl_tay_al_safha',
      title: 'قبل طيّ الصفحة',
      author: 'عامر واجد',
      description:
          'قبل طيّ الصفحة هو بودكاست لعشّاق الكتب والأفكار. في كل حلقة نسلّط الضوء على كتاب مختلف، نلخّص أبرز أفكاره، ونناقش الدروس والرؤى التي يمكن أن تغيّر طريقة تفكيرنا ونظرتنا للحياة. من الروايات الملهمة إلى الكتب الفكرية والتطويرية، نرافقك في رحلة معرفية ممتعة تجعل كل صفحة بداية لفكرة جديدة، وكل كتاب تجربة تستحق أن تُروى. لا تطوِ الصفحة بعد... فما زالت هناك قصة تنتظر أن تُحكى.',
      imageUrl:
          'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
      bannerUrl:
          'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=1200',
      totalEpisodes: 13,
      isPopular: true,
      viewsCount: 14500,
      seasons: const [
        PodcastSeason(
          id: 'season_1',
          name: 'الموسم الأول',
          seasonNumber: 1,
          episodes: [
            PodcastEpisode(
              id: 'qabl_s1_ep1',
              title: 'لماذا الكتب ؟',
              description:
                  'حلقة تتناول القوة السحرية للقراءة وكيف تغير الفكرة مسار حياة الإنسان، وأهمية كتابة القراءة واختيار الكتب المناسبة.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
              duration: '2:30 د',
              category: 'أدب وفلسفة',
              views: 2400,
              programTitle: 'قبل طيّ الصفحة',
              programId: 'qabl_tay_al_safha',
              author: 'عامر واجد',
              season: 1,
              episodeNumber: 1,
              publishedAgo: 'قبل شهر',
              isTrending: false,
            ),
            PodcastEpisode(
              id: 'qabl_s1_ep2',
              title: 'كيف يشكل الكتاب عقلك',
              description:
                  'نستكشف الأثر العصبي والنفسي للقراءة المنتظمة وكيفية تحسين الفهم وتوسيع المدارك الذهنية.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
              duration: '30:00 د',
              category: 'تطوير الذات',
              views: 3100,
              programTitle: 'قبل طيّ الصفحة',
              programId: 'qabl_tay_al_safha',
              author: 'عامر واجد',
              season: 1,
              episodeNumber: 2,
              publishedAgo: '12 نوفمبر',
              isTrending: false,
            ),
            PodcastEpisode(
              id: 'qabl_s1_ep3',
              title: 'تنظيم الفوضى • العادات الذرية',
              description:
                  'تأملات في كتاب العادات الذرية وكيف يمكن للتغييرات الصغيرة اليومية أن تصنع فارقاً هائلاً على المدى الطويل.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
              duration: '01:00 س',
              category: 'تطوير الذات',
              views: 4500,
              programTitle: 'قبل طيّ الصفحة',
              programId: 'qabl_tay_al_safha',
              author: 'عامر واجد',
              season: 1,
              episodeNumber: 3,
              publishedAgo: '25 اكتوبر',
              isTrending: false,
            ),
            PodcastEpisode(
              id: 'qabl_s1_ep4',
              title: 'العادات السبع للأسر الأكثر فعالية',
              description:
                  'قراءة واستعراض لأهم المبادئ التي ترتكز عليها العائلات الناجحة والمترابطة لبناء بيئة صحية ومثمرة.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
              duration: '01:20 س',
              category: 'علاقات ومجتمع',
              views: 2900,
              programTitle: 'قبل طيّ الصفحة',
              programId: 'qabl_tay_al_safha',
              author: 'عامر واجد',
              season: 1,
              episodeNumber: 4,
              publishedAgo: '6 يونيو',
              isTrending: false,
            ),
            PodcastEpisode(
              id: 'qabl_s1_ep10',
              title: 'كيف اصبحنا اسرى العالم الرقمي ؟!',
              description:
                  'نقاش عميق حول التشتت الرقمي، تأثير منصات التواصل على انتباهنا وصحتنا النفسية، وكيف نستعيد التحكم في وقتنا.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
              duration: '3:10 د',
              category: 'تقنية ومجتمع',
              views: 6200,
              programTitle: 'قبل طيّ الصفحة',
              programId: 'qabl_tay_al_safha',
              author: 'عامر واجد',
              season: 1,
              episodeNumber: 10,
              publishedAgo: 'أمس',
              isTrending: true,
            ),
          ],
        ),
        PodcastSeason(
          id: 'season_2',
          name: 'الموسم الثاني',
          seasonNumber: 2,
          episodes: [
            PodcastEpisode(
              id: 'qabl_s2_ep22',
              title: 'كيف تبني نظامًا لا يسقط؟',
              description:
                  'حلقة تتحدث عن بناء الأنظمة الشخصية والمرونة في مواجهة المتغيرات والأزمات غير المتوقعة.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
              duration: '1:55 س',
              category: 'فلسفة وإدارة',
              views: 8900,
              programTitle: 'قبل طيّ الصفحة',
              programId: 'qabl_tay_al_safha',
              author: 'عامر واجد',
              season: 2,
              episodeNumber: 22,
              publishedAgo: 'قبل اسبوع',
              isTrending: true,
            ),
          ],
        ),
      ],
    ),
    Podcast(
      id: 'waraa_al_molsaq_al_ghizaei',
      title: 'وراء الملصق الغذائي',
      author: 'منى رجب',
      description:
          'بودكاست يسلط الضوء على خفايا الملصقات الغذائية وما تتناوله يومياً كاشفاً الأسرار وتصحيح المفاهيم التغذوية.',
      imageUrl:
          'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800',
      totalEpisodes: 6,
      isPopular: true,
      viewsCount: 9200,
      seasons: const [
        PodcastSeason(
          id: 'season_1',
          name: 'الموسم الأول',
          seasonNumber: 1,
          episodes: [
            PodcastEpisode(
              id: 'waraa_ep1',
              title: 'رحلة في عالم المكونات',
              description:
                  'كيف تقرأ قائمة المكونات والقيمة الغذائية وتكتشف المكونات الخفية في الأطعمة المصنعة.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800',
              duration: '15:00 د',
              category: 'صحة وتغذية',
              views: 4100,
              programTitle: 'وراء الملصق الغذائي',
              programId: 'waraa_al_molsaq_al_ghizaei',
              author: 'منى رجب',
              season: 1,
              episodeNumber: 1,
              publishedAgo: 'قبل أسبوع',
              isTrending: false,
            ),
            PodcastEpisode(
              id: 'waraa_ep5',
              title: 'لما لا تتقبل نفسك ؟',
              description:
                  'مناقشة الصورة الذهنية للجسم وعلاقتها بالنظام الغذائي والسلام النفسي.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800',
              duration: '2:30 د',
              category: 'صحة ونفس',
              views: 5100,
              programTitle: 'وراء الملصق الغذائي',
              programId: 'waraa_al_molsaq_al_ghizaei',
              author: 'منى رجب',
              season: 1,
              episodeNumber: 5,
              publishedAgo: 'قبل شهر',
              isTrending: true,
            ),
          ],
        ),
      ],
    ),
    Podcast(
      id: 'akher_geel_bashari',
      title: 'آخر جيل بشري',
      author: 'اسرار محمود',
      description:
          'رحلة تفاعلية استكشافية لمستقبل البشرية في ظل التطور التكنولوجي والذكاء الاصطناعي والهندسة الوراثية.',
      imageUrl:
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800',
      totalEpisodes: 3,
      isPopular: true,
      viewsCount: 6300,
      seasons: const [
        PodcastSeason(
          id: 'season_1',
          name: 'الموسم الأول',
          seasonNumber: 1,
          episodes: [
            PodcastEpisode(
              id: 'akher_ep1',
              title: 'مقدمة عن جيل الغد',
              description:
                  'نستعرض الأسئلة الكبرى حول الاندماج بين الإنسان والآلة ومستقبل الهوية البشرية.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/A_Day_Without_Rain.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800',
              duration: '15:00 د',
              category: 'مستقبليات وتكنولوجيا',
              views: 6300,
              programTitle: 'آخر جيل بشري',
              programId: 'akher_geel_bashari',
              author: 'اسرار محمود',
              season: 1,
              episodeNumber: 1,
              publishedAgo: 'قبل شهر',
              isTrending: false,
            ),
          ],
        ),
      ],
    ),
    Podcast(
      id: 'shiraa_al_saada_bel_mal',
      title: 'شراء السعادة بالمال',
      author: 'سامر خشّاب',
      description:
          'هل المال يشتري السعادة حقاً؟ مناقشة فلسفية واقتصادية شيقة تطرح أفكاراً جديدة حول الثروة وجودة الحياة.',
      imageUrl:
          'https://images.unsplash.com/photo-1565514020179-026b92b84bb6?w=800',
      totalEpisodes: 10,
      isPopular: true,
      viewsCount: 7800,
      seasons: const [
        PodcastSeason(
          id: 'season_1',
          name: 'الموسم الأول',
          seasonNumber: 1,
          episodes: [
            PodcastEpisode(
              id: 'saada_ep1',
              title: 'فلسفة الاقتناء',
              description:
                  'كيف يؤثر الاستهلاك واقتناء الأشياء على مشاعر الرضا والسعادة بعيدة المدى.',
              audioUrl:
                  'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/radio/kutub_fm_radio/hans_zimmer_dark_knight.mp3',
              imageUrl:
                  'https://images.unsplash.com/photo-1565514020179-026b92b84bb6?w=800',
              duration: '45:00 د',
              category: 'اقتصاد ونفس',
              views: 7800,
              programTitle: 'شراء السعادة بالمال',
              programId: 'shiraa_al_saada_bel_mal',
              author: 'سامر خشّاب',
              season: 1,
              episodeNumber: 1,
              publishedAgo: 'قبل شهر',
              isTrending: false,
            ),
          ],
        ),
      ],
    ),
  ];
}

