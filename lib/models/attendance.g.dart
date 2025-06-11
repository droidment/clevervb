// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attendance _$AttendanceFromJson(Map<String, dynamic> json) => Attendance(
  id: json['id'] as String,
  gameId: json['game_id'] as String,
  userId: json['user_id'] as String,
  checkedInAt: DateTime.parse(json['checked_in_at'] as String),
  checkedOutAt:
      json['checked_out_at'] == null
          ? null
          : DateTime.parse(json['checked_out_at'] as String),
  durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
  status: json['status'] as String? ?? 'present',
  notes: json['notes'] as String?,
  verifiedBy: json['verified_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AttendanceToJson(Attendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'game_id': instance.gameId,
      'user_id': instance.userId,
      'checked_in_at': instance.checkedInAt.toIso8601String(),
      'checked_out_at': instance.checkedOutAt?.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'status': instance.status,
      'notes': instance.notes,
      'verified_by': instance.verifiedBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

Fee _$FeeFromJson(Map<String, dynamic> json) => Fee(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  gameId: json['game_id'] as String?,
  teamId: json['team_id'] as String?,
  attendanceId: json['attendance_id'] as String?,
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String,
  feeType: json['fee_type'] as String? ?? 'game',
  dueDate:
      json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
  paidAt:
      json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
  paymentMethod: json['payment_method'] as String?,
  paymentReference: json['payment_reference'] as String?,
  status: json['status'] as String? ?? 'pending',
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$FeeToJson(Fee instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'game_id': instance.gameId,
  'team_id': instance.teamId,
  'attendance_id': instance.attendanceId,
  'amount': instance.amount,
  'description': instance.description,
  'fee_type': instance.feeType,
  'due_date': instance.dueDate?.toIso8601String(),
  'paid_at': instance.paidAt?.toIso8601String(),
  'payment_method': instance.paymentMethod,
  'payment_reference': instance.paymentReference,
  'status': instance.status,
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
