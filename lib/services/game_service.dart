import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/game.dart';
import '../config/env.dart';
import 'auth_service.dart';

class GameService {
  static final _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final _logger = Logger();
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  final _authService = AuthService();

  // ==================== GAME CRUD OPERATIONS ====================

  /// Create a new game (TEST VERSION - bypasses RLS for debugging)
  Future<void> testCreateGameBypassRLS({
    required String teamId,
    required String title,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create a game');
      }

      // Get the st_users.id for the current user
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not find user profile');
      }

      _logger.i('Testing game creation with direct SQL - bypassing RLS');

      final gameId = _uuid.v4();
      final now = DateTime.now();
      final scheduledAt = now.add(const Duration(days: 1));

      // Use RPC to bypass RLS for testing
      await _supabase.rpc(
        'create_game_test',
        params: {
          'p_game_id': gameId,
          'p_team_id': teamId,
          'p_organizer_id': currentUserId,
          'p_title': title,
          'p_sport': 'volleyball',
          'p_venue': 'Test Venue',
          'p_scheduled_at': scheduledAt.toIso8601String(),
          'p_duration_minutes': 120,
          'p_max_players': 12,
          'p_is_public': false,
          'p_requires_rsvp': true,
          'p_auto_confirm_rsvp': true,
          'p_weather_dependent': false,
          'p_created_at': now.toIso8601String(),
          'p_updated_at': now.toIso8601String(),
        },
      );

      _logger.i('Test game created successfully: $gameId');
    } catch (e) {
      _logger.e('Error creating test game: $e');
      rethrow;
    }
  }

  /// Create a new game
  Future<Game> createGame({
    required String teamId,
    required String title,
    String? description,
    required String sport,
    required String venue,
    String? address,
    double? latitude,
    double? longitude,
    required DateTime scheduledAt,
    int durationMinutes = 120,
    int? maxPlayers,
    double? feePerPlayer,
    bool isPublic = false,
    bool requiresRsvp = true,
    bool autoConfirmRsvp = true,
    DateTime? rsvpDeadline,
    bool weatherDependent = false,
    String? notes,
    List<String> equipmentNeeded = const [],
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create a game');
      }

      // Get the st_users.id for the current user
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not find user profile');
      }

      _logger.i('Creating game: $title');

      final gameId = _uuid.v4();
      final now = DateTime.now();

      // Determine max players based on sport if not provided
      final finalMaxPlayers = maxPlayers ?? _getDefaultMaxPlayers(sport);

      // Create game record
      await _supabase.from('st_games').insert({
        'id': gameId,
        'team_id': teamId,
        'organizer_id': currentUserId, // Use st_users.id instead of auth.uid()
        'title': title.trim(),
        'description': description?.trim(),
        'sport': sport.toLowerCase(),
        'venue': venue.trim(),
        'address': address?.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'max_players': finalMaxPlayers,
        'fee_per_player': feePerPlayer,
        'is_public': isPublic,
        'requires_rsvp': requiresRsvp,
        'auto_confirm_rsvp': autoConfirmRsvp,
        'rsvp_deadline': rsvpDeadline?.toIso8601String(),
        'weather_dependent': weatherDependent,
        'notes': notes?.trim(),
        'equipment_needed': equipmentNeeded,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      _logger.i('Game created successfully: $gameId');

      // Return the created game
      return getGame(gameId);
    } catch (e) {
      _logger.e('Error creating game: $e');
      rethrow;
    }
  }

  /// Get a game by ID
  Future<Game> getGame(String gameId) async {
    try {
      final response =
          await _supabase
              .from('st_games')
              .select('''
            *,
            st_users!st_games_organizer_id_fkey(full_name, avatar_url),
            st_teams!st_games_team_id_fkey(name, sport_type),
            rsvp_count:st_rsvps(count),
            attendance_count:st_attendances(count)
          ''')
              .eq('id', gameId)
              .single();

      return _mapGameFromResponse(response);
    } catch (e) {
      _logger.e('Error fetching game: $e');
      rethrow;
    }
  }

  /// Update game details
  Future<Game> updateGame(
    String gameId, {
    String? title,
    String? description,
    String? venue,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? scheduledAt,
    int? durationMinutes,
    int? maxPlayers,
    double? feePerPlayer,
    bool? isPublic,
    bool? requiresRsvp,
    bool? autoConfirmRsvp,
    DateTime? rsvpDeadline,
    String? status,
    String? cancelledReason,
    bool? weatherDependent,
    String? notes,
    List<String>? equipmentNeeded,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to update a game');
      }

      // Check if user is organizer
      final currentUserId = await _authService.getCurrentUserId();
      final game = await getGame(gameId);
      if (game.organizerId != currentUserId) {
        throw Exception('Only the game organizer can update this game');
      }

      _logger.i('Updating game: $gameId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title.trim();
      if (description != null) updateData['description'] = description.trim();
      if (venue != null) updateData['venue'] = venue.trim();
      if (address != null) updateData['address'] = address.trim();
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (scheduledAt != null)
        updateData['scheduled_at'] = scheduledAt.toIso8601String();
      if (durationMinutes != null)
        updateData['duration_minutes'] = durationMinutes;
      if (maxPlayers != null) updateData['max_players'] = maxPlayers;
      if (feePerPlayer != null) updateData['fee_per_player'] = feePerPlayer;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (requiresRsvp != null) updateData['requires_rsvp'] = requiresRsvp;
      if (autoConfirmRsvp != null)
        updateData['auto_confirm_rsvp'] = autoConfirmRsvp;
      if (rsvpDeadline != null)
        updateData['rsvp_deadline'] = rsvpDeadline.toIso8601String();
      if (status != null) updateData['status'] = status;
      if (cancelledReason != null)
        updateData['cancelled_reason'] = cancelledReason;
      if (weatherDependent != null)
        updateData['weather_dependent'] = weatherDependent;
      if (notes != null) updateData['notes'] = notes.trim();
      if (equipmentNeeded != null)
        updateData['equipment_needed'] = equipmentNeeded;

      await _supabase.from('st_games').update(updateData).eq('id', gameId);

      _logger.i('Game updated successfully');

      return getGame(gameId);
    } catch (e) {
      _logger.e('Error updating game: $e');
      rethrow;
    }
  }

  /// Cancel a game
  Future<Game> cancelGame(String gameId, String reason) async {
    return updateGame(gameId, status: 'cancelled', cancelledReason: reason);
  }

  /// Complete a game
  Future<Game> completeGame(String gameId) async {
    return updateGame(gameId, status: 'completed');
  }

  /// Delete a game
  Future<void> deleteGame(String gameId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to delete a game');
      }

      // Get the st_users.id for the current user
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not find user profile');
      }

      // Check if user is organizer
      final game = await getGame(gameId);
      if (game.organizerId != currentUserId) {
        throw Exception('Only the game organizer can delete this game');
      }

      _logger.i('Deleting game: $gameId');

      await _supabase.from('st_games').delete().eq('id', gameId);

      _logger.i('Game deleted successfully');
    } catch (e) {
      _logger.e('Error deleting game: $e');
      rethrow;
    }
  }

  // ==================== GAME QUERIES ====================

  /// Get games for a specific team
  Future<List<Game>> getTeamGames(
    String teamId, {
    bool upcomingOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('st_games')
          .select('''
            *,
            st_users!st_games_organizer_id_fkey(full_name, avatar_url),
            st_teams!st_games_team_id_fkey(name, sport_type),
            rsvp_count:st_rsvps(count),
            attendance_count:st_attendances(count)
          ''')
          .eq('team_id', teamId);

      if (upcomingOnly) {
        query = query.gte('scheduled_at', DateTime.now().toIso8601String());
      }

      final response = await query
          .order('scheduled_at', ascending: !upcomingOnly)
          .range(offset, offset + limit - 1);

      return response.map((game) => _mapGameFromResponse(game)).toList();
    } catch (e) {
      _logger.e('Error fetching team games: $e');
      rethrow;
    }
  }

  /// Get games for user's teams
  Future<List<Game>> getUserGames(
    String userId, {
    bool upcomingOnly = false,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('st_games')
          .select('''
            *,
            st_users!st_games_organizer_id_fkey(full_name, avatar_url),
            st_teams!inner(name, sport_type, st_team_members!inner(user_id)),
            rsvp_count:st_rsvps(count),
            attendance_count:st_attendances(count)
          ''')
          .eq('st_teams.st_team_members.user_id', userId);

      if (upcomingOnly) {
        query = query.gte('scheduled_at', DateTime.now().toIso8601String());
      }

      final response = await query
          .order('scheduled_at', ascending: !upcomingOnly)
          .limit(limit);

      return response.map((game) => _mapGameFromResponse(game)).toList();
    } catch (e) {
      _logger.e('Error fetching user games: $e');
      rethrow;
    }
  }

  /// Get games the user has RSVP'd to
  Future<List<Game>> getUserRsvpedGames(
    String userId, {
    bool upcomingOnly = false,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('st_games')
          .select('''
            *,
            st_users!st_games_organizer_id_fkey(full_name, avatar_url),
            st_teams(name, sport_type),
            st_rsvps!inner(response, guest_count),
            rsvp_count:st_rsvps(count),
            attendance_count:st_attendances(count)
          ''')
          .eq('st_rsvps.user_id', userId)
          .eq(
            'st_rsvps.response',
            'yes',
          ); // Only get games user RSVP'd "yes" to

      if (upcomingOnly) {
        query = query.gte('scheduled_at', DateTime.now().toIso8601String());
      }

      final response = await query
          .order('scheduled_at', ascending: !upcomingOnly)
          .limit(limit);

      return response.map((game) => _mapGameFromResponse(game)).toList();
    } catch (e) {
      _logger.e('Error fetching user RSVP\'d games: $e');
      rethrow;
    }
  }

  /// Discover public games
  Future<List<Game>> discoverGames({
    double? latitude,
    double? longitude,
    double radiusKm = 25.0,
    String? sport,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('st_games')
          .select('''
            *,
            st_users!st_games_organizer_id_fkey(full_name, avatar_url),
            st_teams!inner(name, sport_type, is_public),
            rsvp_count:st_rsvps(count),
            attendance_count:st_attendances(count)
          ''')
          .eq('is_public', true);

      // Filter by date range
      final searchStartDate = startDate ?? DateTime.now();
      query = query.gte('scheduled_at', searchStartDate.toIso8601String());

      if (endDate != null) {
        query = query.lte('scheduled_at', endDate.toIso8601String());
      }

      // Filter by sport
      if (sport != null && sport.isNotEmpty) {
        query = query.eq('sport', sport.toLowerCase());
      }

      // Location-based filtering (if coordinates provided)
      if (latitude != null && longitude != null) {
        // Note: This requires PostGIS extension
        query = query.filter(
          'location',
          'st_dwithin',
          'POINT($longitude $latitude)::geography,${radiusKm * 1000}',
        );
      }

      final response = await query.order('scheduled_at').limit(limit);

      return response.map((game) => _mapGameFromResponse(game)).toList();
    } catch (e) {
      _logger.e('Error discovering games: $e');
      rethrow;
    }
  }

  // ==================== RSVP OPERATIONS ====================

  /// Submit RSVP for a game
  Future<void> rsvpToGame(
    String gameId,
    RsvpResponse response, {
    int guestCount = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to RSVP');
      }

      // Get the st_users.id for the current user
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not find user profile');
      }

      final game = await getGame(gameId);

      // Check if RSVP is still open
      if (!game.isRsvpOpen) {
        throw Exception('RSVP is no longer open for this game');
      }

      // Check capacity if responding yes
      if (response == RsvpResponse.yes) {
        final totalNeeded = 1 + guestCount;
        if (game.remainingSpots < totalNeeded) {
          throw Exception('Not enough spots available');
        }
      }

      _logger.i('Submitting RSVP for game: $gameId');

      // Insert or update RSVP
      await _supabase.from('st_rsvps').upsert({
        'game_id': gameId,
        'user_id': currentUserId, // Use st_users.id instead of auth.uid()
        'response': response.name,
        'guest_count': guestCount,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'game_id,user_id');

      _logger.i('RSVP submitted successfully');
    } catch (e) {
      _logger.e('Error submitting RSVP: $e');
      rethrow;
    }
  }

  /// Get user's RSVP for a game
  Future<Map<String, dynamic>?> getUserRsvp(
    String gameId,
    String userId,
  ) async {
    try {
      final response =
          await _supabase
              .from('st_rsvps')
              .select('*')
              .eq('game_id', gameId)
              .eq('user_id', userId)
              .maybeSingle();

      return response;
    } catch (e) {
      _logger.e('Error fetching user RSVP: $e');
      rethrow;
    }
  }

  /// Get all RSVPs for a game
  Future<List<Map<String, dynamic>>> getGameRsvps(String gameId) async {
    try {
      final response = await _supabase
          .from('st_rsvps')
          .select('''
            *,
            st_users!st_rsvps_user_id_fkey(full_name, avatar_url, email)
          ''')
          .eq('game_id', gameId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.e('Error fetching game RSVPs: $e');
      rethrow;
    }
  }

  /// Remove RSVP for a game
  Future<void> removeRsvp(String gameId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to remove RSVP');
      }

      // Get the st_users.id for the current user
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not find user profile');
      }

      _logger.i('Removing RSVP for game: $gameId');

      await _supabase
          .from('st_rsvps')
          .delete()
          .eq('game_id', gameId)
          .eq(
            'user_id',
            currentUserId,
          ); // Use st_users.id instead of auth.uid()

      _logger.i('RSVP removed successfully');
    } catch (e) {
      _logger.e('Error removing RSVP: $e');
      rethrow;
    }
  }

  /// Get games organized by a specific user
  Future<List<Game>> getOrganizerGames(String organizerId) async {
    try {
      _logger.i('Fetching games for organizer: $organizerId');

      final response = await _supabase
          .from('st_games')
          .select('''
            *,
            st_users!st_games_organizer_id_fkey(full_name, avatar_url),
            st_teams!st_games_team_id_fkey(name, sport_type),
            rsvp_count:st_rsvps(count),
            attendance_count:st_attendances(count)
          ''')
          .eq('organizer_id', organizerId)
          .order('scheduled_at', ascending: false);

      final games = response.map((game) => _mapGameFromResponse(game)).toList();

      _logger.i('Found ${games.length} games for organizer');
      return games;
    } catch (e) {
      _logger.e('Error fetching organizer games: $e');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get default max players based on sport
  int _getDefaultMaxPlayers(String sport) {
    switch (sport.toLowerCase()) {
      case 'volleyball':
        return 8;
      case 'pickleball':
        return 2;
      case 'basketball':
        return 10;
      case 'tennis':
        return 4;
      case 'badminton':
        return 4;
      case 'soccer':
        return 22;
      default:
        return Env.defaultMaxPlayers;
    }
  }

  /// Get default fee based on sport
  double _getDefaultFee(String sport) {
    switch (sport.toLowerCase()) {
      case 'volleyball':
        return Env.defaultVolleyballFee;
      case 'pickleball':
        return Env.defaultPickleballFee;
      default:
        return 0.0;
    }
  }

  /// Map database response to Game object
  Game _mapGameFromResponse(Map<String, dynamic> response) {
    final organizer = response['st_users'];
    final team = response['st_teams'];
    final rsvpCount = response['rsvp_count']?[0]?['count'] ?? 0;
    final attendanceCount = response['attendance_count']?[0]?['count'] ?? 0;

    return Game(
      id: response['id'],
      teamId: response['team_id'],
      organizerId: response['organizer_id'],
      title: response['title'],
      description: response['description'],
      sport: response['sport'],
      venue: response['venue'],
      address: response['address'],
      latitude: response['latitude']?.toDouble(),
      longitude: response['longitude']?.toDouble(),
      scheduledAt: DateTime.parse(response['scheduled_at']),
      durationMinutes: response['duration_minutes'],
      maxPlayers: response['max_players'],
      feePerPlayer: response['fee_per_player']?.toDouble(),
      isPublic: response['is_public'],
      requiresRsvp: response['requires_rsvp'],
      autoConfirmRsvp: response['auto_confirm_rsvp'],
      rsvpDeadline:
          response['rsvp_deadline'] != null
              ? DateTime.parse(response['rsvp_deadline'])
              : null,
      status: response['status'],
      cancelledReason: response['cancelled_reason'],
      weatherDependent: response['weather_dependent'],
      notes: response['notes'],
      equipmentNeeded: List<String>.from(response['equipment_needed'] ?? []),
      createdAt: DateTime.parse(response['created_at']),
      updatedAt: DateTime.parse(response['updated_at']),
      organizerName: organizer?['full_name'],
      teamName: team?['name'],
      rsvpCount: rsvpCount,
      attendanceCount: attendanceCount,
    );
  }
}
