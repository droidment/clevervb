import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/team.dart';
import '../../providers/team_provider.dart';
import 'create_team_page.dart';
import 'team_detail_page.dart';
import 'discover_teams_page.dart';

class TeamsPage extends ConsumerStatefulWidget {
  const TeamsPage({super.key});

  @override
  ConsumerState<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends ConsumerState<TeamsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'My Teams'),
            Tab(icon: Icon(Icons.explore), text: 'Discover'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateTeam(),
            tooltip: 'Create Team',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_MyTeamsTab(), const DiscoverTeamsPage()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTeam(),
        tooltip: 'Create Team',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _navigateToCreateTeam() async {
    final result = await Navigator.of(context).push<Team>(
      MaterialPageRoute(builder: (context) => const CreateTeamPage()),
    );

    if (result != null) {
      // Team was created successfully, refresh the teams list
      ref.invalidate(userTeamsProvider);
    }
  }
}

class _MyTeamsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTeamsAsync = ref.watch(userTeamsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userTeamsProvider);
        await ref.read(userTeamsProvider.future);
      },
      child: userTeamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading teams',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(userTeamsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data: (teams) {
          if (teams.isEmpty) {
            return _EmptyTeamsView();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return _TeamCard(team: team);
            },
          );
        },
      ),
    );
  }
}

class _EmptyTeamsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 96,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Teams Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first team or join an existing one to get started!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateTeamPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Team'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      DefaultTabController.of(context).animateTo(1);
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Discover Teams'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends ConsumerWidget {
  final Team team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _navigateToTeamDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      _getSportIcon(team.sportType),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          team.displaySportType,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Privacy indicator
                  Icon(
                    team.isPublic ? Icons.public : Icons.lock,
                    size: 20,
                    color: team.isPublic ? Colors.green : Colors.orange,
                  ),
                ],
              ),

              // Description
              if (team.hasDescription) ...[
                const SizedBox(height: 12),
                Text(
                  team.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.people,
                    label: '${team.memberCount ?? 0} members',
                  ),
                  if (team.hasMaxMembers) ...[
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.people_outline,
                      label: 'Max ${team.maxMembers}',
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'Organizer: ${team.organizerName ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTeamDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TeamDetailPage(teamId: team.id)),
    );
  }

  IconData _getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'soccer':
        return Icons.sports_soccer;
      case 'pickleball':
        return Icons.sports_tennis;
      case 'badminton':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
