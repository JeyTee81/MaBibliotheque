/// Configuration de la base de données
/// Permet de basculer entre MockDatabaseService et PostgreSQLDatabaseService

class DatabaseConfig {
  // Configuration PostgreSQL
  static const String postgresHost = 'localhost';
  static const int postgresPort = 5432;
  static const String postgresDatabase = 'bookworm_db';
  static const String postgresUsername = 'bookworm_user';
  static const String postgresPassword = 'bookworm_password';
  
  // Mode de base de données
  // true = PostgreSQL, false = Mock (pour les tests)
  static const bool usePostgreSQL = true;
  
  // Configuration de debug
  static const bool enableDatabaseLogs = true;
}
