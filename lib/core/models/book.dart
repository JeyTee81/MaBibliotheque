import '../utils/id_generator.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? publisher;
  final DateTime? publicationDate;
  final String? genre;
  final String? description;
  final String? coverImageUrl;
  final String? coverImagePath;
  final int? pageCount;
  final String? language;
  final double? rating;
  final String? furnitureId;  // ID du meuble où se trouve le livre
  final int? shelfNumber;     // Numéro de l'étagère (1, 2, 3...)
  final int? position;        // Position sur l'étagère (1, 2, 3...)
  final DateTime addedDate;
  final DateTime updatedAt;
  final bool isRead;
  final DateTime? readDate;
  final String? notes;

  Book({
    String? id,
    required this.title,
    required this.author,
    this.isbn,
    this.publisher,
    this.publicationDate,
    this.genre,
    this.description,
    this.coverImageUrl,
    this.coverImagePath,
    this.pageCount,
    this.language,
    this.rating,
    this.furnitureId,
    this.shelfNumber,
    this.position,
    DateTime? addedDate,
    DateTime? updatedAt,
    this.isRead = false,
    this.readDate,
    this.notes,
  }) : 
    id = id ?? IdGenerator.generateBookId(),
    addedDate = addedDate ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? publisher,
    DateTime? publicationDate,
    String? genre,
    String? description,
    String? coverImageUrl,
    String? coverImagePath,
    int? pageCount,
    String? language,
    double? rating,
    String? furnitureId,
    int? shelfNumber,
    int? position,
    DateTime? addedDate,
    DateTime? updatedAt,
    bool? isRead,
    DateTime? readDate,
    String? notes,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publicationDate: publicationDate ?? this.publicationDate,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      pageCount: pageCount ?? this.pageCount,
      language: language ?? this.language,
      rating: rating ?? this.rating,
      furnitureId: furnitureId ?? this.furnitureId,
      shelfNumber: shelfNumber ?? this.shelfNumber,
      position: position ?? this.position,
      addedDate: addedDate ?? this.addedDate,
      updatedAt: updatedAt ?? DateTime.now(),
      isRead: isRead ?? this.isRead,
      readDate: readDate ?? this.readDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publisher': publisher,
      'publication_date': publicationDate?.toIso8601String(),
      'genre': genre,
      'description': description,
      'cover_image_url': coverImageUrl,
      'cover_image_path': coverImagePath,
      'page_count': pageCount,
      'language': language,
      'rating': rating,
      'furniture_id': furnitureId,
      'shelf_number': shelfNumber,
      'position': position,
      'added_date': addedDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'read_date': readDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      isbn: map['isbn'],
      publisher: map['publisher'],
      publicationDate: map['publication_date'] != null 
          ? (map['publication_date'] is DateTime 
              ? map['publication_date'] as DateTime
              : DateTime.parse(map['publication_date'] as String))
          : null,
      genre: map['genre'],
      description: map['description'],
      coverImageUrl: map['cover_image_url'],
      coverImagePath: map['cover_image_path'],
      pageCount: map['page_count'],
      language: map['language'],
      rating: map['rating']?.toDouble(),
      furnitureId: map['furniture_id'],
      shelfNumber: map['shelf_number'],
      position: map['position'],
      addedDate: map['added_date'] is DateTime 
          ? map['added_date'] as DateTime
          : DateTime.parse(map['added_date'] as String),
      updatedAt: map['updated_at'] is DateTime 
          ? map['updated_at'] as DateTime
          : DateTime.parse(map['updated_at'] as String),
      isRead: map['is_read'] == 1,
      readDate: map['read_date'] != null 
          ? (map['read_date'] is DateTime 
              ? map['read_date'] as DateTime
              : DateTime.parse(map['read_date'] as String))
          : null,
      notes: map['notes'],
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, isbn: $isbn)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

