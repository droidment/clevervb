/// Environment configuration for the Sports Team Management app
/// This file handles loading secrets and providing configuration to the app
library;

class Env {
  // Supabase Configuration
  static const String supabaseUrl = 'https://wpajzbavifsndrnyscns.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwYWp6YmF2aWZzbmRybnlzY25zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwMDMzNDksImV4cCI6MjA0MzU3OTM0OX0.HhRp8J8LaimCTOIc7Pg87ZgII3JVEKPkTWs8bjnydtE';

  // App Configuration
  static const String appName = 'Sports Team Manager';
  static const String appVersion = '1.0.0';
  static const String environment = 'development';

  // Database Configuration
  static const String tablePrefix = 'st_';
  static const bool enableLogging = true;

  // Google OAuth Configuration (to be filled when implementing Google Auth)
  static const String? googleWebClientId = null;
  static const String? googleIOSClientId = null;
  static const String? googleAndroidClientId = null;

  // WhatsApp Configuration (for future implementation)
  static const String? whatsappBusinessPhoneId = null;
  static const String? whatsappAccessToken = null;

  // Feature Flags
  static const bool enableWhatsAppIntegration = false;
  static const bool enableGuestInvitations = true;
  static const bool enableLocationServices = true;
  static const bool enablePushNotifications = false; // Future feature

  // Game Configuration
  static const int defaultMaxPlayers = 8;
  static const int maxConsecutiveAbsences =
      10; // Auto-remove after 10 consecutive absences
  static const Duration invitationExpiryDuration = Duration(days: 7);

  // Age Restriction
  static const int minimumAge = 18;

  // Default Game Settings
  static const double defaultVolleyballFee = 15.0;
  static const double defaultPickleballFee = 10.0;
  static const int defaultGameDurationMinutes = 120;

  // Geographic Settings (defaults to Los Angeles area)
  static const double defaultLatitude = 34.0522;
  static const double defaultLongitude = -118.2437;
  static const double defaultSearchRadiusKm = 25.0;

  /// Validate that all required environment variables are set
  static bool validateEnvironment() {
    final missingVars = <String>[];

    if (supabaseUrl.isEmpty) missingVars.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missingVars.add('SUPABASE_ANON_KEY');

    if (missingVars.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingVars.join(', ')}',
      );
    }

    return true;
  }

  /// Get the appropriate table name with prefix
  static String getTableName(String tableName) {
    return '$tablePrefix$tableName';
  }

  /// Check if running in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if running in production mode
  static bool get isProduction => environment == 'production';
}
