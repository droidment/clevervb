import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance.dart';
import '../services/game_service.dart';
import 'auth_service.dart';

class AttendanceService {
  static final _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final _logger = Logger();
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  final _gameService = GameService();

  // ==================== ATTENDANCE OPERATIONS ====================

  /// Check in for a game
  Future<Attendance> checkIn(String gameId, {String? notes}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to check in');
      }

      // Convert auth user id to st_users.id
      final authService = AuthService();
      final stUserId = await authService.getCurrentUserId();
      if (stUserId == null) {
        throw Exception('User profile not found');
      }

      final game = await _gameService.getGame(gameId);

      // Validate check-in window
      if (!game.canCheckIn) {
        throw Exception('Check-in is not available for this game');
      }

      // Check if already checked in
      final existingAttendance = await getUserAttendance(gameId, stUserId);
      if (existingAttendance != null) {
        throw Exception('Already checked in for this game');
      }

      _logger.i('Checking in user $stUserId for game: $gameId');

      final attendanceId = _uuid.v4();
      final now = DateTime.now();

      // Determine status based on check-in time
      final isLate = now.isAfter(
        game.scheduledAt.add(const Duration(minutes: 15)),
      );
      final status = isLate ? 'late' : 'present';

      // Create attendance record
      await _supabase.from('st_attendances').insert({
        'id': attendanceId,
        'game_id': gameId,
        'user_id': stUserId,
        'checked_in_at': now.toIso8601String(),
        'status': status,
        'notes': notes?.trim(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Create fee record if game has a fee
      if (game.feePerPlayer != null && game.feePerPlayer! > 0) {
        await _createFeeRecord(
          gameId: gameId,
          userId: stUserId,
          amount: game.feePerPlayer!,
          attendanceId: attendanceId,
        );
      }

      _logger.i('Check-in successful');

      return getAttendance(attendanceId);
    } catch (e) {
      _logger.e('Error checking in: $e');
      rethrow;
    }
  }

  /// Check out from a game
  Future<Attendance> checkOut(String gameId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to check out');
      }

      // Map auth user to st_users.id to match attendance records
      final authService = AuthService();
      final stUserId = await authService.getCurrentUserId();
      final attendance = await getUserAttendance(gameId, stUserId ?? user.id);

      if (attendance == null) {
        throw Exception('No check-in record found for this game');
      }

      if (attendance.checkedOutAt != null) {
        throw Exception('Already checked out');
      }

      _logger.i('Checking out user ${user.id} from game: $gameId');

      final now = DateTime.now();
      final durationMinutes = now.difference(attendance.checkedInAt).inMinutes;

      await _supabase
          .from('st_attendances')
          .update({
            'checked_out_at': now.toIso8601String(),
            'duration_minutes': durationMinutes,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', attendance.id);

      _logger.i('Check-out successful');

      return getAttendance(attendance.id);
    } catch (e) {
      _logger.e('Error checking out: $e');
      rethrow;
    }
  }

  /// Get attendance record by ID
  Future<Attendance> getAttendance(String attendanceId) async {
    try {
      final response =
          await _supabase
              .from('st_attendances')
              .select('''
            *,
            st_users!st_attendances_user_id_fkey(full_name, avatar_url),
            st_games!st_attendances_game_id_fkey(title, fee_per_player)
          ''')
              .eq('id', attendanceId)
              .single();

      return _mapAttendanceFromResponse(response);
    } catch (e) {
      _logger.e('Error fetching attendance: $e');
      rethrow;
    }
  }

  /// Get user's attendance for a game
  Future<Attendance?> getUserAttendance(String gameId, String userId) async {
    try {
      final response =
          await _supabase
              .from('st_attendances')
              .select('''
            *,
            st_users!st_attendances_user_id_fkey(full_name, avatar_url),
            st_games!st_attendances_game_id_fkey(title, fee_per_player)
          ''')
              .eq('game_id', gameId)
              .eq('user_id', userId)
              .maybeSingle();

      return response != null ? _mapAttendanceFromResponse(response) : null;
    } catch (e) {
      _logger.e('Error fetching user attendance: $e');
      rethrow;
    }
  }

  /// Get all attendances for a game
  Future<List<Attendance>> getGameAttendances(String gameId) async {
    try {
      final response = await _supabase
          .from('st_attendances')
          .select('''
            *,
            st_users!st_attendances_user_id_fkey(full_name, avatar_url, email),
            st_games!st_attendances_game_id_fkey(title, fee_per_player)
          ''')
          .eq('game_id', gameId)
          .order('checked_in_at');

      return response
          .map((attendance) => _mapAttendanceFromResponse(attendance))
          .toList();
    } catch (e) {
      _logger.e('Error fetching game attendances: $e');
      rethrow;
    }
  }

  /// Get user's attendance history
  Future<List<Attendance>> getUserAttendanceHistory(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('st_attendances')
          .select('''
            *,
            st_games!st_attendances_game_id_fkey(
              title, 
              scheduled_at, 
              venue, 
              fee_per_player,
              st_teams!st_games_team_id_fkey(name, sport_type)
            )
          ''')
          .eq('user_id', userId)
          .order('checked_in_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map((attendance) => _mapAttendanceFromResponse(attendance))
          .toList();
    } catch (e) {
      _logger.e('Error fetching user attendance history: $e');
      rethrow;
    }
  }

  /// Update attendance status (organizer only)
  Future<Attendance> updateAttendanceStatus(
    String attendanceId,
    String status, {
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to update attendance');
      }

      // Get attendance and verify organizer permissions
      final attendance = await getAttendance(attendanceId);
      final game = await _gameService.getGame(attendance.gameId);

      if (game.organizerId != user.id) {
        throw Exception('Only the game organizer can update attendance status');
      }

      _logger.i('Updating attendance status: $attendanceId to $status');

      await _supabase
          .from('st_attendances')
          .update({
            'status': status,
            'notes': notes ?? attendance.notes,
            'verified_by': user.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', attendanceId);

      _logger.i('Attendance status updated successfully');

      return getAttendance(attendanceId);
    } catch (e) {
      _logger.e('Error updating attendance status: $e');
      rethrow;
    }
  }

  // ==================== FEE OPERATIONS ====================

  /// Create a fee record
  Future<Fee> _createFeeRecord({
    required String gameId,
    required String userId,
    required double amount,
    String? attendanceId,
    String description = 'Game fee',
    String feeType = 'game',
    DateTime? dueDate,
  }) async {
    try {
      final feeId = _uuid.v4();
      final now = DateTime.now();

      await _supabase.from('st_fees').insert({
        'id': feeId,
        'user_id': userId,
        'game_id': gameId,
        'attendance_id': attendanceId,
        'amount': amount,
        'description': description,
        'fee_type': feeType,
        'due_date': dueDate?.toIso8601String(),
        'status': 'pending',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      return getFee(feeId);
    } catch (e) {
      _logger.e('Error creating fee record: $e');
      rethrow;
    }
  }

  /// Get fee by ID
  Future<Fee> getFee(String feeId) async {
    try {
      final response =
          await _supabase
              .from('st_fees')
              .select('''
            *,
            st_users!st_fees_user_id_fkey(full_name, avatar_url),
            st_games!st_fees_game_id_fkey(title, scheduled_at)
          ''')
              .eq('id', feeId)
              .single();

      return _mapFeeFromResponse(response);
    } catch (e) {
      _logger.e('Error fetching fee: $e');
      rethrow;
    }
  }

  /// Get fees for a user
  Future<List<Fee>> getUserFees(
    String userId, {
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('st_fees')
          .select('''
            *,
            st_games!st_fees_game_id_fkey(
              title, 
              scheduled_at, 
              venue,
              st_teams!st_games_team_id_fkey(name, sport_type)
            )
          ''')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((fee) => _mapFeeFromResponse(fee)).toList();
    } catch (e) {
      _logger.e('Error fetching user fees: $e');
      rethrow;
    }
  }

  /// Get fees for a game
  Future<List<Fee>> getGameFees(String gameId) async {
    try {
      final response = await _supabase
          .from('st_fees')
          .select('''
            *,
            st_users!st_fees_user_id_fkey(full_name, avatar_url, email)
          ''')
          .eq('game_id', gameId)
          .order('created_at');

      return response.map((fee) => _mapFeeFromResponse(fee)).toList();
    } catch (e) {
      _logger.e('Error fetching game fees: $e');
      rethrow;
    }
  }

  /// Mark fee as paid
  Future<Fee> markFeePaid(
    String feeId, {
    String? paymentMethod,
    String? paymentReference,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to mark fee as paid');
      }

      _logger.i('Marking fee as paid: $feeId');

      await _supabase
          .from('st_fees')
          .update({
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
            'payment_method': paymentMethod,
            'payment_reference': paymentReference,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', feeId);

      _logger.i('Fee marked as paid successfully');

      return getFee(feeId);
    } catch (e) {
      _logger.e('Error marking fee as paid: $e');
      rethrow;
    }
  }

  /// Waive a fee (organizer only)
  Future<Fee> waiveFee(String feeId, String reason) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to waive fee');
      }

      // Verify organizer permissions
      final fee = await getFee(feeId);
      if (fee.gameId != null) {
        final game = await _gameService.getGame(fee.gameId!);
        if (game.organizerId != user.id) {
          throw Exception('Only the game organizer can waive fees');
        }
      }

      _logger.i('Waiving fee: $feeId');

      await _supabase
          .from('st_fees')
          .update({
            'status': 'waived',
            'notes': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', feeId);

      _logger.i('Fee waived successfully');

      return getFee(feeId);
    } catch (e) {
      _logger.e('Error waiving fee: $e');
      rethrow;
    }
  }

  // ==================== REPORTING & ANALYTICS ====================

  /// Get fee summary for a user
  Future<Map<String, dynamic>> getUserFeeSummary(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_fee_summary',
        params: {'p_user_id': userId},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      _logger.e('Error fetching user fee summary: $e');
      // Fallback to manual calculation
      return await _calculateUserFeeSummary(userId);
    }
  }

  /// Manual fee summary calculation (fallback)
  Future<Map<String, dynamic>> _calculateUserFeeSummary(String userId) async {
    try {
      final fees = await getUserFees(userId);

      double totalOwed = 0;
      double totalPaid = 0;
      double totalWaived = 0;
      int overdueCount = 0;

      for (final fee in fees) {
        switch (fee.status) {
          case 'pending':
            totalOwed += fee.amount;
            if (fee.isOverdue) overdueCount++;
            break;
          case 'paid':
            totalPaid += fee.amount;
            break;
          case 'waived':
            totalWaived += fee.amount;
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
    } catch (e) {
      _logger.e('Error calculating fee summary: $e');
      rethrow;
    }
  }

  /// Get team attendance stats
  Future<Map<String, dynamic>> getTeamAttendanceStats(String teamId) async {
    try {
      final response = await _supabase.rpc(
        'get_team_attendance_stats',
        params: {'p_team_id': teamId},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      _logger.e('Error fetching team attendance stats: $e');
      // Return empty stats as fallback
      return {
        'total_games': 0,
        'total_attendances': 0,
        'average_attendance': 0.0,
        'top_attendees': [],
      };
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Map database response to Attendance object
  Attendance _mapAttendanceFromResponse(Map<String, dynamic> response) {
    final user = response['st_users'];
    final game = response['st_games'];

    return Attendance(
      id: response['id'],
      gameId: response['game_id'],
      userId: response['user_id'],
      checkedInAt: DateTime.parse(response['checked_in_at']),
      checkedOutAt:
          response['checked_out_at'] != null
              ? DateTime.parse(response['checked_out_at'])
              : null,
      durationMinutes: response['duration_minutes'],
      status: response['status'],
      notes: response['notes'],
      verifiedBy: response['verified_by'],
      createdAt: DateTime.parse(response['created_at']),
      updatedAt: DateTime.parse(response['updated_at']),
      userName: user?['full_name'],
      gameTitle: game?['title'],
      gameFee: game?['fee_per_player']?.toDouble(),
    );
  }

  /// Map database response to Fee object
  Fee _mapFeeFromResponse(Map<String, dynamic> response) {
    final user = response['st_users'];
    final game = response['st_games'];

    return Fee(
      id: response['id'],
      userId: response['user_id'],
      gameId: response['game_id'],
      teamId: response['team_id'],
      attendanceId: response['attendance_id'],
      amount: response['amount'].toDouble(),
      description: response['description'],
      feeType: response['fee_type'],
      dueDate:
          response['due_date'] != null
              ? DateTime.parse(response['due_date'])
              : null,
      paidAt:
          response['paid_at'] != null
              ? DateTime.parse(response['paid_at'])
              : null,
      paymentMethod: response['payment_method'],
      paymentReference: response['payment_reference'],
      status: response['status'],
      notes: response['notes'],
      createdAt: DateTime.parse(response['created_at']),
      updatedAt: DateTime.parse(response['updated_at']),
      userName: user?['full_name'],
      gameTitle: game?['title'],
    );
  }
}
