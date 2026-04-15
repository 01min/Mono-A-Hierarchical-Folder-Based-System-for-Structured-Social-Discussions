class Folder {
  final String id;
  String? parentId; // Added for nested folder support
  String name;
  String icon;
  int colorValue;
  bool isShared;
  String? encryptionKey;
  DateTime createdAt;

  Folder({
    required this.id,
    this.parentId,
    required this.name,
    this.icon = '📁',
    this.colorValue = 0xFF9E9E9E, // Neutral gray default
    this.isShared = false,
    this.encryptionKey,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'isShared': isShared,
      'encryptionKey': encryptionKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<dynamic, dynamic> map) {
    return Folder(
      id: map['id'] as String,
      parentId: map['parentId'] as String?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '📁',
      colorValue: map['colorValue'] as int? ?? 0xFF9E9E9E,
      isShared: map['isShared'] as bool? ?? false,
      encryptionKey: map['encryptionKey'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
