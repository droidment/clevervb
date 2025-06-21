import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/team.dart';
import '../../providers/team_provider.dart';

class CreateTeamPage extends ConsumerStatefulWidget {
  const CreateTeamPage({super.key});

  @override
  ConsumerState<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends ConsumerState<CreateTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMembersController = TextEditingController();

  String _selectedSport = SportType.volleyball.name;
  bool _isPublic = true;
  bool _hasMaxMembers = false;
  bool _onlyOrganizerCreatesGames = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final teamNotifier = ref.read(teamNotifierProvider.notifier);

      final team = await teamNotifier.createTeam(
        name: _nameController.text.trim(),
        sportType: _selectedSport,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        isPublic: _isPublic,
        maxMembers:
            _hasMaxMembers && _maxMembersController.text.isNotEmpty
                ? int.parse(_maxMembersController.text)
                : null,
        onlyOrganizerCreatesGames: _onlyOrganizerCreatesGames,
      );

      if (team != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team "${team.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(team);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create team. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Team'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.group_add, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'Create New Team',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your sports team and start inviting members!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Team Name
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name *',
                        hintText: 'Enter your team name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports_volleyball),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Team name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Team name must be at least 3 characters';
                        }
                        if (value.trim().length > 50) {
                          return 'Team name must be less than 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Tell others about your team...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sport Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sport Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSport,
                      decoration: const InputDecoration(
                        labelText: 'Select Sport *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports),
                      ),
                      items:
                          SportType.values.map((sport) {
                            return DropdownMenuItem(
                              value: sport.name,
                              child: Row(
                                children: [
                                  Icon(_getSportIcon(sport)),
                                  const SizedBox(width: 8),
                                  Text(sport.displayName),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSport = value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a sport';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Team Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Public/Private toggle
                    SwitchListTile(
                      title: const Text('Public Team'),
                      subtitle: Text(
                        _isPublic
                            ? 'Anyone can find and join this team'
                            : 'Invite-only team (members need invitation)',
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() => _isPublic = value);
                      },
                      secondary: Icon(_isPublic ? Icons.public : Icons.lock),
                    ),
                    const Divider(),

                    // Max members toggle
                    SwitchListTile(
                      title: const Text('Set Member Limit'),
                      subtitle: Text(
                        _hasMaxMembers
                            ? 'Limit the number of team members'
                            : 'No limit on team size',
                      ),
                      value: _hasMaxMembers,
                      onChanged: (value) {
                        setState(() => _hasMaxMembers = value);
                      },
                      secondary: const Icon(Icons.people),
                    ),

                    // Max members input
                    if (_hasMaxMembers) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxMembersController,
                        decoration: const InputDecoration(
                          labelText: 'Maximum Members',
                          hintText: 'Enter max number of members',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_hasMaxMembers) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter maximum members';
                            }
                            final number = int.tryParse(value);
                            if (number == null || number < 2) {
                              return 'Must be at least 2 members';
                            }
                            if (number > 100) {
                              return 'Cannot exceed 100 members';
                            }
                          }
                          return null;
                        },
                      ),
                    ],

                    // Only organizer schedule toggle
                    SwitchListTile(
                      title: const Text('Only organizer can schedule games'),
                      subtitle: const Text(
                        'Members will not be able to create games',
                      ),
                      value: _onlyOrganizerCreatesGames,
                      onChanged: (value) {
                        setState(() => _onlyOrganizerCreatesGames = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_add),
                            SizedBox(width: 8),
                            Text('Create Team'),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 16),

            // Helper text
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Text(
                          'What happens next?',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• You\'ll be the team organizer'),
                    const Text('• Start inviting members to join'),
                    const Text('• Schedule games and manage team activities'),
                    const Text('• Track team statistics and performance'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSportIcon(SportType sport) {
    switch (sport) {
      case SportType.volleyball:
        return Icons.sports_volleyball;
      case SportType.basketball:
        return Icons.sports_basketball;
      case SportType.tennis:
        return Icons.sports_tennis;
      case SportType.soccer:
        return Icons.sports_soccer;
      case SportType.pickleball:
        return Icons.sports_tennis; // Close enough
      case SportType.badminton:
        return Icons.sports_tennis; // Close enough
      case SportType.cricket:
        return Icons.sports_cricket;
    }
  }
}
