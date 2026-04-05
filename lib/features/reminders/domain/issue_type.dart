class IssueTypeModel {
  const IssueTypeModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
}
