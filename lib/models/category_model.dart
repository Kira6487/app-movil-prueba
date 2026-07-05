class CategoryModel {
  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isActive;
  final String createdAt;

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isActive,
    String? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
