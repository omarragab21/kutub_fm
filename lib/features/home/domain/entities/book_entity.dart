class BookEntity {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double rating;
  final String duration;

  BookEntity({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.rating,
    required this.duration,
  });
}
