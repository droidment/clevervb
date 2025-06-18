import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import '../providers/game_provider.dart';

class GameDetailsModal extends ConsumerStatefulWidget {
  final Game game;

  const GameDetailsModal({super.key, required this.game});

  @override
  ConsumerState<GameDetailsModal> createState() => _GameDetailsModalState();
}

class _GameDetailsModalState extends ConsumerState<GameDetailsModal> {
  final _gameService = GameService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _rsvpList = [];
  bool _loadingRsvps = true;

  @override
  void initState() {
    super.initState();
    _loadGameRsvps();
  }

  Future<void> _loadGameRsvps() async {
    try {
      setState(() => _loadingRsvps = true);
      final rsvps = await _gameService.getGameRsvps(widget.game.id);
      setState(() {
        _rsvpList = rsvps;
        _loadingRsvps = false;
      });
    } catch (e) {
      setState(() => _loadingRsvps = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load participants: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _updateRsvp(RsvpResponse response) async {
    setState(() => _isLoading = true);

    try {
      await _gameService.rsvpToGame(widget.game.id, response);

      // Refresh providers and RSVP list
      ref.invalidate(upcomingUserRsvpedGamesProvider);
      ref.invalidate(userRsvpedGamesProvider);
      await _loadGameRsvps(); // Reload the participants list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RSVP ${response.display} submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit RSVP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRsvp() async {
    final now = DateTime.now();
    final gameDateTime = widget.game.scheduledAt;
    final hoursUntilGame = gameDateTime.difference(now).inHours;

    if (hoursUntilGame < 12 && hoursUntilGame > 0) {
      final confirmed = await _showCancelWarningDialog();
      if (!confirmed) return;
    }

    setState(() => _isLoading = true);

    try {
      await _gameService.removeRsvp(widget.game.id);

      // Refresh providers and RSVP list
      ref.invalidate(upcomingUserRsvpedGamesProvider);
      ref.invalidate(userRsvpedGamesProvider);
      await _loadGameRsvps(); // Reload the participants list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('RSVP cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel RSVP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showCancelWarningDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                icon: const Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 32,
                ),
                title: const Text('Cancel RSVP?'),
                content: const Text(
                  'This game is less than 12 hours away. Cancelling now may inconvenience other players and the organizer.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keep RSVP'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    child: const Text('Cancel Anyway'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isGameFinished = widget.game.hasEnded;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isGameFinished ? Colors.grey[600] : theme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isGameFinished
                        ? Icons.check_circle
                        : Icons.sports_volleyball,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGameFinished
                              ? 'GAME COMPLETED'
                              : widget.game.sport.toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.game.teamName != null)
                          Text(
                            widget.game.teamName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    _buildInfoSection(
                      icon: Icons.event,
                      title: 'Game Title',
                      content: Text(
                        widget.game.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date & Time
                    _buildInfoSection(
                      icon: Icons.schedule,
                      title: 'Date & Time',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(widget.game.scheduledAt),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            timeFormat.format(widget.game.scheduledAt),
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (isGameFinished)
                            Text(
                              'Completed ${_getTimeSinceGame()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Location
                    _buildInfoSection(
                      icon: Icons.location_on,
                      title: 'Location',
                      content: Text(
                        widget.game.locationDisplay,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Game Info
                    _buildInfoSection(
                      icon: Icons.info,
                      title: 'Game Details',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Players: ${widget.game.rsvpCount ?? 0}/${widget.game.maxPlayers}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${widget.game.durationMinutes} minutes',
                          ),
                          const SizedBox(height: 4),
                          Text('Fee: ${widget.game.feeDisplay}'),
                          if (widget.game.equipmentNeeded.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Equipment: ${widget.game.equipmentNeeded.join(', ')}',
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Description
                    if (widget.game.description != null &&
                        widget.game.description!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        icon: Icons.description,
                        title: 'Description',
                        content: Text(
                          widget.game.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Participants Section
                    _buildParticipantsSection(),

                    // Check-in info
                    if (widget.game.canCheckIn) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        icon: Icons.check_circle,
                        title: 'Check-in Available',
                        content: Text(
                          'You can check in for this game now!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons (only show if game hasn't finished)
            if (!isGameFinished)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: _buildActionButtons(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final theme = Theme.of(context);

    return _buildInfoSection(
      icon: Icons.people,
      title: 'Participants (${_rsvpList.length})',
      content:
          _loadingRsvps
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
              : _rsvpList.isEmpty
              ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'No one has signed up yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
              : Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _rsvpList.length,
                  separatorBuilder:
                      (context, index) =>
                          Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final rsvp = _rsvpList[index];
                    final user = rsvp['st_users'];
                    final response = rsvp['response'] as String;
                    final guestCount = rsvp['guest_count'] as int? ?? 0;
                    final createdAt = DateTime.parse(rsvp['created_at']);

                    return _buildParticipantTile(
                      user: user,
                      response: response,
                      guestCount: guestCount,
                      signUpTime: createdAt,
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildParticipantTile({
    required Map<String, dynamic> user,
    required String response,
    required int guestCount,
    required DateTime signUpTime,
  }) {
    final theme = Theme.of(context);
    final userName = user['full_name'] as String? ?? 'Unknown User';
    final userEmail = user['email'] as String? ?? '';

    Color responseColor;
    IconData responseIcon;
    String responseText;

    switch (response) {
      case 'yes':
        responseColor = Colors.green;
        responseIcon = Icons.check_circle;
        responseText = 'Going';
        break;
      case 'no':
        responseColor = Colors.red;
        responseIcon = Icons.cancel;
        responseText = 'Not Going';
        break;
      case 'maybe':
        responseColor = Colors.orange;
        responseIcon = Icons.help;
        responseText = 'Maybe';
        break;
      default:
        responseColor = Colors.grey;
        responseIcon = Icons.help_outline;
        responseText = response;
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage:
                user['avatar_url'] != null
                    ? NetworkImage(user['avatar_url'])
                    : null,
            child:
                user['avatar_url'] == null
                    ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (userEmail.isNotEmpty)
                  Text(
                    userEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                if (guestCount > 0)
                  Text(
                    '+$guestCount guest${guestCount > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // RSVP Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: responseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: responseColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(responseIcon, size: 14, color: responseColor),
                const SizedBox(width: 4),
                Text(
                  responseText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: responseColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeSinceGame() {
    final now = DateTime.now();
    final gameEnd = widget.game.endTime;
    final timeSince = now.difference(gameEnd);

    if (timeSince.inDays > 0) {
      return '${timeSince.inDays} day${timeSince.inDays == 1 ? '' : 's'} ago';
    } else if (timeSince.inHours > 0) {
      return '${timeSince.inHours} hour${timeSince.inHours == 1 ? '' : 's'} ago';
    } else if (timeSince.inMinutes > 0) {
      return '${timeSince.inMinutes} minute${timeSince.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'just now';
    }
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              content,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);

    return Column(
      children: [
        // Main RSVP Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Will you be joining this game?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Primary RSVP Buttons - Made bigger
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56, // Bigger button height
                      child: OutlinedButton.icon(
                        onPressed: () => _updateRsvp(RsvpResponse.no),
                        icon: const Icon(Icons.cancel, size: 20),
                        label: const Text(
                          'Can\'t Go',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2, // Make "I'm Going" button bigger
                    child: SizedBox(
                      height: 56, // Bigger button height
                      child: ElevatedButton.icon(
                        onPressed:
                            widget.game.isFull
                                ? null
                                : () => _updateRsvp(RsvpResponse.yes),
                        icon: Icon(
                          widget.game.isFull ? Icons.block : Icons.check_circle,
                          size: 24,
                        ),
                        label: Text(
                          widget.game.isFull ? 'Game Full' : 'I\'m Going!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              widget.game.isFull ? Colors.grey : Colors.green,
                          foregroundColor: Colors.white,
                          elevation: widget.game.isFull ? 0 : 3,
                          shadowColor: Colors.green.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Maybe Button - Secondary option
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _updateRsvp(RsvpResponse.maybe),
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text(
                    'Maybe / Not Sure',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cancel RSVP button - Less prominent
        SizedBox(
          height: 44,
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _cancelRsvp,
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Cancel My RSVP', style: TextStyle(fontSize: 14)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
