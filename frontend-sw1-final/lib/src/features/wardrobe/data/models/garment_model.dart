class Garment {
  final String id;
  final String? name;
  final String? category;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String path;
  final String pathLocal;
  final String closetId;

  Garment({
    required this.id,
    this.name,
    this.category,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.path,
    required this.pathLocal,
    required this.closetId,
  });

  factory Garment.fromJson(Map<String, dynamic> json) {
    return Garment(
      id: json['id'] as String,
      name: json['name'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      path: json['path'] as String,
      pathLocal: json['pathLocal'] as String? ?? '',
      closetId: json['closetId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'path': path,
      'pathLocal': pathLocal,
      'closetId': closetId,
    };
  }
}
