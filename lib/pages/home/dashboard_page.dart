import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../providers/team_provider.dart';
import '../../models/game.dart';
import '../../models/team.dart';
import '../../services/game_service.dart';
import '../game_checkin_page.dart';
import '../teams/team_detail_page.dart';
import '../game_detail_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Track games that have been cancelled to filter them out immediately
  final Set<String> _cancelledGameIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final upcomingGamesAsync = ref.watch(upcomingUserRsvpedGamesProvider);
    final userTeamsAsync = ref.watch(userTeamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(upcomingUserRsvpedGamesProvider);
          ref.invalidate(userTeamsProvider);
          ref.invalidate(userRsvpedGamesProvider);

          // Wait for the refresh to complete
          await ref.read(upcomingUserRsvpedGamesProvider.future);
          await ref.read(userTeamsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(context),
              const SizedBox(height: 24),

              // Quick Stats
              _buildQuickStats(context, upcomingGamesAsync, userTeamsAsync),
              const SizedBox(height: 24),

              // Upcoming Games Section
              _buildUpcomingGamesSection(context, ref, upcomingGamesAsync),
              const SizedBox(height: 24),

              // Your Teams Section
              _buildTeamsSection(context, userTeamsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_volleyball, size: 48, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for your next game?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    AsyncValue<List<Game>> upcomingGamesAsync,
    AsyncValue<List<Team>> userTeamsAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.event,
            title: 'Upcoming Games',
            value: upcomingGamesAsync.when(
              data: (games) {
                final filteredCount =
                    games
                        .where((game) => !_cancelledGameIds.contains(game.id))
                        .length;
                return filteredCount.toString();
              },
              loading: () => '...',
              error: (_, __) => '0',
            ),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.group,
            title: 'Your Teams',
            value: userTeamsAsync.when(
              data: (teams) => teams.length.toString(),
              loading: () => '...',
              error: (_, __) => '0',
            ),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingGamesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Game>> upcomingGamesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Games',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        upcomingGamesAsync.when(
          data: (games) {
            if (games.isEmpty) {
              return _buildEmptyState(
                context,
                icon: Icons.event_available,
                title: 'No upcoming games',
                subtitle: 'Browse games to join some matches!',
              );
            }
            // Filter out cancelled games for immediate UI update
            final filteredGames =
                games
                    .where((game) => !_cancelledGameIds.contains(game.id))
                    .toList();

            return Column(
              children:
                  filteredGames
                      .take(3)
                      .map((game) => _buildGameCard(context, ref, game))
                      .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) =>
                  _buildErrorState(context, 'Failed to load games'),
        ),
      ],
    );
  }

  Widget _buildTeamsSection(
    BuildContext context,
    AsyncValue<List<Team>> userTeamsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Teams',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        userTeamsAsync.when(
          data: (teams) {
            if (teams.isEmpty) {
              return _buildEmptyState(
                context,
                icon: Icons.group_add,
                title: 'No teams yet',
                subtitle: 'Create or join a team to get started!',
              );
            }
            return Column(
              children:
                  teams
                      .take(3)
                      .map((team) => _buildTeamCard(context, team))
                      .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) =>
                  _buildErrorState(context, 'Failed to load teams'),
        ),
      ],
    );
  }

  Widget _buildGameCard(BuildContext context, WidgetRef ref, Game game) {
    final timeUntil = game.scheduledAt.difference(DateTime.now());
    final timeUntilText = _formatDuration(timeUntil);
    final isWithin12Hours = timeUntil.inHours < 12 && timeUntil.inMinutes > 0;
    final rsvpCount = game.rsvpCount ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(_getSportIcon(game.sport), color: Colors.white, size: 20),
        ),
        title: Text(
          game.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${game.venue} • ${game.sport}'),
            Row(
              children: [
                Text(
                  timeUntilText,
                  style: TextStyle(
                    color: timeUntil.isNegative ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        rsvpCount >= game.maxPlayers
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          rsvpCount >= game.maxPlayers
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people,
                        size: 12,
                        color:
                            rsvpCount >= game.maxPlayers
                                ? Colors.red[700]
                                : Colors.green[700],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$rsvpCount/${game.maxPlayers}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              rsvpCount >= game.maxPlayers
                                  ? Colors.red[700]
                                  : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (game.canCheckIn)
              IconButton(
                icon: Icon(Icons.login, color: Colors.green[600], size: 20),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GameCheckinPage(gameId: game.id),
                    ),
                  );
                },
                tooltip: 'Check In',
              ),
            IconButton(
              icon: Icon(
                Icons.cancel_outlined,
                color: Colors.red[400],
                size: 20,
              ),
              onPressed:
                  () => _showCancelRsvpDialog(
                    context,
                    ref,
                    game,
                    isWithin12Hours,
                  ),
              tooltip: 'Cancel RSVP',
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
        onTap: () => _showGameDetails(context, game),
      ),
    );
  }

  void _showGameDetails(BuildContext context, Game game) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GameDetailPage(game: game)));
  }

  Future<void> _showCancelRsvpDialog(
    BuildContext context,
    WidgetRef ref,
    Game game,
    bool isWithin12Hours,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel RSVP'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to cancel your RSVP for "${game.title}"?',
                ),
                if (isWithin12Hours) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This game is less than 12 hours away. Canceling now may leave the organizer short-handed.',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep RSVP'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cancel RSVP'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await _cancelRsvp(context, ref, game);
    }
  }

  Future<void> _cancelRsvp(
    BuildContext context,
    WidgetRef ref,
    Game game,
  ) async {
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canceling RSVP...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Optimistically update UI - add to cancelled set for immediate removal
      setState(() {
        _cancelledGameIds.add(game.id);
      });

      // Use the GameService to cancel the RSVP
      final gameService = GameService();
      await gameService.removeRsvp(game.id);

      // Aggressive refresh strategy - invalidate everything first
      ref.invalidate(upcomingUserRsvpedGamesProvider);
      ref.invalidate(userRsvpedGamesProvider);
      ref.invalidate(gameServiceProvider);

      // Wait a moment for invalidation to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Force refresh all related providers
      ref.refresh(upcomingUserRsvpedGamesProvider);
      ref.refresh(userRsvpedGamesProvider);

      // Also refresh the discovery provider in case it's cached
      ref.invalidate(discoverGamesProvider);

      // Clear the cancelled game from our local set since it's truly cancelled now
      setState(() {
        _cancelledGameIds.remove(game.id);
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RSVP canceled for "${game.title}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // On error, remove from cancelled set to restore the game in UI
      setState(() {
        _cancelledGameIds.remove(game.id);
      });

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel RSVP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTeamCard(BuildContext context, Team team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            team.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${team.memberCount} members • ${team.sportType}'),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TeamDetailPage(teamId: team.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'soccer':
        return Icons.sports_soccer;
      case 'pickleball':
        return Icons.sports_tennis; // Using tennis icon for pickleball
      default:
        return Icons.sports;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Game started';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return 'In $days day${days == 1 ? '' : 's'}';
    } else if (hours > 0) {
      return 'In $hours hour${hours == 1 ? '' : 's'}';
    } else if (minutes > 0) {
      return 'In $minutes minute${minutes == 1 ? '' : 's'}';
    } else {
      return 'Starting soon!';
    }
  }
}
