import 'package:uuid/uuid.dart';
import 'book.dart';

/// Livre en attente de validation après reconnaissance OCR
class PendingBook {
  final String id;
  final String deviceId;
  final String imageBase64;
  final String ocrText;
  final Book? recognizedBook;
  final DateTime timestamp;
  final String status; // 'pending', 'validated', 'rejected', 'modified'
  final String? error;
  final Book? finalBook; // Livre final après validation/modification

  PendingBook({
    String? id,
    required this.deviceId,
    required this.imageBase64,
    required this.ocrText,
    this.recognizedBook,
    DateTime? timestamp,
    this.status = 'pending',
    this.error,
    this.finalBook,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();

  PendingBook copyWith({
    String? id,
    String? deviceId,
    String? imageBase64,
    String? ocrText,
    Book? recognizedBook,
    DateTime? timestamp,
    String? status,
    String? error,
    Book? finalBook,
  }) {
    return PendingBook(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      imageBase64: imageBase64 ?? this.imageBase64,
      ocrText: ocrText ?? this.ocrText,
      recognizedBook: recognizedBook ?? this.recognizedBook,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      error: error ?? this.error,
      finalBook: finalBook ?? this.finalBook,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'image_base64': imageBase64,
      'ocr_text': ocrText,
      'recognized_book': recognizedBook?.toMap(),
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'error': error,
      'final_book': finalBook?.toMap(),
    };
  }

  factory PendingBook.fromMap(Map<String, dynamic> map) {
    return PendingBook(
      id: map['id'],
      deviceId: map['device_id'],
      imageBase64: map['image_base64'],
      ocrText: map['ocr_text'],
      recognizedBook: map['recognized_book'] != null 
          ? Book.fromMap(map['recognized_book']) 
          : null,
      timestamp: DateTime.parse(map['timestamp']),
      status: map['status'] ?? 'pending',
      error: map['error'],
      finalBook: map['final_book'] != null 
          ? Book.fromMap(map['final_book']) 
          : null,
    );
  }

  @override
  String toString() {
    return 'PendingBook(id: $id, status: $status, recognizedBook: ${recognizedBook?.title})';
  }
}


