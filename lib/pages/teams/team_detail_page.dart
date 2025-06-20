import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_provider.dart';
import '../../providers/game_provider.dart';
import '../../models/team.dart';
import '../../models/game.dart';
import '../games/game_schedule_page.dart';
import 'package:intl/intl.dart';
import '../../services/team_service.dart';
import '../game_detail_page.dart';
import '../../providers/profile_provider.dart';
import '../../services/deep_link_service.dart';

// Helper function to delete team
Future<void> _deleteTeam(
  BuildContext context,
  WidgetRef ref,
  Team team,
  String teamId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Delete Team'),
          content: Text(
            'Are you sure you want to delete "${team.name}"?\n\n'
            '🔒 Authorization: Only team creators or admins can delete teams\n\n'
            '⚠️ WARNING: This will permanently delete:\n'
            '• All scheduled games for this team\n'
            '• All attendance records and check-ins\n'
            '• All fee records and payment history\n'
            '• All team member records\n'
            '• All pending invitations\n\n'
            'This action cannot be undone!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
  );

  if (confirmed != true) return;

  try {
    final teamService = TeamService();
    await teamService.deleteTeam(team.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh teams list and navigate back
      ref.invalidate(teamProvider(teamId));
      ref.invalidate(userTeamsProvider);
      Navigator.of(context).pop(true); // Return true to indicate deletion
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting team: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class TeamDetailPage extends ConsumerWidget {
  final String teamId;

  const TeamDetailPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));

    return teamAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stackTrace) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load team',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString()),
                ],
              ),
            ),
          ),
      data:
          (team) => Scaffold(
            appBar: AppBar(
              title: Text(team.name),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: [
                Builder(
                  builder: (context) {
                    final currentProfileAsync = ref.watch(
                      currentUserProfileProvider,
                    );
                    final stUserId = currentProfileAsync.maybeWhen(
                      data: (profile) => profile?.id,
                      orElse: () => null,
                    );
                    final isOrganizer = team.organizerId == stUserId;
                    final canCreate =
                        !team.onlyOrganizerCreatesGames || isOrganizer;
                    return canCreate
                        ? IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        GameSchedulePage(teamId: teamId),
                              ),
                            );
                            if (result == true) {
                              ref.invalidate(teamProvider(teamId));
                            }
                          },
                          tooltip: 'Schedule Game',
                        )
                        : const SizedBox.shrink();
                  },
                ),
                Builder(
                  builder: (context) {
                    final currentProfileAsync = ref.watch(
                      currentUserProfileProvider,
                    );
                    final stUserId = currentProfileAsync.maybeWhen(
                      data: (p) => p?.id,
                      orElse: () => null,
                    );
                    final isOrganizer = team.organizerId == stUserId;
                    if (!isOrganizer) return const SizedBox.shrink();
                    return PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteTeam(context, ref, team, teamId);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete Team',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    );
                  },
                ),
              ],
            ),

            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team header card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.sports_volleyball,
                                  size: 32,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      team.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      team.displaySportType,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                team.isPublic ? Icons.public : Icons.lock,
                                color:
                                    team.isPublic
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                            ],
                          ),

                          if (team.hasDescription) ...[
                            const SizedBox(height: 16),
                            Text(
                              team.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],

                          const SizedBox(height: 16),
                          Text(
                            'Organizer: ${team.organizerName ?? 'Unknown'}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Team stats
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.people, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                '${team.memberCount ?? 0}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Text('Members'),
                            ],
                          ),
                          if (team.hasMaxMembers)
                            Column(
                              children: [
                                const Icon(Icons.people_outline, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  '${team.maxMembers}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Text('Max'),
                              ],
                            ),
                          Column(
                            children: [
                              const Icon(Icons.calendar_today, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                'Created',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Text('Recently'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Team Members section
                  _TeamMembersSection(teamId: teamId),

                  const SizedBox(height: 16),

                  // Team Games section
                  _TeamGamesSection(teamId: teamId),
                ],
              ),
            ),
          ),
    );
  }
}

class _TeamMembersSection extends ConsumerWidget {
  final String teamId;

  const _TeamMembersSection({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamMembersAsync = ref.watch(teamMembersProvider(teamId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team Members',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                teamMembersAsync.when(
                  data:
                      (members) => Chip(
                        label: Text('${members.length}'),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                  loading:
                      () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            teamMembersAsync.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (error, stackTrace) => Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load members',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              data: (members) {
                if (members.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No members yet'),
                    ),
                  );
                }

                return Column(
                  children:
                      members
                          .map((member) => _MemberListItem(member: member))
                          .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  final TeamMember member;

  const _MemberListItem({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            backgroundImage:
                member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                    ? NetworkImage(member.avatarUrl!)
                    : null,
            child:
                member.avatarUrl == null || member.avatarUrl!.isEmpty
                    ? Text(
                      _getInitials(member.fullName ?? member.email ?? 'U'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName ?? member.email ?? 'Unknown User',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  member.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  member.isOrganizer
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.role.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    member.isOrganizer
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}

class _TeamGamesSection extends ConsumerWidget {
  final String teamId;

  const _TeamGamesSection({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch all games for the team so we can split into upcoming vs past.
    final teamGamesAsync = ref.watch(teamGamesProvider(teamId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Games',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                teamGamesAsync.when(
                  data: (games) {
                    final now = DateTime.now();
                    final upcomingCount =
                        games.where((g) => g.scheduledAt.isAfter(now)).length;
                    return Chip(
                      label: Text('$upcomingCount'),
                      backgroundColor:
                          upcomingCount > 0
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color:
                            upcomingCount > 0
                                ? Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                  loading:
                      () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            teamGamesAsync.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (error, stackTrace) => Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load games',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              data: (games) {
                if (games.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_volleyball_outlined,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No upcoming games',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Schedule your first game!',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final now = DateTime.now();

                final upcomingGames = List<Game>.from(
                  games.where((g) => g.scheduledAt.isAfter(now)),
                )..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

                final pastGames = List<Game>.from(
                  games.where((g) => !g.scheduledAt.isAfter(now)),
                )..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

                return Column(
                  children: [
                    if (upcomingGames.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'No upcoming games',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ...upcomingGames.map((g) => _GameListItem(game: g)),

                    if (pastGames.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ExpansionTile(
                        title: Text(
                          'Past Games',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text('${pastGames.length}'),
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            ),
                            const Icon(Icons.expand_more),
                          ],
                        ),
                        children:
                            pastGames
                                .map(
                                  (g) => Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      right: 8.0,
                                      bottom: 4.0,
                                    ),
                                    child: _GameListItem(game: g),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ],
                );
              },
            ),

            // View All Games Button (if there are games)
            teamGamesAsync.when(
              data: (games) {
                final now = DateTime.now();
                final upcomingGames =
                    games.where((g) => g.scheduledAt.isAfter(now)).toList();
                return upcomingGames.length > 3
                    ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All games page coming soon!'),
                              ),
                            );
                          },
                          child: Text('View All ${upcomingGames.length} Games'),
                        ),
                      ),
                    )
                    : const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameListItem extends ConsumerWidget {
  final Game game;

  const _GameListItem({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isUpcoming = game.scheduledAt.isAfter(now);
    final timeUntil = game.scheduledAt.difference(now);

    String timeText;
    if (isUpcoming) {
      if (timeUntil.inDays > 0) {
        timeText =
            'In ${timeUntil.inDays} day${timeUntil.inDays == 1 ? '' : 's'}';
      } else if (timeUntil.inHours > 0) {
        timeText =
            'In ${timeUntil.inHours} hour${timeUntil.inHours == 1 ? '' : 's'}';
      } else if (timeUntil.inMinutes > 0) {
        timeText =
            'In ${timeUntil.inMinutes} minute${timeUntil.inMinutes == 1 ? '' : 's'}';
      } else {
        timeText = 'Starting soon!';
      }
    } else {
      final timeSince = now.difference(game.scheduledAt);
      if (timeSince.inDays > 0) {
        timeText =
            '${timeSince.inDays} day${timeSince.inDays == 1 ? '' : 's'} ago';
      } else if (timeSince.inHours > 0) {
        timeText =
            '${timeSince.inHours} hour${timeSince.inHours == 1 ? '' : 's'} ago';
      } else {
        timeText = 'Recently';
      }
    }

    final rsvpCount = game.rsvpCount ?? 0;

    // Determine current user's RSVP (yes/no/maybe/null)
    final userRsvpAsync = ref.watch(userGameRsvpProvider(game.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _showGameDetails(context, game),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color:
                  isUpcoming
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Game status icon
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    isUpcoming
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  isUpcoming ? Icons.schedule : Icons.check_circle_outline,
                  size: 16,
                  color:
                      isUpcoming
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),

              // Game details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            game.venue,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d • h:mm a').format(game.scheduledAt),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // RSVP count indicator
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
                            borderRadius: BorderRadius.circular(6),
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
                                size: 10,
                                color:
                                    rsvpCount >= game.maxPlayers
                                        ? Colors.red[700]
                                        : Colors.green[700],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$rsvpCount/${game.maxPlayers}',
                                style: TextStyle(
                                  fontSize: 10,
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
              ),

              // Time until game, share, RSVP info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Share button
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Share Game',
                    onPressed: () async {
                      await DeepLinkService().shareGameInvite(game.id);
                    },
                  ),
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          isUpcoming
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  userRsvpAsync.when(
                    data: (rsvp) {
                      if (!game.requiresRsvp || !isUpcoming) {
                        return const SizedBox.shrink();
                      }

                      if (rsvp == null) {
                        // Show RSVP Now button
                        return _buildStatusChip(
                          context,
                          label: 'RSVP Now',
                          icon: Icons.how_to_reg,
                          isActive: game.isRsvpOpen,
                        );
                      }

                      final response =
                          (rsvp['response'] as String?)?.toLowerCase();
                      switch (response) {
                        case 'yes':
                          return _buildStatusChip(
                            context,
                            label: 'Going',
                            icon: Icons.check,
                            color: Colors.green,
                          );
                        case 'no':
                          return _buildStatusChip(
                            context,
                            label: "Can't Go",
                            icon: Icons.cancel,
                            color: Colors.red,
                          );
                        case 'maybe':
                          return _buildStatusChip(
                            context,
                            label: 'Maybe',
                            icon: Icons.help_outline,
                            color: Colors.orange,
                          );
                        default:
                          return _buildStatusChip(
                            context,
                            label: 'RSVP Now',
                            icon: Icons.how_to_reg,
                            isActive: game.isRsvpOpen,
                          );
                      }
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  // Arrow indicator for tap
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    Color? color,
    bool isActive = true,
  }) {
    final bg =
        color ??
        (isActive
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer);
    final fg =
        color != null
            ? Colors.white
            : (isActive
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onErrorContainer);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  void _showGameDetails(BuildContext context, Game game) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GameDetailPage(game: game)));
  }
}
