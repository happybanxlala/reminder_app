class ResponsibilityPack {
  const ResponsibilityPack({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
}
