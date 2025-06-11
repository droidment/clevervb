import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SupabaseService {
  static final _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _logger = Logger();
  late final SupabaseClient _client;

  // Initialize Supabase
  Future<void> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  }) async {
    try {
      await Supabase.initialize(url: url, anonKey: anonKey, debug: debug);

      _client = Supabase.instance.client;
      _logger.i('Supabase initialized successfully');

      // Set up auth state listener
      _client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final user = data.session?.user;

        switch (event) {
          case AuthChangeEvent.signedIn:
            _logger.i('User signed in: ${user?.email}');
            break;
          case AuthChangeEvent.signedOut:
            _logger.i('User signed out');
            break;
          case AuthChangeEvent.tokenRefreshed:
            _logger.d('Token refreshed for user: ${user?.email}');
            break;
          default:
            _logger.d('Auth event: $event');
        }
      });
    } catch (e) {
      _logger.e('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  // Get Supabase client
  SupabaseClient get client => _client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ==================== USER PROFILE OPERATIONS ====================

  // Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await _client
              .from('st_users')
              .select('*')
              .eq('id', userId)
              .maybeSingle();

      return response;
    } catch (e) {
      _logger.e('Error fetching user profile: $e');
      rethrow;
    }
  }

  // Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    return await getUserProfile(user.id);
  }

  // Create user profile
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? location,
    String? bio,
    List<String>? preferredSports,
    String skillLevel = 'beginner',
  }) async {
    try {
      final data = {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'phone': phone,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
        'location': location,
        'bio': bio,
        'preferred_sports': preferredSports ?? [],
        'skill_level': skillLevel,
        'is_profile_complete': dateOfBirth != null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('st_users').insert(data);
      _logger.i('User profile created for: $email');
    } catch (e) {
      _logger.e('Error creating user profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? location,
    String? bio,
    List<String>? preferredSports,
    String? skillLevel,
    bool? isProfileComplete,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (phone != null) updateData['phone'] = phone;
      if (dateOfBirth != null) {
        updateData['date_of_birth'] =
            dateOfBirth.toIso8601String().split('T')[0];
      }
      if (location != null) updateData['location'] = location;
      if (bio != null) updateData['bio'] = bio;
      if (preferredSports != null) {
        updateData['preferred_sports'] = preferredSports;
      }
      if (skillLevel != null) updateData['skill_level'] = skillLevel;
      if (isProfileComplete != null) {
        updateData['is_profile_complete'] = isProfileComplete;
      }

      await _client.from('st_users').update(updateData).eq('id', userId);

      _logger.i('User profile updated for user: $userId');
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      rethrow;
    }
  }

  // Check if user profile is complete
  Future<bool> isUserProfileComplete(String userId) async {
    try {
      final response =
          await _client
              .from('st_users')
              .select('is_profile_complete, date_of_birth')
              .eq('id', userId)
              .maybeSingle();

      if (response == null) return false;

      return response['is_profile_complete'] == true &&
          response['date_of_birth'] != null;
    } catch (e) {
      _logger.e('Error checking profile completion: $e');
      return false;
    }
  }

  // Delete user profile and all related data
  Future<void> deleteUserProfile(String userId) async {
    try {
      // Delete user record (cascade will handle related records)
      await _client.from('st_users').delete().eq('id', userId);

      _logger.i('User profile deleted for user: $userId');
    } catch (e) {
      _logger.e('Error deleting user profile: $e');
      rethrow;
    }
  }

  // ==================== TEAM OPERATIONS ====================

  // Get teams where user is a member
  Future<List<Map<String, dynamic>>> getUserTeams(String userId) async {
    try {
      final response = await _client
          .from('st_team_members')
          .select('''
            role,
            joined_at,
            st_teams:team_id (
              id,
              name,
              sport_type,
              description,
              organizer_id,
              is_public,
              max_members,
              created_at,
              updated_at
            )
          ''')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error fetching user teams: $e');
      rethrow;
    }
  }

  // Get teams organized by user
  Future<List<Map<String, dynamic>>> getOrganizedTeams(String userId) async {
    try {
      final response = await _client
          .from('st_teams')
          .select('*')
          .eq('organizer_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error fetching organized teams: $e');
      rethrow;
    }
  }

  // ==================== GAME OPERATIONS ====================

  // Get upcoming games for user's teams
  Future<List<Map<String, dynamic>>> getUpcomingGames(String userId) async {
    try {
      final response = await _client
          .from('st_games')
          .select('''
            *,
            st_teams!inner(name, sport_type),
            st_team_members!inner(user_id)
          ''')
          .eq('st_team_members.user_id', userId)
          .gte('scheduled_at', DateTime.now().toIso8601String())
          .order('scheduled_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error fetching upcoming games: $e');
      rethrow;
    }
  }

  // Get user's RSVPs
  Future<List<Map<String, dynamic>>> getUserRSVPs(String userId) async {
    try {
      final response = await _client
          .from('st_rsvps')
          .select('''
            *,
            st_games!inner(
              id,
              scheduled_at,
              venue_name,
              st_teams!inner(name, sport_type)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error fetching user RSVPs: $e');
      rethrow;
    }
  }

  // ==================== DISCOVERY OPERATIONS ====================

  // Search for public games by location and criteria
  Future<List<Map<String, dynamic>>> discoverGames({
    double? latitude,
    double? longitude,
    double radiusKm = 25.0,
    String? sportType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      // Build query
      var query = _client
          .from('st_games')
          .select('''
            *,
            st_teams!inner(
              id,
              name,
              sport_type,
              is_public,
              organizer_id,
              st_users!st_teams_organizer_id_fkey(full_name, avatar_url)
            )
          ''')
          .eq('st_teams.is_public', true)
          .gte('scheduled_at', (startDate ?? DateTime.now()).toIso8601String());

      // Add end date filter if provided
      if (endDate != null) {
        query = query.lte('scheduled_at', endDate.toIso8601String());
      }

      // Add sport type filter if provided
      if (sportType != null && sportType.isNotEmpty) {
        query = query.eq('st_teams.sport_type', sportType);
      }

      // Add location filter if coordinates provided
      if (latitude != null && longitude != null) {
        // Use PostGIS function to filter by distance
        query = query.filter(
          'location',
          'st_dwithin',
          'POINT($longitude $latitude)::geography,$radiusKm',
        );
      }

      final response = await query.order('scheduled_at').limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error discovering games: $e');
      rethrow;
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final response =
          await _client
              .from('st_users')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      _logger.e('Error checking if user exists: $e');
      return false;
    }
  }

  // Get app statistics
  Future<Map<String, int>> getAppStats() async {
    try {
      final usersResponse = await _client.from('st_users').select('id');
      final teamsResponse = await _client.from('st_teams').select('id');
      final gamesResponse = await _client.from('st_games').select('id');
      final activeGamesResponse = await _client
          .from('st_games')
          .select('id')
          .gte('scheduled_at', DateTime.now().toIso8601String());

      return {
        'totalUsers': usersResponse.length,
        'totalTeams': teamsResponse.length,
        'totalGames': gamesResponse.length,
        'activeGames': activeGamesResponse.length,
      };
    } catch (e) {
      _logger.e('Error fetching app stats: $e');
      return {
        'totalUsers': 0,
        'totalTeams': 0,
        'totalGames': 0,
        'activeGames': 0,
      };
    }
  }

  // Test database connection
  Future<bool> testConnection() async {
    try {
      await _client.from('st_users').select('id').limit(1);
      return true;
    } catch (e) {
      _logger.e('Database connection test failed: $e');
      return false;
    }
  }
}
