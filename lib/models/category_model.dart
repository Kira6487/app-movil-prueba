class CategoryModel {
  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    String? icon,
    String? color,
    String? iconKey,
    String? colorHex,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  })  : iconKey = iconKey ?? icon,
        colorHex = colorHex ?? color;

  final int? id;
  final String name;
  final String type;
  final String? iconKey;
  final String? colorHex;
  final int sortOrder;
  final bool isActive;
  final String createdAt;

  String? get icon => iconKey;
  String? get color => colorHex;

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      iconKey: _readString(map, 'icon_key') ?? _readString(map, 'icon'),
      colorHex: _readString(map, 'color_hex') ?? _readString(map, 'color'),
      sortOrder: ((map['sort_order'] as num?) ?? 0).toInt(),
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': iconKey,
      'color': colorHex,
      'icon_key': iconKey,
      'color_hex': colorHex,
      'sort_order': sortOrder,
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
    String? iconKey,
    String? colorHex,
    int? sortOrder,
    bool? isActive,
    String? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? icon ?? this.iconKey,
      colorHex: colorHex ?? color ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String? _readString(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) return null;
    return map[key] as String?;
  }
}

class CategoryScope {
  const CategoryScope._();

  static const expense = 'expense';
  static const income = 'income';
  static const savings = 'savings';
  static const system = 'system';

  static const editableValues = [expense, income, savings];
  static const values = [expense, income, savings, system];

  static String label(String value) => switch (value) {
        expense => 'Gastos',
        income => 'Ingresos',
        savings => 'Ahorros',
        system => 'Sistema',
        _ => value,
      };
}
