import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/game.dart';
import '../../models/attendance.dart';
import '../../services/game_service.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import 'widgets/attendance_overview_card.dart';
import 'widgets/fee_summary_card.dart';
import 'widgets/game_attendance_list.dart';
import 'game_attendance_detail_page.dart';

class OrganizerDashboardPage extends ConsumerStatefulWidget {
  const OrganizerDashboardPage({super.key});

  @override
  ConsumerState<OrganizerDashboardPage> createState() =>
      _OrganizerDashboardPageState();
}

class _OrganizerDashboardPageState extends ConsumerState<OrganizerDashboardPage>
    with SingleTickerProviderStateMixin {
  final _gameService = GameService();
  final _attendanceService = AttendanceService();
  final _authService = AuthService();

  late TabController _tabController;

  List<Game> _organizerGames = [];
  Map<String, List<Attendance>> _gameAttendances = {};
  Map<String, List<Fee>> _gameFees = {};
  Map<String, dynamic> _summaryStats = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrganizerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizerData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Load games organized by current user
      final games = await _gameService.getOrganizerGames(currentUserId);

      // Load attendance and fee data for each game
      final Map<String, List<Attendance>> attendances = {};
      final Map<String, List<Fee>> fees = {};

      for (final game in games) {
        try {
          attendances[game.id] = await _attendanceService.getGameAttendances(
            game.id,
          );
          fees[game.id] = await _attendanceService.getGameFees(game.id);
        } catch (e) {
          // Continue loading other games even if one fails
          attendances[game.id] = [];
          fees[game.id] = [];
        }
      }

      // Calculate summary statistics
      final summaryStats = _calculateSummaryStats(games, attendances, fees);

      setState(() {
        _organizerGames = games;
        _gameAttendances = attendances;
        _gameFees = fees;
        _summaryStats = summaryStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateSummaryStats(
    List<Game> games,
    Map<String, List<Attendance>> attendances,
    Map<String, List<Fee>> fees,
  ) {
    int totalGames = games.length;
    int totalAttendances = attendances.values.fold(
      0,
      (sum, list) => sum + list.length,
    );
    double totalFeesOwed = 0;
    double totalFeesPaid = 0;
    int overdueFeesCount = 0;

    for (final gameId in fees.keys) {
      for (final fee in fees[gameId]!) {
        switch (fee.status) {
          case 'pending':
            totalFeesOwed += fee.amount;
            if (fee.isOverdue) overdueFeesCount++;
            break;
          case 'paid':
            totalFeesPaid += fee.amount;
            break;
        }
      }
    }

    double averageAttendance =
        totalGames > 0 ? totalAttendances / totalGames : 0;

    return {
      'totalGames': totalGames,
      'totalAttendances': totalAttendances,
      'averageAttendance': averageAttendance,
      'totalFeesOwed': totalFeesOwed,
      'totalFeesPaid': totalFeesPaid,
      'overdueFeesCount': overdueFeesCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Attendance'),
            Tab(icon: Icon(Icons.attach_money), text: 'Fees'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState()
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAttendanceTab(),
                  _buildFeesTab(),
                ],
              ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load organizer data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrganizerData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadOrganizerData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: AttendanceOverviewCard(
                    title: 'Total Games',
                    value: _summaryStats['totalGames']?.toString() ?? '0',
                    icon: Icons.sports_soccer,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AttendanceOverviewCard(
                    title: 'Total Attendances',
                    value: _summaryStats['totalAttendances']?.toString() ?? '0',
                    icon: Icons.people,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AttendanceOverviewCard(
                    title: 'Avg Attendance',
                    value:
                        '${(_summaryStats['averageAttendance'] ?? 0).toStringAsFixed(1)}',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FeeSummaryCard(
                    title: 'Outstanding Fees',
                    amount: _summaryStats['totalFeesOwed'] ?? 0,
                    overdueCount: _summaryStats['overdueFeesCount'] ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Games List
            Text(
              'Recent Games',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_organizerGames.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No games found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Create your first game to start tracking attendance and fees.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._organizerGames
                  .take(5)
                  .map((game) => _buildGameOverviewCard(game)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return GameAttendanceList(
      games: _organizerGames,
      gameAttendances: _gameAttendances,
      gameFees: _gameFees,
      onRefresh: _loadOrganizerData,
    );
  }

  Widget _buildFeesTab() {
    return RefreshIndicator(
      onRefresh: _loadOrganizerData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fee Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fee Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Outstanding:'),
                        Text(
                          '\$${(_summaryStats['totalFeesOwed'] ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Collected:'),
                        Text(
                          '\$${(_summaryStats['totalFeesPaid'] ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if ((_summaryStats['overdueFeesCount'] ?? 0) > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Overdue:'),
                          Text(
                            '${_summaryStats['overdueFeesCount']} fees',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Outstanding Fees by Game
            Text(
              'Outstanding Fees by Game',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ..._organizerGames.map((game) => _buildGameFeesCard(game)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverviewCard(Game game) {
    final attendances = _gameAttendances[game.id] ?? [];
    final fees = _gameFees[game.id] ?? [];
    final outstandingFees = fees.where((f) => f.status == 'pending').length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              game.hasEnded ? Colors.grey[300] : Theme.of(context).primaryColor,
          child: Icon(
            Icons.sports_soccer,
            color: game.hasEnded ? Colors.grey[600] : Colors.white,
          ),
        ),
        title: Text(
          game.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: game.hasEnded ? Colors.grey[600] : null,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy • h:mm a').format(game.scheduledAt),
          style: TextStyle(color: game.hasEnded ? Colors.grey[500] : null),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${attendances.length} attended',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (outstandingFees > 0)
                  Text(
                    '$outstandingFees fees due',
                    style: const TextStyle(color: Colors.orange, fontSize: 11),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteGame(game);
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
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
        onTap: () async {
          // Navigate to detailed game attendance/fee view
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => GameAttendanceDetailPage(
                    game: game,
                    attendances: attendances,
                    fees: fees,
                  ),
            ),
          );

          // Refresh data if game was deleted
          if (result == true) {
            await _loadOrganizerData();
          }
        },
      ),
    );
  }

  Widget _buildGameFeesCard(Game game) {
    final fees = _gameFees[game.id] ?? [];
    final outstandingFees = fees.where((f) => f.status == 'pending').toList();

    if (outstandingFees.isEmpty) return const SizedBox.shrink();

    final totalOwed = outstandingFees.fold(0.0, (sum, fee) => sum + fee.amount);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(game.title),
        subtitle: Text(
          '\$${totalOwed.toStringAsFixed(2)} outstanding from ${outstandingFees.length} players',
        ),
        children:
            outstandingFees
                .map(
                  (fee) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text(
                        fee.userName?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(fee.userName ?? 'Unknown'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${fee.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (action) => _handleFeeAction(action, fee),
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'mark_paid',
                                  child: Text('Mark as Paid'),
                                ),
                                const PopupMenuItem(
                                  value: 'waive',
                                  child: Text('Waive Fee'),
                                ),
                              ],
                          child: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Future<void> _handleFeeAction(String action, Fee fee) async {
    try {
      switch (action) {
        case 'mark_paid':
          await _attendanceService.markFeePaid(fee.id);
          break;
        case 'waive':
          await _attendanceService.waiveFee(fee.id, 'Waived by organizer');
          break;
      }

      // Refresh data
      await _loadOrganizerData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'mark_paid' ? 'Fee marked as paid' : 'Fee waived',
            ),
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

  Future<void> _deleteGame(Game game) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Game'),
            content: Text(
              'Are you sure you want to delete "${game.title}"?\n\n'
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
      await _gameService.deleteGame(game.id);
      await _loadOrganizerData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }
}
