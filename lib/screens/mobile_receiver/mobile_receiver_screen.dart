import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

import '../../providers/books_provider.dart';
import '../../providers/ocr_provider.dart';
import '../../providers/pending_books_provider.dart';
import '../../core/models/book.dart';
import '../../core/models/pending_book.dart';

class MobileReceiverScreen extends StatefulWidget {
  const MobileReceiverScreen({super.key});

  @override
  State<MobileReceiverScreen> createState() => _MobileReceiverScreenState();
}

class _MobileReceiverScreenState extends State<MobileReceiverScreen> {
  static final Logger _logger = Logger();
  final NetworkInfo _networkInfo = NetworkInfo();
  HttpServer? _server;
  bool _isServerRunning = false;
  String _serverStatus = 'Arrêté';
  int _port = 8080;
  String? _detectedIP;
  String _customIP = '192.168.1.100'; // IP personnalisable par l'utilisateur
  List<MobileRequest> _pendingRequests = [];
  StreamSubscription? _serverSubscription;

  @override
  void initState() {
    super.initState();
    _detectLocalIP();
    _startServer();
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isServerRunning = true;
      _serverStatus = 'En cours d\'exécution sur le port $_port';
      
      _logger.i('🌐 Serveur HTTP démarré sur le port $_port');
      
      if (mounted) {
        setState(() {});
      }
      
      _serverSubscription = _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });
      
    } catch (e) {
      _logger.e('Erreur lors du démarrage du serveur: $e');
      _serverStatus = 'Erreur: $e';
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _stopServer() async {
    await _serverSubscription?.cancel();
    await _server?.close();
    _isServerRunning = false;
    _serverStatus = 'Arrêté';
    _logger.i('🛑 Serveur HTTP arrêté');
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      _logger.i('📨 Requête reçue: ${request.method} ${request.uri.path}');
      
      if (request.method == 'POST' && request.uri.path == '/api/upload-image') {
        await _handleImageUpload(request);
      } else if (request.method == 'GET' && request.uri.path == '/api/status') {
        await _handleStatusRequest(request);
      } else if (request.method == 'GET' && request.uri.path == '/') {
        await _handleRootRequest(request);
      } else {
        await _sendResponse(request, 404, {'error': 'Endpoint non trouvé'});
      }
    } catch (e) {
      _logger.e('Erreur lors du traitement de la requête: $e');
      await _sendResponse(request, 500, {'error': 'Erreur interne du serveur'});
    }
  }

  Future<void> _handleImageUpload(HttpRequest request) async {
    try {
      // Utiliser une approche plus simple : parser manuellement le multipart
      final contentType = request.headers.contentType;
      if (contentType == null || !contentType.toString().contains('multipart/form-data')) {
        await _sendResponse(request, 400, {'error': 'Content-Type multipart/form-data attendu'});
        return;
      }

      final boundary = contentType.parameters['boundary'];
      if (boundary == null) {
        await _sendResponse(request, 400, {'error': 'Boundary manquant'});
        return;
      }

      _logger.i('📦 Boundary détecté: $boundary');

      // Lire tout le body
      final body = <int>[];
      await for (final chunk in request) {
        body.addAll(chunk);
      }

      _logger.i('📦 Body reçu: ${body.length} bytes');

      // Convertir en string pour parsing
      final bodyString = String.fromCharCodes(body);
      
      // Diviser par le boundary
      final parts = bodyString.split('--$boundary');
      _logger.i('📦 ${parts.length} parties trouvées');

      String? imageBase64;
      String? deviceId;

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i].trim();
        if (part.isEmpty) continue;

        _logger.i('📄 Partie $i (${part.length} chars): ${part.substring(0, part.length > 200 ? 200 : part.length)}...');

        // Chercher les headers Content-Disposition (insensible à la casse)
        if (part.toLowerCase().contains('content-disposition: form-data')) {
          final lines = part.split('\r\n');
          
          // Trouver la ligne Content-Disposition (insensible à la casse)
          String? dispositionLine;
          for (final line in lines) {
            if (line.toLowerCase().startsWith('content-disposition:')) {
              dispositionLine = line;
              break;
            }
          }

          if (dispositionLine != null) {
            _logger.i('📋 Disposition: $dispositionLine');

            if (dispositionLine.toLowerCase().contains('name="image"')) {
              _logger.i('🖼️ Partie image détectée');
              
              // Trouver le contenu après les headers
              final headerEnd = part.indexOf('\r\n\r\n');
              if (headerEnd != -1) {
                final content = part.substring(headerEnd + 4);
                // Enlever le \r\n final si présent
                final cleanContent = content.replaceAll(RegExp(r'\r\n$'), '');
                
                if (dispositionLine.toLowerCase().contains('filename=')) {
                  // Fichier binaire - extraire les bytes du body original
                  final bodyStart = bodyString.indexOf(cleanContent);
                  if (bodyStart != -1) {
                    final bodyEnd = bodyStart + cleanContent.length;
                    final imageBytes = body.sublist(bodyStart, bodyEnd);
                    imageBase64 = base64Encode(imageBytes);
                    _logger.i('📸 Image binaire: ${imageBytes.length} bytes -> base64 (${imageBase64.length} chars)');
                  }
                } else {
                  // Déjà en base64
                  imageBase64 = cleanContent;
                  _logger.i('📸 Image base64: ${cleanContent.length} caractères');
                }
              }
            } else if (dispositionLine.toLowerCase().contains('name="deviceid"')) {
              _logger.i('📱 Partie deviceId détectée');
              
              final headerEnd = part.indexOf('\r\n\r\n');
              if (headerEnd != -1) {
                deviceId = part.substring(headerEnd + 4).replaceAll(RegExp(r'\r\n$'), '');
                _logger.i('📱 DeviceId: $deviceId');
              }
            }
          }
        }
      }

      _logger.i('🔍 Résultat final: imageBase64=${imageBase64 != null ? "présent (${imageBase64.length} chars)" : "manquant"}, deviceId=$deviceId');

      if (imageBase64 == null || imageBase64.isEmpty) {
        await _sendResponse(request, 400, {'error': 'Image manquante ou vide'});
        return;
      }

      final mobileRequest = MobileRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: deviceId ?? 'unknown',
        imageBase64: imageBase64,
        timestamp: DateTime.now(),
        status: 'received',
      );

      _pendingRequests.add(mobileRequest);
      
      await _sendResponse(request, 200, {
        'success': true,
        'requestId': mobileRequest.id,
        'message': 'Image reçue avec succès'
      });

      // Traiter l'image en arrière-plan
      _processImageRequest(mobileRequest);
      
    } catch (e) {
      _logger.e('Erreur lors du traitement de l\'image: $e');
      await _sendResponse(request, 500, {'error': 'Erreur lors du traitement'});
    }
  }

  Future<void> _handleRootRequest(HttpRequest request) async {
    await _sendResponse(request, 200, {
      'message': 'Serveur Ma Bibliothèque Remote',
      'status': 'running',
      'version': '1.0.0',
      'endpoints': {
        'upload': '/api/upload-image',
        'status': '/api/status',
      }
    });
  }

  Future<void> _handleStatusRequest(HttpRequest request) async {
    final requestId = request.uri.queryParameters['requestId'];
    
    if (requestId != null) {
      final mobileRequest = _pendingRequests.firstWhere(
        (r) => r.id == requestId,
        orElse: () => throw Exception('Requête non trouvée'),
      );
      
      await _sendResponse(request, 200, {
        'requestId': mobileRequest.id,
        'status': mobileRequest.status,
        'result': mobileRequest.result,
        'error': mobileRequest.error,
      });
    } else {
      await _sendResponse(request, 200, {
        'serverStatus': _serverStatus,
        'pendingRequests': _pendingRequests.length,
        'requests': _pendingRequests.map((r) => {
          'id': r.id,
          'deviceId': r.deviceId,
          'status': r.status,
          'timestamp': r.timestamp.toIso8601String(),
        }).toList(),
      });
    }
  }

  Future<void> _processImageRequest(MobileRequest mobileRequest) async {
    try {
      mobileRequest.status = 'processing';
      if (mounted) {
        setState(() {});
      }
      
      _logger.i('🔍 Traitement OCR pour la requête ${mobileRequest.id}');
      
      // Décoder l'image
      final imageBytes = base64Decode(mobileRequest.imageBase64);
      
      // Utiliser le service OCR
      final ocrProvider = Provider.of<OCRProvider>(context, listen: false);
      final ocrResult = await ocrProvider.extractTextFromImageBytes(imageBytes);
      
      if (ocrResult.isNotEmpty) {
        // Rechercher le livre
        final searchResults = await ocrProvider.searchBooks(ocrResult);
        
        Book? recognizedBook;
        if (searchResults.isNotEmpty) {
          // Le premier résultat est déjà un objet Book
          recognizedBook = searchResults.first;
        }
        
        // Créer le livre en attente
        final pendingBook = PendingBook(
          deviceId: mobileRequest.deviceId,
          imageBase64: mobileRequest.imageBase64,
          ocrText: ocrResult,
          recognizedBook: recognizedBook,
        );
        
        // Ajouter à la file d'attente de validation
        final pendingProvider = Provider.of<PendingBooksProvider>(context, listen: false);
        pendingProvider.addPendingBook(pendingBook);
        
        mobileRequest.status = 'pending_validation';
        mobileRequest.result = {
          'pendingBookId': pendingBook.id,
          'ocrText': ocrResult,
          'message': recognizedBook != null 
              ? 'Livre reconnu, en attente de validation'
              : 'Aucun livre trouvé, en attente de validation manuelle'
        };
        
        _logger.i('📚 Livre en attente de validation: ${recognizedBook?.title ?? 'Non reconnu'}');
      } else {
        mobileRequest.status = 'no_text';
        mobileRequest.error = 'Aucun texte détecté dans l\'image';
      }
      
    } catch (e) {
      _logger.e('Erreur lors du traitement OCR: $e');
      mobileRequest.status = 'error';
      mobileRequest.error = e.toString();
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _sendResponse(HttpRequest request, int statusCode, Map<String, dynamic> data) async {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(data));
    await request.response.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Récepteur Mobile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<PendingBooksProvider>(
            builder: (context, provider, child) {
              final pendingCount = provider.pendingCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.pending_actions),
                    onPressed: () => context.go('/book-validation'),
                    tooltip: 'Livres en attente de validation',
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
            onPressed: _isServerRunning ? _stopServer : _startServer,
            tooltip: _isServerRunning ? 'Arrêter le serveur' : 'Démarrer le serveur',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut du serveur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isServerRunning ? Icons.wifi : Icons.wifi_off,
                          color: _isServerRunning ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Serveur HTTP',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_serverStatus),
                    if (_isServerRunning) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'http://${_getLocalIP()}:$_port',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: () {
                                // Copier l'URL dans le presse-papiers
                                Clipboard.setData(ClipboardData(text: 'http://${_getLocalIP()}:$_port'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Adresse copiée dans le presse-papiers'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copier l\'adresse',
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code, size: 16),
                              onPressed: _showQRCodeDialog,
                              tooltip: 'Afficher le QR code',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: _showIPConfigDialog,
                              tooltip: 'Configurer l\'IP',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vérifiez que cette IP correspond à votre ordinateur. Utilisez "ipconfig" dans le terminal pour la trouver.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Requêtes en attente
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requêtes mobiles (${_pendingRequests.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _pendingRequests.isEmpty
                            ? const Center(
                                child: Text('Aucune requête en attente'),
                              )
                            : ListView.builder(
                                itemCount: _pendingRequests.length,
                                itemBuilder: (context, index) {
                                  final request = _pendingRequests[index];
                                  return _buildRequestCard(request);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(MobileRequest request) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (request.status) {
      case 'received':
        statusColor = Colors.blue;
        statusIcon = Icons.inbox;
        statusText = 'Reçue';
        break;
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Traitement...';
        break;
      case 'pending_validation':
        statusColor = Colors.purple;
        statusIcon = Icons.pending_actions;
        statusText = 'En attente de validation';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Terminée';
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Erreur';
        break;
      case 'no_text':
        statusColor = Colors.amber;
        statusIcon = Icons.text_fields;
        statusText = 'Aucun texte détecté';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = request.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text('Requête ${request.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appareil: ${request.deviceId}'),
            Text('Statut: $statusText'),
            Text('Heure: ${_formatTimestamp(request.timestamp)}'),
            if (request.error != null)
              Text('Erreur: ${request.error}', style: const TextStyle(color: Colors.red)),
            if (request.result != null && request.result!['ocrText'] != null) ...[
              Builder(
                builder: (context) {
                  final ocrText = request.result!['ocrText'].toString();
                  final displayText = ocrText.length > 50 
                      ? '${ocrText.substring(0, 50)}...'
                      : ocrText;
                  return Text('Texte OCR: $displayText');
                },
              ),
            ],
            if (request.result != null && request.result!['message'] != null)
              Text('Message: ${request.result!['message']}'),
          ],
        ),
        isThreeLine: true,
        onTap: request.status == 'pending_validation' ? () => _handleRequestTap(request) : null,
        trailing: request.status == 'pending_validation' 
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleRequestTap(MobileRequest request) {
    if (request.status == 'pending_validation' && request.result != null) {
      final pendingBookId = request.result!['pendingBookId'] as String?;
      if (pendingBookId != null) {
        // Récupérer le livre en attente
        final pendingProvider = Provider.of<PendingBooksProvider>(context, listen: false);
        final pendingBook = pendingProvider.getPendingBook(pendingBookId);
        
        if (pendingBook != null) {
          // Naviguer vers l'écran d'ajout de livre avec les données pré-remplies
          context.push('/add-book', extra: {
            'preFilledBook': pendingBook.recognizedBook,
            'preFilledImageBase64': pendingBook.imageBase64,
            'preFilledOcrText': pendingBook.ocrText,
          });
        }
      }
    }
  }

  Future<void> _detectLocalIP() async {
    try {
      _detectedIP = await _networkInfo.getWifiIP();
      _logger.i('IP détectée automatiquement: $_detectedIP');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _logger.e('Erreur lors de la détection automatique de l\'IP: $e');
      _detectedIP = null;
    }
  }

  String _getLocalIP() {
    // Utiliser l'IP détectée automatiquement, sinon l'IP personnalisée
    return _detectedIP ?? _customIP;
  }

  void _showIPConfigDialog() {
    final controller = TextEditingController(text: _customIP);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurer l\'adresse IP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez l\'adresse IP de votre ordinateur :',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Adresse IP',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Utilisez "ipconfig" dans le terminal pour trouver votre IP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _customIP = controller.text.trim();
              Navigator.of(context).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('IP configurée: $_customIP'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog() {
    final serverUrl = 'http://${_getLocalIP()}:$_port';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code de connexion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scannez ce QR code avec l\'application mobile :',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: serverUrl,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serverUrl,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: serverUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copiée dans le presse-papiers'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}

class MobileRequest {
  final String id;
  final String deviceId;
  final String imageBase64;
  final DateTime timestamp;
  String status;
  Map<String, dynamic>? result;
  String? error;

  MobileRequest({
    required this.id,
    required this.deviceId,
    required this.imageBase64,
    required this.timestamp,
    required this.status,
    this.result,
    this.error,
  });
}
