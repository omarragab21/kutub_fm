class AudioStory {
  final String id;
  final String title;
  final String author;
  final String description;
  final String category;
  final String coverUrl;
  final int totalDurationSeconds;
  final int likes;
  final int comments;
  final int shares;
  final int saves;

  AudioStory({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.coverUrl,
    required this.totalDurationSeconds,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.saves,
  });

  // ── Curated Arabic audiobook entries ─────────────────────────────────────

  static AudioStory get theEnemies => AudioStory(
    id: 'story_enemies',
    title: 'الأعداء',
    author: 'تأليف: أنطون تشيخوف | ترجمة: أبي بكر يوسف',
    description:
        'قصة قصيرة للكاتب الروسي الكبير تشيخوف، تستعرض ليلةً مظلمة يلتقي فيها طبيبٌ حزين بعد وفاة ابنه بطلبٍ عاجل من رجل ثريّ لإنقاذ زوجته. رحلة في تناقضات الألم والإنسانية.',
    category: 'قصة قصيرة | أدب روسي',
    coverUrl: 'https://i.ytimg.com/vi/Ie6vcn8gel4/maxresdefault.jpg',
    totalDurationSeconds: 39 * 60,
    likes: 24800,
    comments: 5320,
    shares: 3100,
    saves: 8910,
  );

  static AudioStory get theAlchemist => AudioStory(
    id: 'story_alchemist',
    title: 'الخيميائي',
    author: 'تأليف: باولو كويلو | ترجمة: بدر الديوب',
    description:
        'رواية عالمية تحكي مغامرة راعٍ أندلسي شاب يسعى نحو حلمه ويتعلّم لغة العالم. واحدة من أكثر الكتب مبيعاً في التاريخ، ومُعادة رواياتها بأسلوب صوتيّ شيّق.',
    category: 'رواية | فلسفة',
    coverUrl:
        'https://m.media-amazon.com/images/I/71aFt4+OTOL._AC_UF1000,1000_QL80_.jpg',
    totalDurationSeconds: (4 * 60 + 30) * 60,
    likes: 89400,
    comments: 14200,
    shares: 22000,
    saves: 41300,
  );

  static AudioStory get theStranger => AudioStory(
    id: 'story_stranger',
    title: 'الغريب',
    author: 'تأليف: ألبير كامو | ترجمة: سامي الدروبي',
    description:
        'رواية وجودية فرنسية كلاسيكية لألبير كامو. بطلها مرسو، رجلٌ يواجه الحياة والموت بعيونٍ باردة وغريبة عن العالم من حوله، في تساؤل عميق عن معنى الوجود.',
    category: 'رواية فلسفية | أدب فرنسي',
    coverUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/TheStranger.jpg/800px-TheStranger.jpg',
    totalDurationSeconds: (2 * 60 + 15) * 60,
    likes: 45600,
    comments: 9800,
    shares: 7700,
    saves: 18200,
  );

  static AudioStory get crimeAndPunishment => AudioStory(
    id: 'story_crime',
    title: 'الجريمة والعقاب',
    author: 'تأليف: فيودور دوستويفسكي | ترجمة: سامي الدروبي',
    description:
        'ملحمة أدبية من أعظم روايات الأدب العالمي. تتابع رحلة الطالب الفقير راسكولينيكوف مع الجريمة والذنب والفداء في شوارع سان بطرسبرغ في القرن التاسع عشر.',
    category: 'رواية نفسية | أدب روسي',
    coverUrl: 'https://picsum.photos/seed/story-crime-and-punishment/600/900',
    totalDurationSeconds: (18 * 60 + 40) * 60,
    likes: 67200,
    comments: 11500,
    shares: 14300,
    saves: 29800,
  );

  // ── Static mock list ──────────────────────────────────────────────────────
  static List<AudioStory> get mockList => [
    theEnemies,
    theEnemies,
    theEnemies,
    theEnemies,
  ];
}
