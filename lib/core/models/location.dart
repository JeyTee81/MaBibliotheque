import 'package:uuid/uuid.dart';

class Location {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    String? id,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Location copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'Location(id: $id, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Shelf {
  final String id;
  final String locationId;
  final String name;
  final String? description;
  final int maxBooks;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shelf({
    String? id,
    required this.locationId,
    required this.name,
    this.description,
    this.maxBooks = 50,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Shelf copyWith({
    String? id,
    String? locationId,
    String? name,
    String? description,
    int? maxBooks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shelf(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      description: description ?? this.description,
      maxBooks: maxBooks ?? this.maxBooks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location_id': locationId,
      'name': name,
      'description': description,
      'max_books': maxBooks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Shelf.fromMap(Map<String, dynamic> map) {
    return Shelf(
      id: map['id'],
      locationId: map['location_id'],
      name: map['name'],
      description: map['description'],
      maxBooks: map['max_books'] ?? 50,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'Shelf(id: $id, locationId: $locationId, name: $name, maxBooks: $maxBooks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shelf && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class BookPosition {
  final String id;
  final String bookId;
  final String shelfId;
  final int position;
  final DateTime assignedAt;
  final DateTime updatedAt;

  BookPosition({
    String? id,
    required this.bookId,
    required this.shelfId,
    required this.position,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    assignedAt = assignedAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  BookPosition copyWith({
    String? id,
    String? bookId,
    String? shelfId,
    int? position,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) {
    return BookPosition(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      shelfId: shelfId ?? this.shelfId,
      position: position ?? this.position,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'shelf_id': shelfId,
      'position': position,
      'assigned_at': assignedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BookPosition.fromMap(Map<String, dynamic> map) {
    return BookPosition(
      id: map['id'],
      bookId: map['book_id'],
      shelfId: map['shelf_id'],
      position: map['position'],
      assignedAt: DateTime.parse(map['assigned_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'BookPosition(id: $id, bookId: $bookId, shelfId: $shelfId, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookPosition && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
