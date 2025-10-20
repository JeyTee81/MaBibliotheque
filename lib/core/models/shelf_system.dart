import '../utils/id_generator.dart';

/// Pièce de la maison (Bureau, Salon, Chambre, etc.)
class Room {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Room({
    String? id,
    required this.name,
    this.description,
    DateTime? createdAt,
  }) : 
    id = id ?? IdGenerator.generateRoomId(),
    createdAt = createdAt ?? DateTime.now();

  Room copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() => 'Room(id: $id, name: $name)';
}

/// Meuble dans une pièce (Meuble 1, Bibliothèque A, etc.)
class Furniture {
  final String id;
  final String roomId;
  final String name;
  final String? description;
  final int numberOfShelves;  // Nombre d'étagères dans ce meuble
  final int placesPerShelf;   // Nombre de places par étagère
  final DateTime createdAt;

  Furniture({
    String? id,
    required this.roomId,
    required this.name,
    this.description,
    required this.numberOfShelves,
    required this.placesPerShelf,
    DateTime? createdAt,
  }) : 
    id = id ?? IdGenerator.generateFurnitureId(),
    createdAt = createdAt ?? DateTime.now();

  /// Nombre total de places dans ce meuble
  int get totalPlaces => numberOfShelves * placesPerShelf;

  Furniture copyWith({
    String? id,
    String? roomId,
    String? name,
    String? description,
    int? numberOfShelves,
    int? placesPerShelf,
    DateTime? createdAt,
  }) {
    return Furniture(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      description: description ?? this.description,
      numberOfShelves: numberOfShelves ?? this.numberOfShelves,
      placesPerShelf: placesPerShelf ?? this.placesPerShelf,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'name': name,
      'description': description,
      'number_of_shelves': numberOfShelves,
      'places_per_shelf': placesPerShelf,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Furniture.fromMap(Map<String, dynamic> map) {
    return Furniture(
      id: map['id'],
      roomId: map['room_id'],
      name: map['name'],
      description: map['description'],
      numberOfShelves: map['number_of_shelves'] ?? 1,
      placesPerShelf: map['places_per_shelf'] ?? 10,
      createdAt: map['created_at'] is DateTime 
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() => 'Furniture(id: $id, name: $name, shelves: $numberOfShelves, places: $placesPerShelf)';
}

/// Position d'un livre dans le système
class BookLocation {
  final String id;
  final String bookId;
  final String furnitureId;
  final int shelfNumber;    // Numéro de l'étagère (1, 2, 3...)
  final int position;       // Position sur l'étagère (1, 2, 3...)
  final DateTime assignedAt;

  BookLocation({
    String? id,
    required this.bookId,
    required this.furnitureId,
    required this.shelfNumber,
    required this.position,
    DateTime? assignedAt,
  }) : 
    id = id ?? IdGenerator.generateLocationId(),
    assignedAt = assignedAt ?? DateTime.now();

  BookLocation copyWith({
    String? id,
    String? bookId,
    String? furnitureId,
    int? shelfNumber,
    int? position,
    DateTime? assignedAt,
  }) {
    return BookLocation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      furnitureId: furnitureId ?? this.furnitureId,
      shelfNumber: shelfNumber ?? this.shelfNumber,
      position: position ?? this.position,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'furniture_id': furnitureId,
      'shelf_number': shelfNumber,
      'position': position,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }

  factory BookLocation.fromMap(Map<String, dynamic> map) {
    return BookLocation(
      id: map['id'],
      bookId: map['book_id'],
      furnitureId: map['furniture_id'],
      shelfNumber: map['shelf_number'] ?? 1,
      position: map['position'] ?? 1,
      assignedAt: map['assigned_at'] is DateTime 
          ? map['assigned_at'] as DateTime
          : DateTime.parse(map['assigned_at'] as String),
    );
  }

  @override
  String toString() => 'BookLocation(bookId: $bookId, furniture: $furnitureId, shelf: $shelfNumber, pos: $position)';
}
