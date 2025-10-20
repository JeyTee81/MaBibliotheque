import '../utils/id_generator.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? passwordHash;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  User({
    String? id,
    required this.email,
    required this.name,
    this.passwordHash,
    this.profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : 
    id = id ?? IdGenerator.generateUserId(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? passwordHash,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'password_hash': passwordHash,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      passwordHash: map['password_hash'],
      profileImageUrl: map['profile_image_url'],
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at'] as DateTime
          : DateTime.parse(map['updated_at'] as String),
      isActive: map['is_active'] == 1,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Getter pour compatibilité avec le code existant
  String get username => email.split('@').first;
}

