import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/team.dart';
import '../config/env.dart';
import 'auth_service.dart';

class TeamService {
  static final _instance = TeamService._internal();
  factory TeamService() => _instance;
  TeamService._internal();

  final _logger = Logger();
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // ==================== TEAM CRUD OPERATIONS ====================

  /// Create a new team
  Future<Team> createTeam({
    required String name,
    required String sportType,
    String? description,
    bool isPublic = true,
    int maxMembers = 8, // Default to 8 players to match database default
  }) async {
    try {
      _logger.i('Creating team: $name');
      _logger.i('Checking authentication...');

      final authService = AuthService();
      final currentUser = authService.currentUser;
      _logger.i(
        'Current auth user: ${currentUser?.id} (${currentUser?.email})',
      );

      final userId = await authService.getCurrentUserId();
      _logger.i('Retrieved st_users.id: $userId');

      if (userId == null) {
        throw Exception('User must be authenticated to create a team');
      }

      final teamId = _uuid.v4();
      final now = DateTime.now();

      // Create team record
      await _supabase.from('st_teams').insert({
        'id': teamId,
        'name': name.trim(),
        'sport': sportType.toLowerCase(), // Required NOT NULL column
        'sport_type': sportType.toLowerCase(), // Compatibility column
        'description': description?.trim(),
        'organizer_id': userId,
        'is_public': isPublic,
        'max_members': maxMembers,
        'max_players': maxMembers, // Also set the original column
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Add organizer as team member
      await _supabase.from('st_team_members').insert({
        'team_id': teamId,
        'user_id': userId,
        'role': 'organizer',
        'joined_at': now.toIso8601String(),
      });

      _logger.i('Team created successfully: $teamId');

      // Return the created team
      return getTeam(teamId);
    } catch (e) {
      _logger.e('Error creating team: $e');
      rethrow;
    }
  }

  /// Get team by ID with member count and organizer info
  Future<Team> getTeam(String teamId) async {
    try {
      final response =
          await _supabase
              .from('st_teams')
              .select('''
            *,
            st_users!st_teams_organizer_id_fkey(full_name, avatar_url),
            st_team_members(count)
          ''')
              .eq('id', teamId)
              .maybeSingle();

      if (response == null) {
        throw Exception('Team not found');
      }

      return _mapTeamFromResponse(response);
    } catch (e) {
      _logger.e('Error getting team: $e');
      rethrow;
    }
  }

  /// Update team information
  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? description,
    bool? isPublic,
    int? maxMembers,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to update team');
      }

      // Check if user is organizer
      final isOrganizer = await _isTeamOrganizer(teamId, user.id);
      if (!isOrganizer) {
        throw Exception('Only team organizers can update team information');
      }

      _logger.i('Updating team: $teamId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name.trim();
      if (description != null) updateData['description'] = description.trim();
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (maxMembers != null) {
        updateData['max_members'] = maxMembers;
        updateData['max_players'] = maxMembers; // Keep both columns in sync
      }

      await _supabase.from('st_teams').update(updateData).eq('id', teamId);

      _logger.i('Team updated successfully');

      return getTeam(teamId);
    } catch (e) {
      _logger.e('Error updating team: $e');
      rethrow;
    }
  }

  /// Delete team (organizer only)
  Future<void> deleteTeam(String teamId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to delete team');
      }

      // Get the st_users.id for the current user
      final authService = AuthService();
      final currentUserId = await authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not find user profile');
      }

      // Check if user is organizer
      final isOrganizer = await _isTeamOrganizer(teamId, currentUserId);
      if (!isOrganizer) {
        throw Exception('Only team organizers can delete teams');
      }

      _logger.i('Deleting team: $teamId');

      // Delete team (cascade will handle related records)
      await _supabase.from('st_teams').delete().eq('id', teamId);

      _logger.i('Team deleted successfully');
    } catch (e) {
      _logger.e('Error deleting team: $e');
      rethrow;
    }
  }

  // ==================== MEMBER MANAGEMENT ====================

  /// Get team members with user details
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    try {
      final response = await _supabase
          .from('st_team_members')
          .select('''
            *,
            st_users!st_team_members_user_id_fkey(full_name, email, avatar_url)
          ''')
          .eq('team_id', teamId)
          .order('joined_at');

      return response
          .map((member) => _mapTeamMemberFromResponse(member))
          .toList();
    } catch (e) {
      _logger.e('Error getting team members: $e');
      rethrow;
    }
  }

  /// Join a team (for public teams or with invitation)
  Future<void> joinTeam(String teamId, {String? invitationToken}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to join team');
      }

      final authService = AuthService();
      final currentUserId = await authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Could not find user profile');
      }

      // Check if already a member
      final existingMember =
          await _supabase
              .from('st_team_members')
              .select('team_id')
              .eq('team_id', teamId)
              .eq('user_id', currentUserId)
              .maybeSingle();

      if (existingMember != null) {
        throw Exception('You are already a member of this team');
      }

      // Get team info
      final team = await getTeam(teamId);

      // Check if team is full
      if (team.isFull) {
        throw Exception('Team is full');
      }

      // If team is not public, require invitation token
      if (!team.isPublic && invitationToken != null) {
        await _validateAndUseInvitation(invitationToken, user.email!);
      } else if (!team.isPublic) {
        throw Exception('Team is private and requires an invitation');
      }

      _logger.i('User ${user.email} joining team: $teamId');

      // Add member
      await _supabase.from('st_team_members').insert({
        'team_id': teamId,
        'user_id': currentUserId, // Use st_users.id instead of auth.uid()
        'role': 'player',
        'joined_at': DateTime.now().toIso8601String(),
      });

      _logger.i('User joined team successfully');
    } catch (e) {
      _logger.e('Error joining team: $e');
      rethrow;
    }
  }

  /// Leave a team
  Future<void> leaveTeam(String teamId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to leave team');
      }

      // Check if user is organizer
      final isOrganizer = await _isTeamOrganizer(teamId, user.id);
      if (isOrganizer) {
        throw Exception(
          'Team organizers cannot leave the team. Delete the team instead.',
        );
      }

      _logger.i('User ${user.email} leaving team: $teamId');

      await _supabase
          .from('st_team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', user.id);

      _logger.i('User left team successfully');
    } catch (e) {
      _logger.e('Error leaving team: $e');
      rethrow;
    }
  }

  /// Remove a member from team (organizer only)
  Future<void> removeMember(String teamId, String userId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to remove members');
      }

      // Check if current user is organizer
      final isOrganizer = await _isTeamOrganizer(teamId, currentUser.id);
      if (!isOrganizer) {
        throw Exception('Only team organizers can remove members');
      }

      // Cannot remove organizer
      final targetIsOrganizer = await _isTeamOrganizer(teamId, userId);
      if (targetIsOrganizer) {
        throw Exception('Cannot remove team organizer');
      }

      _logger.i('Removing member $userId from team: $teamId');

      await _supabase
          .from('st_team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', userId);

      _logger.i('Member removed successfully');
    } catch (e) {
      _logger.e('Error removing member: $e');
      rethrow;
    }
  }

  // ==================== INVITATION MANAGEMENT ====================

  /// Create team invitation
  Future<TeamInvitation> createInvitation({
    required String teamId,
    required String email,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create invitations');
      }

      // Check if user is organizer
      final isOrganizer = await _isTeamOrganizer(teamId, user.id);
      if (!isOrganizer) {
        throw Exception('Only team organizers can create invitations');
      }

      // Check if email is already a team member
      final existingMember =
          await _supabase
              .from('st_team_members')
              .select('user_id')
              .eq('team_id', teamId)
              .eq('st_users.email', email)
              .maybeSingle();

      if (existingMember != null) {
        throw Exception('User is already a team member');
      }

      _logger.i('Creating invitation for $email to team: $teamId');

      final invitationId = _uuid.v4();
      final token = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(Env.invitationExpiryDuration);

      await _supabase.from('st_invitations').insert({
        'id': invitationId,
        'team_id': teamId,
        'invited_by': user.id,
        'invited_email': email.toLowerCase().trim(),
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      });

      _logger.i('Invitation created successfully');

      return getInvitation(invitationId);
    } catch (e) {
      _logger.e('Error creating invitation: $e');
      rethrow;
    }
  }

  /// Get invitation by ID
  Future<TeamInvitation> getInvitation(String invitationId) async {
    try {
      final response =
          await _supabase
              .from('st_invitations')
              .select('''
            *,
            st_teams!st_invitations_team_id_fkey(name),
            st_users!st_invitations_invited_by_fkey(full_name)
          ''')
              .eq('id', invitationId)
              .maybeSingle();

      if (response == null) {
        throw Exception('Invitation not found');
      }

      return _mapInvitationFromResponse(response);
    } catch (e) {
      _logger.e('Error getting invitation: $e');
      rethrow;
    }
  }

  /// Get team invitations
  Future<List<TeamInvitation>> getTeamInvitations(String teamId) async {
    try {
      final response = await _supabase
          .from('st_invitations')
          .select('''
            *,
            st_teams!st_invitations_team_id_fkey(name),
            st_users!st_invitations_invited_by_fkey(full_name)
          ''')
          .eq('team_id', teamId)
          .order('created_at', ascending: false);

      return response
          .map((invitation) => _mapInvitationFromResponse(invitation))
          .toList();
    } catch (e) {
      _logger.e('Error getting team invitations: $e');
      rethrow;
    }
  }

  // ==================== TEAM DISCOVERY ====================

  /// Search teams by criteria
  Future<List<Team>> searchTeams({
    String? name,
    String? sportType,
    bool? isPublic,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('st_teams').select('''
            *,
            st_users!st_teams_organizer_id_fkey(full_name, avatar_url),
            st_team_members(count)
          ''');

      // Add filters
      if (name != null && name.isNotEmpty) {
        query = query.ilike('name', '%$name%');
      }

      if (sportType != null && sportType.isNotEmpty) {
        query = query.eq('sport_type', sportType.toLowerCase());
      }

      if (isPublic != null) {
        query = query.eq('is_public', isPublic);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((team) => _mapTeamFromResponse(team)).toList();
    } catch (e) {
      _logger.e('Error searching teams: $e');
      rethrow;
    }
  }

  /// Get user's teams (where user is a member)
  Future<List<Team>> getUserTeams(String userId) async {
    try {
      final response = await _supabase
          .from('st_team_members')
          .select('''
            role,
            joined_at,
            st_teams!inner(
              *,
              st_users!st_teams_organizer_id_fkey(full_name, avatar_url)
            )
          ''')
          .eq('user_id', userId)
          .order('joined_at', ascending: false);

      return response.map((memberData) {
        final teamData = memberData['st_teams'];
        return _mapTeamFromResponse(teamData);
      }).toList();
    } catch (e) {
      _logger.e('Error getting user teams: $e');
      rethrow;
    }
  }

  /// Get popular teams (most members)
  Future<List<Team>> getPopularTeams({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('st_teams')
          .select('''
            *,
            st_users!st_teams_organizer_id_fkey(full_name, avatar_url),
            st_team_members(count)
          ''')
          .eq('is_public', true)
          .order(
            'created_at',
            ascending: false,
          ) // Will be ordered by member count in real impl
          .limit(limit);

      return response.map((team) => _mapTeamFromResponse(team)).toList();
    } catch (e) {
      _logger.e('Error getting popular teams: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Check if user is team organizer
  Future<bool> _isTeamOrganizer(String teamId, String userId) async {
    try {
      final response =
          await _supabase
              .from('st_team_members')
              .select('role')
              .eq('team_id', teamId)
              .eq('user_id', userId)
              .eq('role', 'organizer')
              .maybeSingle();

      return response != null;
    } catch (e) {
      _logger.e('Error checking organizer status: $e');
      return false;
    }
  }

  /// Validate and use invitation token
  Future<void> _validateAndUseInvitation(String token, String email) async {
    final invitation =
        await _supabase
            .from('st_invitations')
            .select('*')
            .eq('token', token)
            .eq('invited_email', email.toLowerCase())
            .maybeSingle();

    if (invitation == null) {
      throw Exception('Invalid invitation');
    }

    final expiresAt = DateTime.parse(invitation['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Invitation has expired');
    }

    if (invitation['used_at'] != null) {
      throw Exception('Invitation has already been used');
    }

    // Mark invitation as used
    await _supabase
        .from('st_invitations')
        .update({'used_at': DateTime.now().toIso8601String()})
        .eq('token', token);
  }

  /// Map database response to Team object
  Team _mapTeamFromResponse(Map<String, dynamic> response) {
    final organizer = response['st_users'];
    final memberCount =
        response['st_team_members'] is List
            ? (response['st_team_members'] as List).length
            : response['st_team_members']?['count'] ?? 0;

    return Team(
      id: response['id'],
      name: response['name'],
      sportType: response['sport_type'],
      description: response['description'],
      organizerId: response['organizer_id'],
      isPublic: response['is_public'],
      maxMembers: response['max_members'],
      createdAt: DateTime.parse(response['created_at']),
      updatedAt: DateTime.parse(response['updated_at']),
      memberCount: memberCount,
      organizerName: organizer?['full_name'],
      organizerAvatarUrl: organizer?['avatar_url'],
    );
  }

  /// Map database response to TeamMember object
  TeamMember _mapTeamMemberFromResponse(Map<String, dynamic> response) {
    final user = response['st_users'];

    return TeamMember(
      teamId: response['team_id'],
      userId: response['user_id'],
      role:
          response['role'] == 'organizer'
              ? TeamRole.organizer
              : TeamRole.member,
      joinedAt: DateTime.parse(response['joined_at']),
      fullName: user?['full_name'],
      email: user?['email'],
      avatarUrl: user?['avatar_url'],
    );
  }

  /// Map database response to TeamInvitation object
  TeamInvitation _mapInvitationFromResponse(Map<String, dynamic> response) {
    final team = response['st_teams'];
    final inviter = response['st_users'];

    return TeamInvitation(
      id: response['id'],
      teamId: response['team_id'],
      invitedBy: response['invited_by'],
      invitedEmail: response['invited_email'],
      token: response['token'],
      expiresAt: DateTime.parse(response['expires_at']),
      usedAt:
          response['used_at'] != null
              ? DateTime.parse(response['used_at'])
              : null,
      createdAt: DateTime.parse(response['created_at']),
      teamName: team?['name'],
      inviterName: inviter?['full_name'],
    );
  }
}
