import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import '../providers/game_provider.dart';
import '../services/auth_service.dart';

class GameDetailPage extends ConsumerStatefulWidget {
  final Game game;

  const GameDetailPage({super.key, required this.game});

  @override
  ConsumerState<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends ConsumerState<GameDetailPage> {
  final _gameService = GameService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _rsvpList = [];
  bool _loadingRsvps = true;

  // Tracks whether the current user already RSVP'd "Going"
  bool _hasRsvpedYes = false;

  // Tracks whether the current user has any RSVP (yes/no/maybe)
  bool _hasUserRsvp = false;

  @override
  void initState() {
    super.initState();
    _loadGameRsvps();
  }

  Future<void> _loadGameRsvps() async {
    try {
      setState(() => _loadingRsvps = true);
      final rsvps = await _gameService.getGameRsvps(widget.game.id);

      // Determine if the current user has already RSVP'd "yes"
      final authService = AuthService();
      final currentUserId = await authService.getCurrentUserId();

      setState(() {
        _rsvpList = rsvps;
        _loadingRsvps = false;
        _hasRsvpedYes = rsvps.any(
          (rsvp) =>
              rsvp['user_id'] == currentUserId && rsvp['response'] == 'yes',
        );
        _hasUserRsvp = rsvps.any((rsvp) => rsvp['user_id'] == currentUserId);
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
            duration: const Duration(seconds: 2),
          ),
        );
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
            duration: Duration(seconds: 2),
          ),
        );
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Game Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor:
                isGameFinished ? Colors.grey[600] : theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isGameFinished ? Colors.grey[800]! : theme.primaryColor,
                      isGameFinished
                          ? Colors.grey[600]!
                          : theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 90, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isGameFinished
                                ? Icons.check_circle
                                : _getSportIcon(widget.game.sport),
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Game title (primary)
                                Text(
                                  widget.game.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Sport or status label
                                Text(
                                  isGameFinished
                                      ? 'GAME COMPLETED'
                                      : widget.game.sport.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.game.teamName != null)
                                  Text(
                                    widget.game.teamName!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
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
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Participants section (visible first)
                  _buildParticipantsCard(theme),

                  const SizedBox(height: 16),

                  // Collapsible game details to save space
                  _buildCollapsibleDetails(
                    theme,
                    dateFormat,
                    timeFormat,
                    isGameFinished,
                  ),

                  // Check-in info
                  if (widget.game.canCheckIn) ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.check_circle,
                      title: 'Check-in Available',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can check in for this game now!',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Bottom padding for floating action buttons
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Buttons (only show if game hasn't finished)
      bottomNavigationBar:
          !isGameFinished
              ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildActionButtons(),
              )
              : null,
    );
  }

  Widget _buildCombinedGameInfoCard(
    ThemeData theme,
    DateFormat dateFormat,
    DateFormat timeFormat,
    bool isGameFinished,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sport icon
            Row(
              children: [
                Icon(
                  isGameFinished
                      ? Icons.check_circle
                      : _getSportIcon(widget.game.sport),
                  color: theme.primaryColor,
                  size: 28,
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.game.teamName != null)
                        Text(
                          widget.game.teamName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Date & Time Section
            _buildInfoSection(
              icon: Icons.schedule,
              title: 'Date & Time',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(widget.game.scheduledAt),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeFormat.format(widget.game.scheduledAt),
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (isGameFinished) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Completed ${_getTimeSinceGame()}',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 32),

            // Location Section
            _buildInfoSection(
              icon: Icons.location_on,
              title: 'Location',
              child: Text(
                widget.game.locationDisplay,
                style: theme.textTheme.bodyLarge,
              ),
            ),

            const Divider(height: 32),

            // Game Details Section
            _buildInfoSection(
              icon: Icons.info,
              title: 'Game Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Players',
                    '${widget.game.rsvpCount ?? 0}/${widget.game.maxPlayers}',
                    icon: Icons.people,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Duration',
                    '${widget.game.durationMinutes} minutes',
                    icon: Icons.timer,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Fee',
                    widget.game.feeDisplay,
                    icon: Icons.attach_money,
                  ),
                  if (widget.game.equipmentNeeded.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Equipment',
                      widget.game.equipmentNeeded.join(', '),
                      icon: Icons.sports,
                    ),
                  ],
                ],
              ),
            ),

            // Description Section (if available)
            if (widget.game.description != null &&
                widget.game.description!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildInfoSection(
                icon: Icons.description,
                title: 'Description',
                child: Text(
                  widget.game.description!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.only(left: 28), child: child),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required IconData icon}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsCard(ThemeData theme) {
    if (_loadingRsvps) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants (${_rsvpList.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _rsvpList.map((rsvp) {
                    final name =
                        rsvp['st_users']?['full_name'] ??
                        rsvp['st_users']?['email'] ??
                        'Player';
                    return Chip(
                      label: Text(name, overflow: TextOverflow.ellipsis),
                      avatar: const Icon(Icons.person, size: 18),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleDetails(
    ThemeData theme,
    DateFormat dateFormat,
    DateFormat timeFormat,
    bool isGameFinished,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: const Text('Game Details'),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildCombinedGameInfoCard(
              theme,
              dateFormat,
              timeFormat,
              isGameFinished,
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

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'pickleball':
        return Icons.sports_tennis;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'badminton':
        return Icons.sports_tennis;
      case 'soccer':
        return Icons.sports_soccer;
      default:
        return Icons.sports;
    }
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Show only Cancel RSVP if user already RSVP'd yes OR RSVP window closed
    if (_hasRsvpedYes || (!widget.game.isRsvpOpen && _hasUserRsvp)) {
      return SizedBox(
        height: 56,
        child: TextButton.icon(
          onPressed: _cancelRsvp,
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text(
            'Cancel RSVP',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // If RSVP is closed and user has no RSVP, hide action buttons entirely
    if (!widget.game.isRsvpOpen && !_hasUserRsvp) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary RSVP Buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _updateRsvp(RsvpResponse.no),
                  icon: const Icon(Icons.cancel, size: 20),
                  label: const Text(
                    'Can\'t Go',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      (widget.game.isFull || _hasRsvpedYes)
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

        // Secondary buttons row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _updateRsvp(RsvpResponse.maybe),
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text(
                    'Maybe',
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextButton.icon(
                  onPressed: _cancelRsvp,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text(
                    'Cancel RSVP',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
