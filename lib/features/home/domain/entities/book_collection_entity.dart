class BookCollectionEntity {
  final String id;
  final String title;
  final String miniDescription;
  final List<String> bookIds;

  BookCollectionEntity({
    required this.id,
    required this.title,
    required this.miniDescription,
    required this.bookIds,
  });
}
