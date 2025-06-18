import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/game.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';
import '../../services/game_service.dart';

class GameAttendanceDetailPage extends ConsumerStatefulWidget {
  final Game game;
  final List<Attendance> attendances;
  final List<Fee> fees;

  const GameAttendanceDetailPage({
    super.key,
    required this.game,
    required this.attendances,
    required this.fees,
  });

  @override
  ConsumerState<GameAttendanceDetailPage> createState() =>
      _GameAttendanceDetailPageState();
}

class _GameAttendanceDetailPageState
    extends ConsumerState<GameAttendanceDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AttendanceService _attendanceService = AttendanceService();
  final GameService _gameService = GameService();

  List<Attendance> _attendances = [];
  List<Fee> _fees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _attendances = List.from(widget.attendances);
    _fees = List.from(widget.fees);

    // Debug logging
    print('🔍 GameAttendanceDetailPage initialized');
    print('📊 Game: ${widget.game.title}');
    print('👥 Attendances: ${_attendances.length}');
    print('💰 Fees: ${_fees.length}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch fresh attendance and fee data
      final freshAttendances = await _attendanceService.getGameAttendances(
        widget.game.id,
      );
      final freshFees = await _attendanceService.getGameFees(widget.game.id);

      setState(() {
        _attendances = freshAttendances;
        _fees = freshFees;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFeeAction(Fee fee, String action) async {
    try {
      switch (action) {
        case 'mark_paid':
          await _attendanceService.markFeePaid(fee.id);
          break;
        case 'waive':
          await _attendanceService.waiveFee(fee.id, 'Waived by organizer');
          break;
        case 'delete':
          // Delete functionality would need to be implemented
          throw UnimplementedError('Delete fee not implemented yet');
      }

      await _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fee $action completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteGame() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Game'),
            content: Text(
              'Are you sure you want to delete "${widget.game.title}"?\n\n'
              '⚠️ WARNING: This will permanently delete:\n'
              '• All attendance records and check-ins\n'
              '• All fee records and payment history\n'
              '• All RSVPs and responses\n\n'
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
      setState(() => _isLoading = true);

      await _gameService.deleteGame(widget.game.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to organizer dashboard
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Attendance', icon: Icon(Icons.people)),
            Tab(text: 'Fees', icon: Icon(Icons.attach_money)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteGame();
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
                          'Delete Game',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildAttendanceTab(), _buildFeesTab()],
              ),
    );
  }

  Widget _buildAttendanceTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildAttendanceSummary(),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final attendance = _attendances[index];
            return _buildAttendanceCard(attendance);
          }, childCount: _attendances.length),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary() {
    final totalAttended = _attendances.length;
    final maxPlayers = widget.game.maxPlayers ?? 0;
    final attendanceRate =
        maxPlayers > 0 ? (totalAttended / maxPlayers * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Game Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Attended',
                  '$totalAttended',
                  Icons.people,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Max Players',
                  '$maxPlayers',
                  Icons.group,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Rate',
                  '${attendanceRate.toStringAsFixed(1)}%',
                  Icons.analytics,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAttendanceCard(Attendance attendance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.check, color: Colors.green[700]),
        ),
        title: Text(attendance.userName ?? 'Unknown User'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checked in: ${DateFormat('MMM d, h:mm a').format(attendance.checkedInAt)}',
            ),
            if (attendance.durationMinutes != null)
              Text(
                'Duration: ${attendance.durationMinutes} minutes',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attendance.gameFee != null && attendance.gameFee! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${attendance.gameFee!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.verified, color: Colors.green[600], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeesTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFeesSummary(),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final fee = _fees[index];
            return _buildFeeCard(fee);
          }, childCount: _fees.length),
        ),
      ],
    );
  }

  Widget _buildFeesSummary() {
    final totalFees = _fees.fold<double>(0, (sum, fee) => sum + fee.amount);
    final paidFees = _fees
        .where((fee) => fee.status == 'paid')
        .fold<double>(0, (sum, fee) => sum + fee.amount);
    final pendingFees = _fees
        .where((fee) => fee.status == 'pending')
        .fold<double>(0, (sum, fee) => sum + fee.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fee Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total',
                  '\$${totalFees.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Paid',
                  '\$${paidFees.toStringAsFixed(2)}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Pending',
                  '\$${pendingFees.toStringAsFixed(2)}',
                  Icons.pending,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeCard(Fee fee) {
    Color statusColor;
    IconData statusIcon;

    switch (fee.status) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'waived':
        statusColor = Colors.blue;
        statusIcon = Icons.block;
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(fee.userName ?? 'Unknown User'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fee.description ?? 'Game fee'),
            if (fee.dueDate != null)
              Text(
                'Due: ${DateFormat('MMM d, yyyy').format(fee.dueDate!)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${fee.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (action) => _handleFeeAction(fee, action),
              itemBuilder:
                  (context) => [
                    if (fee.status != 'paid')
                      const PopupMenuItem(
                        value: 'mark_paid',
                        child: Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Mark Paid'),
                          ],
                        ),
                      ),
                    if (fee.status != 'waived')
                      const PopupMenuItem(
                        value: 'waive',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Waive Fee'),
                          ],
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
