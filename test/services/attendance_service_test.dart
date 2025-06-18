import 'package:flutter_test/flutter_test.dart';
import 'package:clevervb/models/attendance.dart';
import 'package:clevervb/models/game.dart';

void main() {
  group('Attendance Service Fee Aggregation Logic', () {
    group('Fee Summary Calculations', () {
      test('calculates user fee summary correctly', () {
        // Mock fee data - this represents what would come from the database
        final mockFees = [
          {
            'id': 'fee1',
            'user_id': 'user1',
            'amount': 15.0,
            'status': 'pending',
            'due_date':
                DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'fee2',
            'user_id': 'user1',
            'amount': 20.0,
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'fee3',
            'user_id': 'user1',
            'amount': 10.0,
            'status': 'waived',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'fee4',
            'user_id': 'user1',
            'amount': 25.0,
            'status': 'pending',
            'due_date':
                DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        ];

        // Calculate expected values
        const expectedTotalOwed = 15.0 + 25.0; // pending fees
        const expectedTotalPaid = 20.0; // paid fees
        const expectedTotalWaived = 10.0; // waived fees
        const expectedOverdueCount = 1; // only fee1 is overdue
        const expectedTotalFees = 4;

        // Test the calculation logic
        final summary = _calculateFeeSummary(mockFees);

        expect(summary['total_owed'], expectedTotalOwed);
        expect(summary['total_paid'], expectedTotalPaid);
        expect(summary['total_waived'], expectedTotalWaived);
        expect(summary['overdue_count'], expectedOverdueCount);
        expect(summary['total_fees'], expectedTotalFees);
      });

      test('handles empty fee list correctly', () {
        final summary = _calculateFeeSummary([]);

        expect(summary['total_owed'], 0.0);
        expect(summary['total_paid'], 0.0);
        expect(summary['total_waived'], 0.0);
        expect(summary['overdue_count'], 0);
        expect(summary['total_fees'], 0);
      });

      test('handles fees without due dates correctly', () {
        final mockFees = [
          {
            'id': 'fee1',
            'user_id': 'user1',
            'amount': 15.0,
            'status': 'pending',
            'due_date': null, // No due date
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        ];

        final summary = _calculateFeeSummary(mockFees);

        expect(summary['total_owed'], 15.0);
        expect(summary['overdue_count'], 0); // No due date = not overdue
      });

      test('calculates team attendance statistics correctly', () {
        final mockAttendances = [
          {'game_id': 'game1', 'user_id': 'user1'},
          {'game_id': 'game1', 'user_id': 'user2'},
          {'game_id': 'game2', 'user_id': 'user1'},
          {'game_id': 'game2', 'user_id': 'user2'},
          {'game_id': 'game2', 'user_id': 'user3'},
        ];

        const totalGames = 2;
        final totalAttendances = mockAttendances.length;
        final averageAttendance = totalAttendances / totalGames;

        final stats = _calculateAttendanceStats(mockAttendances, totalGames);

        expect(stats['total_games'], totalGames);
        expect(stats['total_attendances'], totalAttendances);
        expect(stats['average_attendance'], averageAttendance);
      });
    });

    group('Fee Status Validation', () {
      test('validates pending fee status correctly', () {
        final fee = _createMockFee(
          status: 'pending',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(fee.status, 'pending');
        expect(fee.isOverdue, true);
        expect(fee.isPaid, false);
        expect(fee.isWaived, false);
      });

      test('validates paid fee status correctly', () {
        final fee = _createMockFee(status: 'paid', paidAt: DateTime.now());

        expect(fee.status, 'paid');
        expect(fee.isPaid, true);
        expect(fee.isOverdue, false);
        expect(fee.isWaived, false);
      });

      test('validates waived fee status correctly', () {
        final fee = _createMockFee(status: 'waived');

        expect(fee.status, 'waived');
        expect(fee.isWaived, true);
        expect(fee.isPaid, false);
        expect(fee.isOverdue, false);
      });
    });

    group('Fee Calculation Edge Cases', () {
      test('handles zero amount fees', () {
        final mockFees = [
          {
            'id': 'fee1',
            'user_id': 'user1',
            'amount': 0.0,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        ];

        final summary = _calculateFeeSummary(mockFees);
        expect(summary['total_owed'], 0.0);
      });

      test('handles negative amount fees (refunds)', () {
        final mockFees = [
          {
            'id': 'fee1',
            'user_id': 'user1',
            'amount': -10.0,
            'status': 'paid',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        ];

        final summary = _calculateFeeSummary(mockFees);
        expect(summary['total_paid'], -10.0);
      });

      test('handles very large fee amounts', () {
        final mockFees = [
          {
            'id': 'fee1',
            'user_id': 'user1',
            'amount': 9999999.99,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        ];

        final summary = _calculateFeeSummary(mockFees);
        expect(summary['total_owed'], 9999999.99);
      });
    });

    group('Date-based Calculations', () {
      test('correctly identifies overdue fees', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));

        final overdueFee = _createMockFee(
          status: 'pending',
          dueDate: yesterday,
        );

        final upcomingFee = _createMockFee(
          status: 'pending',
          dueDate: tomorrow,
        );

        expect(overdueFee.isOverdue, true);
        expect(upcomingFee.isOverdue, false);
      });

      test('handles fees due exactly now', () {
        final now = DateTime.now();
        final fee = _createMockFee(status: 'pending', dueDate: now);

        // A fee due exactly now should not be overdue
        expect(fee.isOverdue, false);
      });
    });

    group('Attendance Duration Calculations', () {
      test('calculates attendance duration correctly', () {
        final checkedInAt = DateTime.now();
        final checkedOutAt = checkedInAt.add(
          const Duration(hours: 2, minutes: 30),
        );

        final attendance = _createMockAttendance(
          checkedInAt: checkedInAt,
          checkedOutAt: checkedOutAt,
        );

        expect(attendance.durationMinutes, 150); // 2.5 hours = 150 minutes
        expect(attendance.durationDisplay, '2h 30m');
      });

      test('handles active attendance (not checked out yet)', () {
        final checkedInAt = DateTime.now().subtract(const Duration(hours: 1));

        final attendance = _createMockAttendance(
          checkedInAt: checkedInAt,
          checkedOutAt: null,
        );

        expect(attendance.isActive, true);
        expect(attendance.checkedOutAt, null);
        expect(attendance.durationMinutes, null);
      });
    });

    group('Fee Creation Logic', () {
      test('creates fee with correct amount from game', () {
        final game = _createMockGame(feePerPlayer: 25.0);
        final expectedFee = _createExpectedFeeFromGame(game, 'user1');

        expect(expectedFee['amount'], 25.0);
        expect(expectedFee['user_id'], 'user1');
        expect(expectedFee['game_id'], game.id);
        expect(expectedFee['status'], 'pending');
      });

      test('does not create fee for games with zero fee', () {
        final game = _createMockGame(feePerPlayer: 0.0);
        final shouldCreateFee =
            game.feePerPlayer != null && game.feePerPlayer! > 0;

        expect(shouldCreateFee, false);
      });

      test('does not create fee for games with null fee', () {
        final game = _createMockGame(feePerPlayer: null);
        final shouldCreateFee =
            game.feePerPlayer != null && game.feePerPlayer! > 0;

        expect(shouldCreateFee, false);
      });
    });

    group('Weekly and Monthly Aggregation Logic', () {
      test('calculates weekly fee totals correctly', () {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        final feesThisWeek = [
          _createFeeRecord(
            amount: 15.0,
            createdAt: weekStart.add(const Duration(days: 1)),
          ),
          _createFeeRecord(
            amount: 20.0,
            createdAt: weekStart.add(const Duration(days: 3)),
          ),
          _createFeeRecord(
            amount: 10.0,
            createdAt: weekStart.add(const Duration(days: 5)),
          ),
        ];

        final feesLastWeek = [
          _createFeeRecord(
            amount: 25.0,
            createdAt: weekStart.subtract(const Duration(days: 2)),
          ),
        ];

        final weeklyTotal = _calculateWeeklyTotal(
          feesThisWeek + feesLastWeek,
          weekStart,
        );
        expect(weeklyTotal, 45.0); // Only this week's fees
      });

      test('calculates monthly fee totals correctly', () {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);

        final feesThisMonth = [
          _createFeeRecord(
            amount: 15.0,
            createdAt: monthStart.add(const Duration(days: 5)),
          ),
          _createFeeRecord(
            amount: 20.0,
            createdAt: monthStart.add(const Duration(days: 15)),
          ),
          _createFeeRecord(
            amount: 10.0,
            createdAt: monthStart.add(const Duration(days: 25)),
          ),
        ];

        final feesLastMonth = [
          _createFeeRecord(
            amount: 25.0,
            createdAt: monthStart.subtract(const Duration(days: 5)),
          ),
        ];

        final monthlyTotal = _calculateMonthlyTotal(
          feesThisMonth + feesLastMonth,
          monthStart,
        );
        expect(monthlyTotal, 45.0); // Only this month's fees
      });
    });

    group('Attendance Rate Calculations', () {
      test('calculates attendance rate correctly', () {
        const totalGamesScheduled = 10;
        const gamesAttended = 7;

        final attendanceRate = _calculateAttendanceRate(
          gamesAttended,
          totalGamesScheduled,
        );
        expect(attendanceRate, 70.0); // 7/10 = 0.7 = 70%
      });

      test('handles zero games scheduled', () {
        const totalGamesScheduled = 0;
        const gamesAttended = 0;

        final attendanceRate = _calculateAttendanceRate(
          gamesAttended,
          totalGamesScheduled,
        );
        expect(attendanceRate, 0.0);
      });

      test('handles perfect attendance', () {
        const totalGamesScheduled = 5;
        const gamesAttended = 5;

        final attendanceRate = _calculateAttendanceRate(
          gamesAttended,
          totalGamesScheduled,
        );
        expect(attendanceRate, 100.0);
      });
    });
  });
}

// Helper functions that mirror the logic in AttendanceService

Map<String, dynamic> _calculateFeeSummary(List<Map<String, dynamic>> fees) {
  double totalOwed = 0;
  double totalPaid = 0;
  double totalWaived = 0;
  int overdueCount = 0;

  for (final fee in fees) {
    final amount = fee['amount'] as double;
    final status = fee['status'] as String;
    final dueDateStr = fee['due_date'] as String?;

    switch (status) {
      case 'pending':
        totalOwed += amount;
        if (dueDateStr != null) {
          final dueDate = DateTime.parse(dueDateStr);
          if (DateTime.now().isAfter(dueDate)) {
            overdueCount++;
          }
        }
        break;
      case 'paid':
        totalPaid += amount;
        break;
      case 'waived':
        totalWaived += amount;
        break;
    }
  }

  return {
    'total_owed': totalOwed,
    'total_paid': totalPaid,
    'total_waived': totalWaived,
    'overdue_count': overdueCount,
    'total_fees': fees.length,
  };
}

Map<String, dynamic> _calculateAttendanceStats(
  List<Map<String, dynamic>> attendances,
  int totalGames,
) {
  final totalAttendances = attendances.length;
  final averageAttendance =
      totalGames > 0 ? totalAttendances / totalGames : 0.0;

  return {
    'total_games': totalGames,
    'total_attendances': totalAttendances,
    'average_attendance': averageAttendance,
  };
}

double _calculateWeeklyTotal(
  List<Map<String, dynamic>> fees,
  DateTime weekStart,
) {
  final weekEnd = weekStart.add(const Duration(days: 7));

  return fees
      .where((fee) {
        final createdAt = DateTime.parse(fee['created_at'] as String);
        return createdAt.isAfter(weekStart) && createdAt.isBefore(weekEnd);
      })
      .fold(0.0, (sum, fee) => sum + (fee['amount'] as double));
}

double _calculateMonthlyTotal(
  List<Map<String, dynamic>> fees,
  DateTime monthStart,
) {
  final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

  return fees
      .where((fee) {
        final createdAt = DateTime.parse(fee['created_at'] as String);
        return createdAt.isAfter(monthStart) && createdAt.isBefore(monthEnd);
      })
      .fold(0.0, (sum, fee) => sum + (fee['amount'] as double));
}

double _calculateAttendanceRate(int gamesAttended, int totalGamesScheduled) {
  if (totalGamesScheduled == 0) return 0.0;
  return (gamesAttended / totalGamesScheduled) * 100;
}

Map<String, dynamic> _createFeeRecord({
  required double amount,
  required DateTime createdAt,
  String status = 'pending',
}) {
  return {
    'id': 'fee-${createdAt.millisecondsSinceEpoch}',
    'amount': amount,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': createdAt.toIso8601String(),
  };
}

Fee _createMockFee({
  String? id,
  String? userId,
  double? amount,
  String? status,
  DateTime? dueDate,
  DateTime? paidAt,
}) {
  return Fee(
    id: id ?? 'test-fee-id',
    userId: userId ?? 'test-user-id',
    amount: amount ?? 15.0,
    description: 'Test fee',
    feeType: 'game',
    status: status ?? 'pending',
    dueDate: dueDate,
    paidAt: paidAt,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Attendance _createMockAttendance({
  String? id,
  String? gameId,
  String? userId,
  DateTime? checkedInAt,
  DateTime? checkedOutAt,
  String? status,
}) {
  final checkIn = checkedInAt ?? DateTime.now();
  final checkOut = checkedOutAt;
  final duration = checkOut?.difference(checkIn).inMinutes;

  return Attendance(
    id: id ?? 'test-attendance-id',
    gameId: gameId ?? 'test-game-id',
    userId: userId ?? 'test-user-id',
    checkedInAt: checkIn,
    checkedOutAt: checkOut,
    durationMinutes: duration,
    status: status ?? 'present',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Game _createMockGame({String? id, String? title, double? feePerPlayer}) {
  return Game(
    id: id ?? 'test-game-id',
    teamId: 'test-team-id',
    organizerId: 'test-organizer-id',
    title: title ?? 'Test Game',
    sport: 'volleyball',
    venue: 'Test Venue',
    scheduledAt: DateTime.now().add(const Duration(hours: 1)),
    maxPlayers: 8,
    feePerPlayer: feePerPlayer,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Map<String, dynamic> _createExpectedFeeFromGame(Game game, String userId) {
  return {
    'user_id': userId,
    'game_id': game.id,
    'amount': game.feePerPlayer,
    'status': 'pending',
    'fee_type': 'game',
    'description': 'Game fee',
  };
}
