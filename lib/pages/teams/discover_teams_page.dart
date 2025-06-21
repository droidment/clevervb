import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/team.dart';
import '../../providers/team_provider.dart';
import 'team_detail_page.dart';

class DiscoverTeamsPage extends ConsumerStatefulWidget {
  const DiscoverTeamsPage({super.key});

  @override
  ConsumerState<DiscoverTeamsPage> createState() => _DiscoverTeamsPageState();
}

class _DiscoverTeamsPageState extends ConsumerState<DiscoverTeamsPage> {
  final _searchController = TextEditingController();
  String? _selectedSport;
  bool _showOnlyPublic = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popularTeamsAsync = ref.watch(popularTeamsProvider());

    return Scaffold(
      body: Column(
        children: [
          // Search and filters
          _SearchFilters(),

          const SizedBox(height: 8),

          // Results
          Expanded(child: _SearchResults()),
        ],
      ),
    );
  }

  Widget _SearchFilters() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Teams',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search teams...',
                hintText: 'Enter team name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // TODO: Implement search debouncing
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // Filters row
            Row(
              children: [
                // Sport filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSport,
                    decoration: const InputDecoration(
                      labelText: 'Sport',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sports),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Sports'),
                      ),
                      ...SportType.values.map((sport) {
                        return DropdownMenuItem(
                          value: sport.name,
                          child: Text(sport.displayName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedSport = value);
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Public/Private filter
                Column(
                  children: [
                    Switch(
                      value: _showOnlyPublic,
                      onChanged: (value) {
                        setState(() => _showOnlyPublic = value);
                      },
                    ),
                    Text(
                      'Public Only',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _SearchResults() {
    // If no search term and no filters, show popular teams
    if (_searchController.text.isEmpty &&
        _selectedSport == null &&
        _showOnlyPublic) {
      return _PopularTeamsSection();
    }

    // Show search results
    return _SearchResultsSection();
  }

  Widget _PopularTeamsSection() {
    final popularTeamsAsync = ref.watch(popularTeamsProvider());

    return popularTeamsAsync.when(
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
                Text(error.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(popularTeamsProvider()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      data: (teams) {
        if (teams.isEmpty) {
          return _EmptyDiscoverView();
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            Text(
              'Popular Teams',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...teams.map((team) => _TeamDiscoveryCard(team: team)),
          ],
        );
      },
    );
  }

  Widget _SearchResultsSection() {
    final searchTeamsAsync = ref.watch(
      searchTeamsProvider(
        teamName:
            _searchController.text.isEmpty ? null : _searchController.text,
        sportType: _selectedSport,
        isPublic: _showOnlyPublic ? true : null,
      ),
    );

    return searchTeamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error searching teams',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(error.toString()),
              ],
            ),
          ),
      data: (teams) {
        if (teams.isEmpty) {
          return _NoResultsView();
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            Text(
              'Search Results (${teams.length})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...teams.map((team) => _TeamDiscoveryCard(team: team)),
          ],
        );
      },
    );
  }

  Widget _EmptyDiscoverView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 96,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Teams to Discover',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a team in your area!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _NoResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 96,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Teams Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search filters or create a new team.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedSport = null;
                  _showOnlyPublic = true;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamDiscoveryCard extends ConsumerWidget {
  final Team team;

  const _TeamDiscoveryCard({required this.team});

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
                  // Join button
                  if (team.isPublic && !team.isFull)
                    ElevatedButton(
                      onPressed: () => _joinTeam(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Join'),
                    )
                  else if (team.isFull)
                    const Chip(
                      label: Text('Full'),
                      backgroundColor: Colors.orange,
                    )
                  else
                    const Chip(
                      label: Text('Private'),
                      backgroundColor: Colors.grey,
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
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: team.isPublic ? Icons.public : Icons.lock,
                    label: team.isPublic ? 'Public' : 'Private',
                  ),
                  const Spacer(),
                  Text(
                    'By ${team.organizerName ?? 'Unknown'}',
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

  Future<void> _joinTeam(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(teamNotifierProvider.notifier);
      final success = await notifier.joinTeam(team.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined ${team.name}!')),
        );
        // Refresh teams lists
        ref.invalidate(userTeamsProvider);
        ref.invalidate(popularTeamsProvider());
      } else if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to join team')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
      case 'cricket':
        return Icons.sports_cricket;
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
