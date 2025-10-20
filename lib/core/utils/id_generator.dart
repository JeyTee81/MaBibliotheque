/// Générateur d'IDs cohérents pour l'application
class IdGenerator {
  static int _roomCounter = 1;
  static int _furnitureCounter = 1;
  static int _bookCounter = 1;
  static int _userCounter = 1;
  static int _locationCounter = 1;
  static int _ocrJobCounter = 1;

  /// Génère un ID simple pour une pièce
  static String generateRoomId() {
    return 'room-$_roomCounter';
  }

  /// Génère un ID simple pour un meuble
  static String generateFurnitureId() {
    return 'furniture-$_furnitureCounter';
  }

  /// Génère un ID simple pour un livre
  static String generateBookId() {
    return 'book-$_bookCounter';
  }

  /// Génère un ID simple pour un utilisateur
  static String generateUserId() {
    return 'user-$_userCounter';
  }

  /// Génère un ID simple pour une localisation de livre
  static String generateLocationId() {
    return 'location-$_locationCounter';
  }

  /// Génère un ID simple pour un travail OCR
  static String generateOcrJobId() {
    return 'ocr-$_ocrJobCounter';
  }

  /// Incrémente les compteurs (appelé après création réussie)
  static void incrementCounters({
    bool room = false,
    bool furniture = false,
    bool book = false,
    bool user = false,
    bool location = false,
    bool ocrJob = false,
  }) {
    if (room) _roomCounter++;
    if (furniture) _furnitureCounter++;
    if (book) _bookCounter++;
    if (user) _userCounter++;
    if (location) _locationCounter++;
    if (ocrJob) _ocrJobCounter++;
  }

  /// Parse un ID existant pour mettre à jour les compteurs
  static void updateCountersFromExistingIds(List<String> existingIds) {
    for (final id in existingIds) {
      if (id.startsWith('room-')) {
        final number = int.tryParse(id.substring(5));
        if (number != null && number >= _roomCounter) {
          _roomCounter = number + 1;
        }
      } else if (id.startsWith('furniture-')) {
        final number = int.tryParse(id.substring(10));
        if (number != null && number >= _furnitureCounter) {
          _furnitureCounter = number + 1;
        }
      } else if (id.startsWith('book-')) {
        final number = int.tryParse(id.substring(5));
        if (number != null && number >= _bookCounter) {
          _bookCounter = number + 1;
        }
      } else if (id.startsWith('user-')) {
        final number = int.tryParse(id.substring(5));
        if (number != null && number >= _userCounter) {
          _userCounter = number + 1;
        }
      } else if (id.startsWith('location-')) {
        final number = int.tryParse(id.substring(9));
        if (number != null && number >= _locationCounter) {
          _locationCounter = number + 1;
        }
      } else if (id.startsWith('ocr-')) {
        final number = int.tryParse(id.substring(4));
        if (number != null && number >= _ocrJobCounter) {
          _ocrJobCounter = number + 1;
        }
      }
    }
  }
}


