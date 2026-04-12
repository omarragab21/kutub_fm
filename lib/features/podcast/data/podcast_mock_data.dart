import '../domain/entities/podcast_episode.dart';
import '../domain/entities/podcast_comment.dart';

class PodcastMockData {
  static List<PodcastEpisode> buildEpisodes() {
    return [
      PodcastEpisode(
        id: 'pod_1',
        title: 'عالم نجيب محفوظ: فلسفة الحارة',
        description:
            'في هذه الحلقة نستكشف الأعماق الفلسفية في روايات نجيب محفوظ، وكيف تحولت الحارة المصرية إلى رمز للكون بأسره. نناقش الصراع بين العلم والإيمان، والبحث عن العدالة المفقودة.',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        imageUrl:
            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=800',
        duration: '٤٥ دقيقة',
        category: 'أدب وفلسفة',
        views: 1240,
        comments: [
          PodcastComment(
            id: 'c1',
            userName: 'أحمد محمود',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=11',
            content:
                'تحليل رائع فعلاً، محفوظ لم يكتب عن حارة بل كتب عن الإنسان في كل مكان.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          PodcastComment(
            id: 'c2',
            userName: 'سارة حسن',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=5',
            content:
                'هل تعتقدون أن الثلاثية هي ذروة أعماله أم أن أولاد حارتنا هي الأكثر جرأة؟',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
            replies: [
              PodcastComment(
                id: 'c3',
                userName: 'ياسين علي',
                userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
                content: 'بكل تأكيد أولاد حارتنا هي الأكثر فلسفة وعمقاً.',
                createdAt: DateTime.now().subtract(const Duration(hours: 4)),
              ),
            ],
          ),
        ],
      ),
      PodcastEpisode(
        id: 'pod_2',
        title: 'الذكاء الاصطناعي ومستقبل الكتابة',
        description:
            'هل سيحل الذكاء الاصطناعي محل الروائيين؟ حوار حول التكنولوجيا والإبداع البشري، وكيف يمكن للأدباء الاستفادة من هذه الأدوات الجديدة دون فقدان روح النص.',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        imageUrl:
            'https://images.unsplash.com/photo-1677442136019-21780ecad995?q=80&w=800',
        duration: '٣٢ دقيقة',
        category: 'تكنولوجيا وأدب',
        views: 850,
        comments: [],
      ),
      PodcastEpisode(
        id: 'pod_3',
        title: 'فن الرواية عند ميلان كونديرا',
        description:
            'مراجعة لكتاب "فن الرواية" لميلان كونديرا، والحديث عن خفة الكائن التي لا تحتمل، وكيف يعالج كونديرا الوجود من خلال السرد الروائي المبتكر.',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        imageUrl:
            'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=800',
        duration: '٥٨ دقيقة',
        category: 'مراجعات كتب',
        views: 2100,
        comments: [],
      ),
    ];
  }
}
