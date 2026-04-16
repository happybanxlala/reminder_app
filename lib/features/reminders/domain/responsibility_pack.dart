enum ResponsibilityPackStatus { active, archived }

class ResponsibilityPackInput {
  const ResponsibilityPackInput({required this.title, this.description});

  final String title;
  final String? description;
}

class ResponsibilityPack {
  const ResponsibilityPack({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.isSystemDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final ResponsibilityPackStatus status;
  final bool isSystemDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
}
