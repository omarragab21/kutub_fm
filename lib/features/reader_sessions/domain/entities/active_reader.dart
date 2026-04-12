class ActiveReader {
  const ActiveReader({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isOnline = true,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
}
