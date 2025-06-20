import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import 'auth_service.dart';

class ProfileService {
  static final _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final _logger = Logger();
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  // ==================== PROFILE OPERATIONS ====================

  /// Get current user's profile
  Future<models.User?> getCurrentUserProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final userId = await _authService.getCurrentUserId();
      if (userId == null) return null;

      return getUserProfile(userId);
    } catch (e) {
      _logger.e('Error getting current user profile: $e');
      rethrow;
    }
  }

  /// Get user profile by ID
  Future<models.User?> getUserProfile(String userId) async {
    try {
      _logger.i('Getting profile for user: $userId');

      final response =
          await _supabase
              .from('st_users')
              .select('*')
              .eq('id', userId)
              .maybeSingle();

      if (response == null) {
        _logger.w('No profile found for user: $userId');
        return null;
      }

      return models.User.fromJson(response);
    } catch (e) {
      _logger.e('Error getting user profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<models.User> updateProfile({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? location,
    String? bio,
    List<String>? preferredSports,
    String? skillLevel,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to update profile');
      }

      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Unable to get user ID');
      }

      _logger.i('Updating profile for user: $userId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName.trim();
      if (phone != null) updateData['phone'] = phone.trim();
      if (dateOfBirth != null) {
        updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      }
      if (location != null) updateData['location'] = location.trim();
      if (bio != null) updateData['bio'] = bio.trim();
      if (preferredSports != null) {
        updateData['preferred_sports'] = preferredSports;
      }
      if (skillLevel != null) updateData['skill_level'] = skillLevel;

      // Check if profile should be marked as complete
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile != null) {
        final isComplete = _isProfileComplete(
          fullName: fullName ?? currentProfile.fullName,
          phone: phone ?? currentProfile.phone,
          dateOfBirth: dateOfBirth ?? currentProfile.dateOfBirth,
          location: location ?? currentProfile.location,
          preferredSports: preferredSports ?? currentProfile.preferredSports,
        );
        updateData['is_profile_complete'] = isComplete;
      }

      await _supabase.from('st_users').update(updateData).eq('id', userId);

      _logger.i('Profile updated successfully');

      final updatedProfile = await getUserProfile(userId);
      if (updatedProfile == null) {
        throw Exception('Failed to retrieve updated profile');
      }
      return updatedProfile;
    } catch (e) {
      _logger.e('Error updating profile: $e');
      rethrow;
    }
  }

  /// Upload and update user avatar
  Future<String> updateAvatar(dynamic imageFile) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to update avatar');
      }

      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Unable to get user ID');
      }

      _logger.i('Uploading avatar for user: $userId');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_${userId}_$timestamp.jpg';

      // Upload to Supabase Storage
      final uploadPath = 'avatars/$fileName';

      // Handle different file types (web vs mobile)
      if (imageFile is Uint8List) {
        // Web platform - upload bytes directly
        await _supabase.storage
            .from('user-assets')
            .uploadBinary(
              uploadPath,
              imageFile,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } else {
        // Mobile platform - upload File
        await _supabase.storage
            .from('user-assets')
            .upload(uploadPath, imageFile);
      }

      // Get public URL
      final publicUrl = _supabase.storage
          .from('user-assets')
          .getPublicUrl(uploadPath);

      // Update user profile with new avatar URL
      await _supabase
          .from('st_users')
          .update({
            'avatar_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      _logger.i('Avatar updated successfully');
      return publicUrl;
    } catch (e) {
      _logger.e('Error updating avatar: $e');
      rethrow;
    }
  }

  /// Delete user avatar
  Future<void> deleteAvatar() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to delete avatar');
      }

      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Unable to get user ID');
      }

      _logger.i('Deleting avatar for user: $userId');

      final currentProfile = await getCurrentUserProfile();
      if (currentProfile?.avatarUrl != null) {
        // Extract file path from URL and delete from storage
        try {
          final url = currentProfile!.avatarUrl!;
          final uri = Uri.parse(url);
          final path = uri.path
              .split('/')
              .skip(1)
              .join('/'); // Remove leading slash

          await _supabase.storage.from('user-assets').remove([path]);
        } catch (e) {
          _logger.w('Failed to delete avatar file from storage: $e');
          // Continue anyway to clear the URL from profile
        }
      }

      // Clear avatar URL from profile
      await _supabase
          .from('st_users')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      _logger.i('Avatar deleted successfully');
    } catch (e) {
      _logger.e('Error deleting avatar: $e');
      rethrow;
    }
  }

  /// Get user's game statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      _logger.i('Getting stats for user: $userId');

      // Get attendance stats - just count records
      final attendanceResponse = await _supabase
          .from('st_attendances')
          .select('id, game_id, checked_in_at')
          .eq('user_id', userId);

      // Get RSVP stats - using 'response' field not 'status'
      final rsvpResponse = await _supabase
          .from('st_rsvps')
          .select('id, response')
          .eq('user_id', userId);

      // Get team membership stats
      final teamResponse = await _supabase
          .from('st_team_members')
          .select('id, role')
          .eq('user_id', userId);

      // Get game durations for attended games
      final gameIds = attendanceResponse.map((a) => a['game_id']).toList();
      double totalGameHours = 0;

      if (gameIds.isNotEmpty) {
        final gameResponse = await _supabase
            .from('st_games')
            .select('duration_minutes')
            .inFilter('id', gameIds);

        for (final game in gameResponse) {
          if (game['duration_minutes'] != null) {
            totalGameHours += (game['duration_minutes'] as int) / 60.0;
          }
        }
      }

      final totalGamesAttended = attendanceResponse.length;
      final totalRsvps = rsvpResponse.length;
      final acceptedRsvps =
          rsvpResponse.where((r) => r['response'] == 'yes').length;

      final teamsJoined = teamResponse.length;
      final teamsOrganized =
          teamResponse.where((t) => t['role'] == 'organizer').length;

      return {
        'total_games_attended': totalGamesAttended,
        'total_game_hours': totalGameHours.round(),
        'total_rsvps': totalRsvps,
        'accepted_rsvps': acceptedRsvps,
        'teams_joined': teamsJoined,
        'teams_organized': teamsOrganized,
        'attendance_rate':
            totalRsvps > 0
                ? (totalGamesAttended / totalRsvps * 100).round()
                : 0,
      };
    } catch (e) {
      _logger.e('Error getting user stats: $e');
      rethrow;
    }
  }

  /// Check if profile is complete
  bool _isProfileComplete({
    required String fullName,
    String? phone,
    DateTime? dateOfBirth,
    String? location,
    required List<String> preferredSports,
  }) {
    return fullName.isNotEmpty &&
        phone != null &&
        phone.isNotEmpty &&
        dateOfBirth != null &&
        location != null &&
        location.isNotEmpty &&
        preferredSports.isNotEmpty;
  }

  /// Get available skill levels
  List<String> getSkillLevels() {
    return ['beginner', 'intermediate', 'advanced', 'expert'];
  }

  /// Get available sports
  List<String> getAvailableSports() {
    return [
      'Basketball',
      'Football',
      'Soccer',
      'Tennis',
      'Volleyball',
      'Baseball',
      'Softball',
      'Swimming',
      'Running',
      'Cycling',
      'Golf',
      'Rugby',
      'Hockey',
      'Badminton',
      'Table Tennis',
      'Cricket',
      'Wrestling',
      'Boxing',
      'Martial Arts',
      'Rock Climbing',
      'Other',
    ];
  }
}
