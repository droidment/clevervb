import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import 'auth_provider.dart';

part 'game_provider.g.dart';

/// Provider for GameService
@riverpod
GameService gameService(GameServiceRef ref) => GameService();

/// Provider to get games for a specific team
@riverpod
Future<List<Game>> teamGames(TeamGamesRef ref, String teamId) async {
  final gameService = ref.watch(gameServiceProvider);
  return gameService.getTeamGames(teamId, upcomingOnly: false);
}

/// Provider to get upcoming games for a specific team
@riverpod
Future<List<Game>> upcomingTeamGames(
  UpcomingTeamGamesRef ref,
  String teamId,
) async {
  final gameService = ref.watch(gameServiceProvider);
  return gameService.getTeamGames(teamId, upcomingOnly: true);
}

/// Provider to get games for current user's teams
@riverpod
Future<List<Game>> userGames(UserGamesRef ref) async {
  final authService = ref.watch(authServiceProvider);
  final gameService = ref.watch(gameServiceProvider);

  final user = authService.currentUser;
  if (user == null) return [];

  // Get the st_users.id instead of auth.users.id
  final userId = await authService.getCurrentUserId();
  if (userId == null) return [];

  return gameService.getUserGames(userId);
}

/// Provider to get upcoming games for current user's teams
@riverpod
Future<List<Game>> upcomingUserGames(UpcomingUserGamesRef ref) async {
  final authService = ref.watch(authServiceProvider);
  final gameService = ref.watch(gameServiceProvider);

  final user = authService.currentUser;
  if (user == null) return [];

  // Get the st_users.id instead of auth.users.id
  final userId = await authService.getCurrentUserId();
  if (userId == null) return [];

  return gameService.getUserGames(userId, upcomingOnly: true);
}

/// Provider to get games the user has RSVP'd to
@riverpod
Future<List<Game>> userRsvpedGames(UserRsvpedGamesRef ref) async {
  final authService = ref.watch(authServiceProvider);
  final gameService = ref.watch(gameServiceProvider);

  final user = authService.currentUser;
  if (user == null) return [];

  // Get the st_users.id instead of auth.users.id
  final userId = await authService.getCurrentUserId();
  if (userId == null) return [];

  return gameService.getUserRsvpedGames(userId);
}

/// Provider to get upcoming games the user has RSVP'd to
@riverpod
Future<List<Game>> upcomingUserRsvpedGames(
  UpcomingUserRsvpedGamesRef ref,
) async {
  final authService = ref.watch(authServiceProvider);
  final gameService = ref.watch(gameServiceProvider);

  final user = authService.currentUser;
  if (user == null) return [];

  // Get the st_users.id instead of auth.users.id
  final userId = await authService.getCurrentUserId();
  if (userId == null) return [];

  return gameService.getUserRsvpedGames(userId, upcomingOnly: true);
}

/// Provider to get a specific game by ID
@riverpod
Future<Game> game(GameRef ref, String gameId) async {
  final gameService = ref.watch(gameServiceProvider);
  return gameService.getGame(gameId);
}

/// Provider to discover public games
@riverpod
Future<List<Game>> discoverGames(
  DiscoverGamesRef ref, {
  double? latitude,
  double? longitude,
  double radiusKm = 25.0,
  String? sport,
  DateTime? startDate,
  DateTime? endDate,
  int limit = 50,
}) async {
  final gameService = ref.watch(gameServiceProvider);
  return gameService.discoverGames(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
    sport: sport,
    startDate: startDate,
    endDate: endDate,
    limit: limit,
  );
}

/// Provider to get current user's RSVP for a specific game (if any)
@riverpod
Future<Map<String, dynamic>?> userGameRsvp(
  UserGameRsvpRef ref,
  String gameId,
) async {
  final authService = ref.watch(authServiceProvider);
  final gameService = ref.watch(gameServiceProvider);

  // Ensure user is logged in
  final user = authService.currentUser;
  if (user == null) return null;

  final userId = await authService.getCurrentUserId();
  if (userId == null) return null;

  return gameService.getUserRsvp(gameId, userId);
}
