import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/game.dart';
import '../../../models/attendance.dart';
import '../../../services/attendance_service.dart';
import '../game_attendance_detail_page.dart';

class GameAttendanceList extends StatelessWidget {
  final List<Game> games;
  final Map<String, List<Attendance>> gameAttendances;
  final Map<String, List<Fee>> gameFees;
  final VoidCallback onRefresh;

  const GameAttendanceList({
    super.key,
    required this.games,
    required this.gameAttendances,
    required this.gameFees,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child:
          games.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event, size: 64, color: Colors.grey),
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
                      'Games you organize will appear here.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final attendances = gameAttendances[game.id] ?? [];
                  final fees = gameFees[game.id] ?? [];
                  return _buildGameAttendanceCard(
                    context,
                    game,
                    attendances,
                    fees,
                  );
                },
              ),
    );
  }

  void _navigateToDetailPage(
    BuildContext context,
    Game game,
    List<Attendance> attendances,
    List<Fee> fees,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GameAttendanceDetailPage(
              game: game,
              attendances: attendances,
              fees: fees,
            ),
      ),
    ).then((_) => onRefresh()); // Refresh data when returning from detail page
  }

  Widget _buildGameAttendanceCard(
    BuildContext context,
    Game game,
    List<Attendance> attendances,
    List<Fee> fees,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetailPage(context, game, attendances, fees),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor:
                game.hasEnded ? Colors.grey[300] : theme.primaryColor,
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateFormat.format(game.scheduledAt)} at ${timeFormat.format(game.scheduledAt)}',
                style: TextStyle(
                  color: game.hasEnded ? Colors.grey[500] : null,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${attendances.length} attended',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    ' / ${game.maxPlayers} capacity',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (fees.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${fees.length} fees',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          children: [
            if (attendances.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No attendances recorded',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...attendances.map(
                (attendance) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text(
                      attendance.userName?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(attendance.userName ?? 'Unknown'),
                  subtitle: Text(
                    'Checked in: ${DateFormat('h:mm a').format(attendance.checkedInAt)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attendance.statusEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (attendance.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
