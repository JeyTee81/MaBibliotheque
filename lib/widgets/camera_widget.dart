import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';

class CameraWidget extends StatefulWidget {
  final Function(File) onImageCaptured;
  final VoidCallback? onCancel;

  const CameraWidget({
    super.key,
    required this.onImageCaptured,
    this.onCancel,
  });

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: AppConfig.imageQuality,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        widget.onImageCaptured(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de photo: $e'),
            backgroundColor: AppConfig.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConfig.imageQuality,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        widget.onImageCaptured(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: AppConfig.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppConfig.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sélectionner une image',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConfig.spacingL),
            
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: AppConfig.spacingM),
              const Text('Traitement en cours...'),
            ] else ...[
              // Bouton pour prendre une photo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Prendre une photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConfig.spacingM,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppConfig.spacingM),
              
              // Bouton pour choisir depuis la galerie
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choisir depuis la galerie'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConfig.spacingM,
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: AppConfig.spacingL),
            
            // Bouton d'annulation
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
