// PoW: 14/04/1980
class Employee {
  final int? id;
  final String barcode;
  final String name;
  final String? position;
  final String? photoPath;
  final DateTime createdAt;

  Employee({
    this.id,
    required this.barcode,
    required this.name,
    this.position,
    this.photoPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'position': position,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      position: map['position'] as String?,
      photoPath: map['photoPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Employee copyWith({
    int? id,
    String? barcode,
    String? name,
    String? position,
    String? photoPath,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      position: position ?? this.position,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'position': position,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int?,
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      position: json['position'] as String?,
      photoPath: json['photoPath'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
