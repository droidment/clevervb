import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../models/game.dart';
import '../models/attendance.dart';

class GameCheckinWidget extends ConsumerStatefulWidget {
  final Game game;
  final VoidCallback? onCheckinChanged;

  const GameCheckinWidget({
    super.key,
    required this.game,
    this.onCheckinChanged,
  });

  @override
  ConsumerState<GameCheckinWidget> createState() => _GameCheckinWidgetState();
}

class _GameCheckinWidgetState extends ConsumerState<GameCheckinWidget> {
  final _attendanceService = AttendanceService();
  final _authService = AuthService();
  Attendance? _currentAttendance;
  bool _isLoading = false;
  List<Attendance> _gameAttendances = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user ID first
      final currentUserId = await _authService.getCurrentUserId();

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Load user's attendance for this game
      final userAttendance = await _attendanceService.getUserAttendance(
        widget.game.id,
        currentUserId,
      );

      // Load all attendances for this game
      final gameAttendances = await _attendanceService.getGameAttendances(
        widget.game.id,
      );

      setState(() {
        _currentAttendance = userAttendance;
        _gameAttendances = gameAttendances;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkin() async {
    setState(() => _isLoading = true);

    try {
      final attendance = await _attendanceService.checkIn(widget.game.id);

      setState(() => _currentAttendance = attendance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Checked in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onCheckinChanged?.call();
      await _loadAttendanceData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkout() async {
    setState(() => _isLoading = true);

    try {
      final attendance = await _attendanceService.checkOut(widget.game.id);

      setState(() => _currentAttendance = attendance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Checked out successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onCheckinChanged?.call();
      await _loadAttendanceData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCheckinButton() {
    if (_currentAttendance == null) {
      return ElevatedButton.icon(
        onPressed: widget.game.canCheckIn && !_isLoading ? _checkin : null,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.login),
        label: Text(_isLoading ? 'Checking in...' : 'Check In'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }

    if (_currentAttendance!.isActive) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checked In',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Since ${_formatTime(_currentAttendance!.checkedInAt)}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Duration: ${_currentAttendance!.durationDisplay}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: !_isLoading ? _checkout : null,
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.logout),
            label: Text(_isLoading ? 'Checking out...' : 'Check Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attended',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Checked out at ${_formatTime(_currentAttendance!.checkedOutAt!)}',
                  style: TextStyle(color: Colors.blue[600], fontSize: 12),
                ),
                Text(
                  'Duration: ${_currentAttendance!.durationDisplay}',
                  style: TextStyle(color: Colors.blue[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_gameAttendances.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Attendance (${_gameAttendances.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._gameAttendances
                .take(5)
                .map((attendance) => _buildAttendanceItem(attendance)),
            if (_gameAttendances.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'and ${_gameAttendances.length - 5} more...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(Attendance attendance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              attendance.userName?.substring(0, 1).toUpperCase() ?? '?',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.userName ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  attendance.isActive
                      ? 'Checked in at ${_formatTime(attendance.checkedInAt)}'
                      : 'Attended (${attendance.durationDisplay})',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(attendance.statusEmoji, style: const TextStyle(fontSize: 16)),
          if (attendance.isActive) ...[
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    final now = DateTime.now();
    final gameStarted = now.isAfter(widget.game.scheduledAt);
    final gameEnded = now.isAfter(
      widget.game.scheduledAt.add(const Duration(hours: 2)),
    );

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!gameStarted) {
      statusColor = Colors.orange;
      statusText = 'Starting soon';
      statusIcon = Icons.schedule;
    } else if (gameStarted && !gameEnded) {
      statusColor = Colors.green;
      statusText = 'In progress';
      statusIcon = Icons.play_circle;
    } else {
      statusColor = Colors.grey;
      statusText = 'Ended';
      statusIcon = Icons.stop_circle;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.game.feePerPlayer != null &&
                    widget.game.feePerPlayer! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '\$${widget.game.feePerPlayer!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.game.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.game.venue,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(widget.game.scheduledAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGameInfo(),
        const SizedBox(height: 16),
        _buildCheckinButton(),
        const SizedBox(height: 16),
        _buildAttendanceList(),
      ],
    );
  }
}
 