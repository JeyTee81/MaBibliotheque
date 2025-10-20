import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../core/models/user.dart';
import '../core/database/postgresql_database_service.dart';

class AuthProvider extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');

      if (userId != null && userName != null && userEmail != null) {
        _currentUser = User(
          id: userId,
          name: userName,
          email: userEmail,
          createdAt: DateTime.now(), // En production, récupérer depuis la base
        );
        _isAuthenticated = true;
        _logger.i('User authenticated: ${_currentUser!.name}');
      } else {
        _isAuthenticated = false;
        _logger.i('No authenticated user found');
      }
    } catch (e) {
      _logger.e('Error checking auth status: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email et mot de passe requis');
      }

      final databaseService = PostgreSQLDatabaseService();
      await databaseService.initialize();
      
      // Rechercher l'utilisateur par email
      final results = await databaseService.select(
        'SELECT * FROM users WHERE email = \$1',
        [email]
      );

      if (results.isEmpty) {
        throw Exception('Utilisateur non trouvé');
      }

      final userData = results.first;
      final user = User.fromMap(userData);
      
      // Vérifier le mot de passe (hash)
      final passwordHash = _hashPassword(password);
      if (user.passwordHash != passwordHash) {
        throw Exception('Mot de passe incorrect');
      }

      await _saveUserToStorage(user);
      _currentUser = user;
      _isAuthenticated = true;
      _logger.i('User logged in: ${user.name}');
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('Tous les champs sont requis');
      }

      final databaseService = PostgreSQLDatabaseService();
      await databaseService.initialize();
      
      // Vérifier si l'utilisateur existe déjà
      final existingResults = await databaseService.select(
        'SELECT * FROM users WHERE email = \$1',
        [email]
      );

      if (existingResults.isNotEmpty) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Créer le nouvel utilisateur
      final passwordHash = _hashPassword(password);
      final user = User(
        name: name,
        email: email,
        passwordHash: passwordHash,
        createdAt: DateTime.now(),
      );

      // Sauvegarder dans la base de données
      await databaseService.addUser(user);

      await _saveUserToStorage(user);
      _currentUser = user;
      _isAuthenticated = true;
      _logger.i('User registered: ${user.name}');
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');

      _currentUser = null;
      _isAuthenticated = false;
      _logger.i('User logged out');
    } catch (e) {
      _logger.e('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
  }

  /// Hash un mot de passe avec SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}