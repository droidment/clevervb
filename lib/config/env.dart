/// Environment configuration for the Sports Team Management app
/// This file handles loading secrets and providing configuration to the app
library;

class Env {
  // Supabase Configuration - Use environment variables in production
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wpajzbavifsndrnyscns.supabase.co', // Dev fallback
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwYWp6YmF2aWZzbmRybnlzY25zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwMDMzNDksImV4cCI6MjA0MzU3OTM0OX0.HhRp8J8LaimCTOIc7Pg87ZgII3JVEKPkTWs8bjnydtE', // Dev fallback
  );

  // App Configuration
  static const String appName = 'CleverVB';
  static const String appVersion = '1.0.0';
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Database Configuration
  static const String tablePrefix = 'st_';
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  // Google OAuth Configuration
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '743003482567-4ooqr455lbfrn8vjubrrhmnqdo388n6k.apps.googleusercontent.com',
  );

  static const String googleIOSClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
  );

  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '743003482567-grjmdppd3sbbpkn9uoc6lcr7ro0tvdp0.apps.googleusercontent.com',
  );

  // WhatsApp Configuration (for future implementation)
  static const String whatsappBusinessPhoneId = String.fromEnvironment(
    'WHATSAPP_BUSINESS_PHONE_ID',
  );
  static const String whatsappAccessToken = String.fromEnvironment(
    'WHATSAPP_ACCESS_TOKEN',
  );

  // Feature Flags
  static const bool enableWhatsAppIntegration = bool.fromEnvironment(
    'ENABLE_WHATSAPP_INTEGRATION',
    defaultValue: false,
  );
  static const bool enableGuestInvitations = bool.fromEnvironment(
    'ENABLE_GUEST_INVITATIONS',
    defaultValue: true,
  );
  static const bool enableLocationServices = bool.fromEnvironment(
    'ENABLE_LOCATION_SERVICES',
    defaultValue: true,
  );
  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: false,
  );

  // Game Configuration
  static const int defaultMaxPlayers = int.fromEnvironment(
    'DEFAULT_MAX_PLAYERS',
    defaultValue: 8,
  );
  static const int maxConsecutiveAbsences = int.fromEnvironment(
    'MAX_CONSECUTIVE_ABSENCES',
    defaultValue: 10,
  );
  static const Duration invitationExpiryDuration = Duration(days: 7);

  // Age Restriction
  static const int minimumAge = int.fromEnvironment(
    'MINIMUM_AGE',
    defaultValue: 18,
  );

  // Default Game Settings
  static const double defaultVolleyballFee = 15.0;
  static const double defaultPickleballFee = 10.0;
  static const int defaultGameDurationMinutes = int.fromEnvironment(
    'DEFAULT_GAME_DURATION_MINUTES',
    defaultValue: 120,
  );

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

  /// Print current configuration (for debugging - never log sensitive keys!)
  static void printConfig() {
    print('=== CleverVB Configuration ===');
    print('App Name: $appName');
    print('Version: $appVersion');
    print('Environment: $environment');
    print('Supabase URL: $supabaseUrl');
    print('Supabase Key: ${supabaseAnonKey.substring(0, 20)}...[HIDDEN]');
    print('Enable Logging: $enableLogging');
    print(
      'Google Web Client ID: ${googleWebClientId?.substring(0, 20)}...[HIDDEN]',
    );
    print('===============================');
  }
}
