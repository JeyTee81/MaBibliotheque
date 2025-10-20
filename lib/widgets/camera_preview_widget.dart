import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';

import '../core/config/app_config.dart';

class CameraPreviewWidget extends StatefulWidget {
  final Function(File) onImageCaptured;
  final VoidCallback? onCancel;

  const CameraPreviewWidget({
    super.key,
    required this.onImageCaptured,
    this.onCancel,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  static final Logger _logger = Logger();
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _logger.i('Initializing camera...');
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        _logger.e('No cameras available');
        _showError('Aucune caméra disponible. Veuillez vérifier que votre webcam est connectée et autorisée.');
        return;
      }

      _logger.i('Found ${_cameras!.length} cameras');
      
      // Utiliser la première caméra disponible (généralement la webcam)
      final camera = _cameras!.first;
      _logger.i('Using camera: ${camera.name}');
      
      _controller = CameraController(
        camera,
        ResolutionPreset.low, // Utiliser low pour éviter les problèmes de performance
        enableAudio: false,
      );

      await _controller!.initialize();
      _logger.i('Camera initialized successfully');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _logger.e('Camera initialization error: $e');
      _showError('Erreur lors de l\'initialisation de la caméra: $e\n\nVeuillez vérifier que votre webcam est autorisée dans les paramètres Windows.');
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'book_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(appDir.path, fileName);

      final XFile image = await _controller!.takePicture();
      
      // Copier l'image vers le répertoire de l'application
      final File imageFile = File(image.path);
      final File savedImage = await imageFile.copy(filePath);
      
      widget.onImageCaptured(savedImage);
    } catch (e) {
      _showError('Erreur lors de la capture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppConfig.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(AppConfig.spacingL),
        child: Column(
          children: [
            Text(
              'Prendre une photo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConfig.spacingM),
            
            Expanded(
              child: _buildCameraPreview(),
            ),
            
            const SizedBox(height: AppConfig.spacingM),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton d'annulation
                ElevatedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('Annuler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                // Bouton de capture
                ElevatedButton.icon(
                  onPressed: _isInitialized && !_isCapturing ? _captureImage : null,
                  icon: _isCapturing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                  label: Text(_isCapturing ? 'Capture...' : 'Prendre la photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: AppConfig.spacingM),
              Text(
                'Initialisation de la caméra...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: AppConfig.primaryColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }
}
