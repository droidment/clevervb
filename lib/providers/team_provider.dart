import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/team.dart';
import '../services/team_service.dart';
import 'auth_provider.dart';

part 'team_provider.g.dart';

// ==================== TEAM PROVIDERS ====================

/// Provider for team service singleton
@riverpod
TeamService teamService(TeamServiceRef ref) {
  return TeamService();
}

/// Provider to get a specific team by ID
@riverpod
Future<Team> team(TeamRef ref, String teamId) async {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeam(teamId);
}

/// Provider to get user's teams
@riverpod
Future<List<Team>> userTeams(UserTeamsRef ref) async {
  final authService = ref.watch(authServiceProvider);
  final teamService = ref.watch(teamServiceProvider);

  final user = authService.currentUser;
  if (user == null) return [];

  // Get the st_users.id instead of auth.users.id
  final userId = await authService.getCurrentUserId();
  if (userId == null) return [];

  return teamService.getUserTeams(userId);
}

/// Provider to search teams with filters
@riverpod
Future<List<Team>> searchTeams(
  SearchTeamsRef ref, {
  String? teamName,
  String? sportType,
  bool? isPublic,
  int limit = 20,
  int offset = 0,
}) async {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.searchTeams(
    name: teamName,
    sportType: sportType,
    isPublic: isPublic,
    limit: limit,
    offset: offset,
  );
}

/// Provider to get popular teams
@riverpod
Future<List<Team>> popularTeams(PopularTeamsRef ref, {int limit = 10}) async {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getPopularTeams(limit: limit);
}

// ==================== TEAM MEMBER PROVIDERS ====================

/// Provider to get team members
@riverpod
Future<List<TeamMember>> teamMembers(TeamMembersRef ref, String teamId) async {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamMembers(teamId);
}

// ==================== INVITATION PROVIDERS ====================

/// Provider to get team invitations
@riverpod
Future<List<TeamInvitation>> teamInvitations(
  TeamInvitationsRef ref,
  String teamId,
) async {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamInvitations(teamId);
}

/// Provider to get a specific invitation
@riverpod
Future<TeamInvitation> invitation(
  InvitationRef ref,
  String invitationId,
) async {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getInvitation(invitationId);
}

// ==================== TEAM NOTIFIER ====================

/// State notifier for team operations
@riverpod
class TeamNotifier extends _$TeamNotifier {
  TeamService get _teamService => ref.read(teamServiceProvider);

  @override
  AsyncValue<Team?> build() {
    return const AsyncValue.data(null);
  }

  /// Create a new team
  Future<Team?> createTeam({
    required String name,
    required String sportType,
    String? description,
    bool isPublic = true,
    int? maxMembers,
    bool onlyOrganizerCreatesGames = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      final team = await _teamService.createTeam(
        name: name,
        sportType: sportType,
        description: description,
        isPublic: isPublic,
        maxMembers: maxMembers ?? 8, // Use 8 as default if null
        onlyOrganizerCreatesGames: onlyOrganizerCreatesGames,
      );

      state = AsyncValue.data(team);

      // Invalidate related providers
      ref.invalidate(userTeamsProvider);
      ref.invalidate(searchTeamsProvider);
      ref.invalidate(popularTeamsProvider);

      return team;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Update team information
  Future<Team?> updateTeam({
    required String teamId,
    String? name,
    String? description,
    bool? isPublic,
    int? maxMembers,
  }) async {
    state = const AsyncValue.loading();

    try {
      final team = await _teamService.updateTeam(
        teamId: teamId,
        name: name,
        description: description,
        isPublic: isPublic,
        maxMembers: maxMembers,
      );

      state = AsyncValue.data(team);

      // Invalidate related providers
      ref.invalidate(teamProvider(teamId));
      ref.invalidate(userTeamsProvider);
      ref.invalidate(searchTeamsProvider);

      return team;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Delete team
  Future<bool> deleteTeam(String teamId) async {
    state = const AsyncValue.loading();

    try {
      await _teamService.deleteTeam(teamId);

      state = const AsyncValue.data(null);

      // Invalidate related providers
      ref.invalidate(teamProvider(teamId));
      ref.invalidate(userTeamsProvider);
      ref.invalidate(searchTeamsProvider);
      ref.invalidate(popularTeamsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Join a team
  Future<bool> joinTeam(String teamId, {String? invitationToken}) async {
    try {
      await _teamService.joinTeam(teamId, invitationToken: invitationToken);

      // Invalidate related providers
      ref.invalidate(teamProvider(teamId));
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(userTeamsProvider);

      return true;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return false;
    }
  }

  /// Leave a team
  Future<bool> leaveTeam(String teamId) async {
    try {
      await _teamService.leaveTeam(teamId);

      // Invalidate related providers
      ref.invalidate(teamProvider(teamId));
      ref.invalidate(teamMembersProvider(teamId));
      ref.invalidate(userTeamsProvider);

      return true;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return false;
    }
  }

  /// Remove a member from team
  Future<bool> removeMember(String teamId, String userId) async {
    try {
      await _teamService.removeMember(teamId, userId);

      // Invalidate related providers
      ref.invalidate(teamProvider(teamId));
      ref.invalidate(teamMembersProvider(teamId));

      return true;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return false;
    }
  }
}

// ==================== INVITATION NOTIFIER ====================

/// State notifier for invitation operations
@riverpod
class InvitationNotifier extends _$InvitationNotifier {
  TeamService get _teamService => ref.read(teamServiceProvider);

  @override
  AsyncValue<TeamInvitation?> build() {
    return const AsyncValue.data(null);
  }

  /// Create team invitation
  Future<TeamInvitation?> createInvitation({
    required String teamId,
    required String email,
  }) async {
    state = const AsyncValue.loading();

    try {
      final invitation = await _teamService.createInvitation(
        teamId: teamId,
        email: email,
      );

      state = AsyncValue.data(invitation);

      // Invalidate team invitations
      ref.invalidate(teamInvitationsProvider(teamId));

      return invitation;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

// ==================== TEAM SEARCH NOTIFIER ====================

/// State notifier for team search functionality
@riverpod
class TeamSearchNotifier extends _$TeamSearchNotifier {
  TeamService get _teamService => ref.read(teamServiceProvider);

  @override
  TeamSearchState build() {
    return const TeamSearchState();
  }

  /// Update search filters
  void updateFilters({String? name, String? sportType, bool? isPublic}) {
    state = state.copyWith(
      name: name,
      sportType: sportType,
      isPublic: isPublic,
    );
  }

  /// Clear all filters
  void clearFilters() {
    state = const TeamSearchState();
  }

  /// Search teams with current filters
  Future<List<Team>> searchTeams({int limit = 20, int offset = 0}) async {
    return _teamService.searchTeams(
      name: state.name,
      sportType: state.sportType,
      isPublic: state.isPublic,
      limit: limit,
      offset: offset,
    );
  }
}

// ==================== TEAM SEARCH STATE ====================

class TeamSearchState {
  final String? name;
  final String? sportType;
  final bool? isPublic;

  const TeamSearchState({this.name, this.sportType, this.isPublic});

  TeamSearchState copyWith({String? name, String? sportType, bool? isPublic}) {
    return TeamSearchState(
      name: name ?? this.name,
      sportType: sportType ?? this.sportType,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  bool get hasFilters =>
      (name != null && name!.isNotEmpty) ||
      (sportType != null && sportType!.isNotEmpty) ||
      isPublic != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamSearchState &&
        other.name == name &&
        other.sportType == sportType &&
        other.isPublic == isPublic;
  }

  @override
  int get hashCode => Object.hash(name, sportType, isPublic);

  @override
  String toString() {
    return 'TeamSearchState(name: $name, sportType: $sportType, isPublic: $isPublic)';
  }
}
