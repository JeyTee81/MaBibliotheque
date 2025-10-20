import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../../widgets/camera_preview_widget.dart';

class CameraService {
  static final Logger _logger = Logger();
  final ImagePicker _picker = ImagePicker();

  /// Prend une photo avec la webcam en utilisant le widget de prévisualisation
  Future<File?> takePictureWithPreview(BuildContext context) async {
    try {
      _logger.i('Taking picture with camera preview');
      
      // Vérifier d'abord si des caméras sont disponibles
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _logger.w('No cameras available for preview');
        return null;
      }
      
      _logger.i('Found ${cameras.length} cameras, opening preview');
      
      File? capturedImage;
      
      await showDialog<File?>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CameraPreviewWidget(
            onImageCaptured: (File image) {
              capturedImage = image;
              Navigator.of(context).pop(image);
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
      
      if (capturedImage != null) {
        _logger.i('Picture taken successfully: ${capturedImage!.path}');
        return capturedImage;
      } else {
        _logger.w('No image captured from preview');
        return null;
      }
    } catch (e) {
      _logger.e('Error taking picture with preview: $e');
      return null; // Retourner null au lieu de rethrow pour permettre le fallback
    }
  }

  /// Prend une photo avec la webcam (méthode de fallback)
  Future<File?> takePicture() async {
    try {
      _logger.i('Taking picture with camera (fallback)');
      
      // Sur Windows, utiliser la webcam
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: AppConfig.imageQuality,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        final file = File(image.path);
        _logger.i('Picture taken successfully: ${file.path}');
        return file;
      } else {
        _logger.w('No image selected');
        return null;
      }
    } catch (e) {
      _logger.e('Error taking picture: $e');
      rethrow;
    }
  }

  /// Sélectionne une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      _logger.i('Picking image from gallery');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConfig.imageQuality,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        final file = File(image.path);
        _logger.i('Image selected from gallery: ${file.path}');
        return file;
      } else {
        _logger.w('No image selected from gallery');
        return null;
      }
    } catch (e) {
      _logger.e('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Affiche un dialogue pour choisir entre caméra et galerie
  Future<File?> showImageSourceDialog(BuildContext context) async {
    _logger.i('Showing image source dialog');
    
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner une image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () async {
                  _logger.i('Camera option selected');
                  try {
                    // Essayer d'abord la méthode de prévisualisation
                    File? file = await takePictureWithPreview(context);
                    
                    // Si ça ne fonctionne pas, essayer la méthode de fallback
                    if (file == null) {
                      _logger.w('Camera preview failed, trying fallback method');
                      file = await takePicture();
                    }
                    
                    _logger.i('Camera result: ${file != null ? "Success" : "Failed"}');
                    if (context.mounted) {
                      Navigator.of(context).pop(file);
                    }
                  } catch (e) {
                    _logger.e('Camera error: $e');
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      _showErrorDialog(context, 'Erreur lors de la prise de photo: $e\n\nVeuillez utiliser l\'option "Choisir depuis la galerie" à la place.');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  _logger.i('Gallery option selected');
                  try {
                    final file = await pickImageFromGallery();
                    _logger.i('Gallery result: ${file != null ? "Success" : "Failed"}');
                    if (context.mounted) {
                      Navigator.of(context).pop(file);
                    }
                  } catch (e) {
                    _logger.e('Gallery error: $e');
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      _showErrorDialog(context, 'Erreur lors de la sélection: $e');
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _logger.i('Dialog cancelled');
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Vérifie si la caméra est disponible
  Future<bool> isCameraAvailable() async {
    try {
      // Tenter de lister les caméras disponibles
      final cameras = await _picker.pickImage(source: ImageSource.camera);
      return true;
    } catch (e) {
      _logger.w('Camera not available: $e');
      return false;
    }
  }

  /// Obtient les informations sur l'image
  Future<Map<String, dynamic>?> getImageInfo(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return null;
      }

      final stat = await imageFile.stat();
      final sizeInMB = stat.size / (1024 * 1024);

      return {
        'path': imageFile.path,
        'size': stat.size,
        'sizeInMB': sizeInMB,
        'modified': stat.modified,
        'isValid': sizeInMB <= (AppConfig.maxImageSize / (1024 * 1024)),
      };
    } catch (e) {
      _logger.e('Error getting image info: $e');
      return null;
    }
  }
}
