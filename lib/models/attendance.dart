import 'package:json_annotation/json_annotation.dart';

part 'attendance.g.dart';

@JsonSerializable()
class Attendance {
  final String id;
  @JsonKey(name: 'game_id')
  final String gameId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'checked_in_at')
  final DateTime checkedInAt;
  @JsonKey(name: 'checked_out_at')
  final DateTime? checkedOutAt;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  final String status;
  final String? notes;
  @JsonKey(name: 'verified_by')
  final String? verifiedBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Computed fields (populated from joins)
  @JsonKey(name: 'user_name', includeFromJson: false, includeToJson: false)
  final String? userName;
  @JsonKey(name: 'game_title', includeFromJson: false, includeToJson: false)
  final String? gameTitle;
  @JsonKey(name: 'game_fee', includeFromJson: false, includeToJson: false)
  final double? gameFee;

  const Attendance({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.checkedInAt,
    this.checkedOutAt,
    this.durationMinutes,
    this.status = 'present',
    this.notes,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.gameTitle,
    this.gameFee,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceToJson(this);

  Attendance copyWith({
    String? id,
    String? gameId,
    String? userId,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    int? durationMinutes,
    String? status,
    String? notes,
    String? verifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? gameTitle,
    double? gameFee,
  }) {
    return Attendance(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      userId: userId ?? this.userId,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      gameTitle: gameTitle ?? this.gameTitle,
      gameFee: gameFee ?? this.gameFee,
    );
  }

  /// Check if attendance is currently active (checked in but not out)
  bool get isActive => checkedOutAt == null;

  /// Calculate actual duration if checked out, or current duration if still active
  Duration get actualDuration {
    if (checkedOutAt != null) {
      return checkedOutAt!.difference(checkedInAt);
    }
    return DateTime.now().difference(checkedInAt);
  }

  /// Get status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'present':
        return isActive ? 'Checked In' : 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      case 'excused':
        return 'Excused';
      default:
        return 'Unknown';
    }
  }

  /// Get status emoji
  String get statusEmoji {
    switch (status.toLowerCase()) {
      case 'present':
        return '✅';
      case 'late':
        return '⏰';
      case 'absent':
        return '❌';
      case 'excused':
        return '🛡️';
      default:
        return '❓';
    }
  }

  /// Check if attendance was late (checked in more than 15 minutes after game start)
  bool isLateCheckIn(DateTime gameStartTime) {
    final lateThreshold = gameStartTime.add(const Duration(minutes: 15));
    return checkedInAt.isAfter(lateThreshold);
  }

  /// Format duration for display
  String get durationDisplay {
    final duration = actualDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attendance && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Attendance{id: $id, gameId: $gameId, userId: $userId, status: $status, checkedInAt: $checkedInAt}';
  }
}

@JsonSerializable()
class Fee {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'game_id')
  final String? gameId;
  @JsonKey(name: 'team_id')
  final String? teamId;
  @JsonKey(name: 'attendance_id')
  final String? attendanceId;
  final double amount;
  final String description;
  @JsonKey(name: 'fee_type')
  final String feeType;
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @JsonKey(name: 'paid_at')
  final DateTime? paidAt;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'payment_reference')
  final String? paymentReference;
  final String status;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Computed fields (populated from joins)
  @JsonKey(name: 'user_name', includeFromJson: false, includeToJson: false)
  final String? userName;
  @JsonKey(name: 'game_title', includeFromJson: false, includeToJson: false)
  final String? gameTitle;

  const Fee({
    required this.id,
    required this.userId,
    this.gameId,
    this.teamId,
    this.attendanceId,
    required this.amount,
    required this.description,
    this.feeType = 'game',
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.paymentReference,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.gameTitle,
  });

  factory Fee.fromJson(Map<String, dynamic> json) => _$FeeFromJson(json);
  Map<String, dynamic> toJson() => _$FeeToJson(this);

  Fee copyWith({
    String? id,
    String? userId,
    String? gameId,
    String? teamId,
    String? attendanceId,
    double? amount,
    String? description,
    String? feeType,
    DateTime? dueDate,
    DateTime? paidAt,
    String? paymentMethod,
    String? paymentReference,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? gameTitle,
  }) {
    return Fee(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      teamId: teamId ?? this.teamId,
      attendanceId: attendanceId ?? this.attendanceId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      feeType: feeType ?? this.feeType,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      gameTitle: gameTitle ?? this.gameTitle,
    );
  }

  /// Check if fee is paid
  bool get isPaid => status == 'paid' && paidAt != null;

  /// Check if fee is overdue
  bool get isOverdue {
    if (isPaid || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if fee is pending
  bool get isPending => status == 'pending';

  /// Check if fee is waived
  bool get isWaived => status == 'waived';

  /// Get status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return isOverdue ? 'Overdue' : 'Pending';
      case 'waived':
        return 'Waived';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// Get status emoji
  String get statusEmoji {
    switch (status.toLowerCase()) {
      case 'paid':
        return '✅';
      case 'pending':
        return isOverdue ? '⚠️' : '⏳';
      case 'waived':
        return '🎁';
      case 'cancelled':
        return '❌';
      default:
        return '❓';
    }
  }

  /// Get fee type display text
  String get feeTypeDisplay {
    switch (feeType.toLowerCase()) {
      case 'game':
        return 'Game Fee';
      case 'membership':
        return 'Membership';
      case 'equipment':
        return 'Equipment';
      case 'court':
        return 'Court Fee';
      case 'penalty':
        return 'Penalty';
      default:
        return 'Other';
    }
  }

  /// Format amount for display
  String get amountDisplay => '\$${amount.toStringAsFixed(2)}';

  /// Get days until due (negative if overdue)
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(
      DateTime(now.year, now.month, now.day),
    );
    return difference.inDays;
  }

  /// Get due date display text
  String get dueDateDisplay {
    if (dueDate == null) return 'No due date';
    if (isPaid) return 'Paid';

    final days = daysUntilDue;
    if (days == null) return 'No due date';

    if (days < 0) {
      return '${-days} days overdue';
    } else if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $days days';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fee && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Fee{id: $id, userId: $userId, amount: $amount, status: $status, feeType: $feeType}';
  }
}

/// Attendance status enum
enum AttendanceStatus {
  present,
  late,
  absent,
  excused;

  String get display {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  String get emoji {
    switch (this) {
      case AttendanceStatus.present:
        return '✅';
      case AttendanceStatus.late:
        return '⏰';
      case AttendanceStatus.absent:
        return '❌';
      case AttendanceStatus.excused:
        return '🛡️';
    }
  }
}

/// Fee status enum
enum FeeStatus {
  pending,
  paid,
  waived,
  cancelled;

  String get display {
    switch (this) {
      case FeeStatus.pending:
        return 'Pending';
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.waived:
        return 'Waived';
      case FeeStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case FeeStatus.pending:
        return '⏳';
      case FeeStatus.paid:
        return '✅';
      case FeeStatus.waived:
        return '🎁';
      case FeeStatus.cancelled:
        return '❌';
    }
  }
}

/// Fee type enum
enum FeeType {
  game,
  membership,
  equipment,
  court,
  penalty;

  String get display {
    switch (this) {
      case FeeType.game:
        return 'Game Fee';
      case FeeType.membership:
        return 'Membership';
      case FeeType.equipment:
        return 'Equipment';
      case FeeType.court:
        return 'Court Fee';
      case FeeType.penalty:
        return 'Penalty';
    }
  }
}
