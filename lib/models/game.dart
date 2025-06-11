import 'package:json_annotation/json_annotation.dart';

part 'game.g.dart';

@JsonSerializable()
class Game {
  final String id;
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'organizer_id')
  final String organizerId;
  final String title;
  final String? description;
  final String sport;
  final String venue;
  final String? address;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'scheduled_at')
  final DateTime scheduledAt;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'max_players')
  final int maxPlayers;
  @JsonKey(name: 'fee_per_player')
  final double? feePerPlayer;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'requires_rsvp')
  final bool requiresRsvp;
  @JsonKey(name: 'auto_confirm_rsvp')
  final bool autoConfirmRsvp;
  @JsonKey(name: 'rsvp_deadline')
  final DateTime? rsvpDeadline;
  final String status;
  @JsonKey(name: 'cancelled_reason')
  final String? cancelledReason;
  @JsonKey(name: 'weather_dependent')
  final bool weatherDependent;
  final String? notes;
  @JsonKey(name: 'equipment_needed')
  final List<String> equipmentNeeded;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Computed fields (populated from joins)
  @JsonKey(name: 'organizer_name', includeFromJson: false, includeToJson: false)
  final String? organizerName;
  @JsonKey(name: 'team_name', includeFromJson: false, includeToJson: false)
  final String? teamName;
  @JsonKey(name: 'rsvp_count', includeFromJson: false, includeToJson: false)
  final int? rsvpCount;
  @JsonKey(
    name: 'attendance_count',
    includeFromJson: false,
    includeToJson: false,
  )
  final int? attendanceCount;

  const Game({
    required this.id,
    required this.teamId,
    required this.organizerId,
    required this.title,
    this.description,
    required this.sport,
    required this.venue,
    this.address,
    this.latitude,
    this.longitude,
    required this.scheduledAt,
    this.durationMinutes = 120,
    this.maxPlayers = 8,
    this.feePerPlayer,
    this.isPublic = false,
    this.requiresRsvp = true,
    this.autoConfirmRsvp = true,
    this.rsvpDeadline,
    this.status = 'scheduled',
    this.cancelledReason,
    this.weatherDependent = false,
    this.notes,
    this.equipmentNeeded = const [],
    required this.createdAt,
    required this.updatedAt,
    this.organizerName,
    this.teamName,
    this.rsvpCount,
    this.attendanceCount,
  });

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
  Map<String, dynamic> toJson() => _$GameToJson(this);

  Game copyWith({
    String? id,
    String? teamId,
    String? organizerId,
    String? title,
    String? description,
    String? sport,
    String? venue,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? scheduledAt,
    int? durationMinutes,
    int? maxPlayers,
    double? feePerPlayer,
    bool? isPublic,
    bool? requiresRsvp,
    bool? autoConfirmRsvp,
    DateTime? rsvpDeadline,
    String? status,
    String? cancelledReason,
    bool? weatherDependent,
    String? notes,
    List<String>? equipmentNeeded,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organizerName,
    String? teamName,
    int? rsvpCount,
    int? attendanceCount,
  }) {
    return Game(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      organizerId: organizerId ?? this.organizerId,
      title: title ?? this.title,
      description: description ?? this.description,
      sport: sport ?? this.sport,
      venue: venue ?? this.venue,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      feePerPlayer: feePerPlayer ?? this.feePerPlayer,
      isPublic: isPublic ?? this.isPublic,
      requiresRsvp: requiresRsvp ?? this.requiresRsvp,
      autoConfirmRsvp: autoConfirmRsvp ?? this.autoConfirmRsvp,
      rsvpDeadline: rsvpDeadline ?? this.rsvpDeadline,
      status: status ?? this.status,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      weatherDependent: weatherDependent ?? this.weatherDependent,
      notes: notes ?? this.notes,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizerName: organizerName ?? this.organizerName,
      teamName: teamName ?? this.teamName,
      rsvpCount: rsvpCount ?? this.rsvpCount,
      attendanceCount: attendanceCount ?? this.attendanceCount,
    );
  }

  /// Check if game is upcoming (scheduled in the future)
  bool get isUpcoming => DateTime.now().isBefore(scheduledAt);

  /// Check if game is currently in progress
  bool get isInProgress {
    final now = DateTime.now();
    final endTime = scheduledAt.add(Duration(minutes: durationMinutes));
    return now.isAfter(scheduledAt) && now.isBefore(endTime);
  }

  /// Check if game has ended
  bool get hasEnded {
    final now = DateTime.now();
    final endTime = scheduledAt.add(Duration(minutes: durationMinutes));
    return now.isAfter(endTime);
  }

  /// Check if game is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Check if game is completed
  bool get isCompleted => status == 'completed';

  /// Check if RSVP is still open
  bool get isRsvpOpen {
    if (!requiresRsvp) return false;
    if (rsvpDeadline == null) return isUpcoming;
    return DateTime.now().isBefore(rsvpDeadline!) && isUpcoming;
  }

  /// Check if game has reached maximum capacity
  bool get isFull => (rsvpCount ?? 0) >= maxPlayers;

  /// Get game end time
  DateTime get endTime => scheduledAt.add(Duration(minutes: durationMinutes));

  /// Get status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'scheduled':
        if (isInProgress) return 'In Progress';
        if (hasEnded) return 'Ended';
        return 'Scheduled';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'postponed':
        return 'Postponed';
      default:
        return 'Unknown';
    }
  }

  /// Get sport display text with emoji
  String get sportDisplay {
    switch (sport.toLowerCase()) {
      case 'volleyball':
        return '🏐 Volleyball';
      case 'pickleball':
        return '🏓 Pickleball';
      case 'basketball':
        return '🏀 Basketball';
      case 'tennis':
        return '🎾 Tennis';
      case 'badminton':
        return '🏸 Badminton';
      case 'soccer':
        return '⚽ Soccer';
      default:
        return '🏅 $sport';
    }
  }

  /// Get remaining spots available
  int get remainingSpots => maxPlayers - (rsvpCount ?? 0);

  /// Format fee for display
  String get feeDisplay {
    if (feePerPlayer == null || feePerPlayer == 0) return 'Free';
    return '\$${feePerPlayer!.toStringAsFixed(2)}';
  }

  /// Get venue and address display
  String get locationDisplay {
    if (address != null && address!.isNotEmpty) {
      return '$venue\n$address';
    }
    return venue;
  }

  /// Check if user can still check in for attendance
  bool get canCheckIn {
    if (isCancelled || isCompleted) return false;
    final now = DateTime.now();
    final checkInStart = scheduledAt.subtract(const Duration(minutes: 30));
    final checkInEnd = endTime;
    return now.isAfter(checkInStart) && now.isBefore(checkInEnd);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Game{id: $id, title: $title, sport: $sport, scheduledAt: $scheduledAt, status: $status}';
  }
}

/// RSVP response enum
enum RsvpResponse {
  yes,
  no,
  maybe,
  waitlist;

  String get display {
    switch (this) {
      case RsvpResponse.yes:
        return 'Yes';
      case RsvpResponse.no:
        return 'No';
      case RsvpResponse.maybe:
        return 'Maybe';
      case RsvpResponse.waitlist:
        return 'Waitlist';
    }
  }

  String get emoji {
    switch (this) {
      case RsvpResponse.yes:
        return '✅';
      case RsvpResponse.no:
        return '❌';
      case RsvpResponse.maybe:
        return '❓';
      case RsvpResponse.waitlist:
        return '⏰';
    }
  }
}

/// Game status enum
enum GameStatus {
  scheduled,
  cancelled,
  completed,
  postponed;

  String get display {
    switch (this) {
      case GameStatus.scheduled:
        return 'Scheduled';
      case GameStatus.cancelled:
        return 'Cancelled';
      case GameStatus.completed:
        return 'Completed';
      case GameStatus.postponed:
        return 'Postponed';
    }
  }
}

/// Sports enum
enum Sport {
  volleyball,
  pickleball,
  basketball,
  tennis,
  badminton,
  soccer;

  String get display {
    switch (this) {
      case Sport.volleyball:
        return 'Volleyball';
      case Sport.pickleball:
        return 'Pickleball';
      case Sport.basketball:
        return 'Basketball';
      case Sport.tennis:
        return 'Tennis';
      case Sport.badminton:
        return 'Badminton';
      case Sport.soccer:
        return 'Soccer';
    }
  }

  String get emoji {
    switch (this) {
      case Sport.volleyball:
        return '🏐';
      case Sport.pickleball:
        return '🏓';
      case Sport.basketball:
        return '🏀';
      case Sport.tennis:
        return '🎾';
      case Sport.badminton:
        return '🏸';
      case Sport.soccer:
        return '⚽';
    }
  }

  int get defaultMaxPlayers {
    switch (this) {
      case Sport.volleyball:
        return 8;
      case Sport.pickleball:
        return 2;
      case Sport.basketball:
        return 10;
      case Sport.tennis:
        return 4;
      case Sport.badminton:
        return 4;
      case Sport.soccer:
        return 22;
    }
  }

  double get defaultFee {
    switch (this) {
      case Sport.volleyball:
        return 15.0;
      case Sport.pickleball:
        return 10.0;
      case Sport.basketball:
        return 12.0;
      case Sport.tennis:
        return 20.0;
      case Sport.badminton:
        return 8.0;
      case Sport.soccer:
        return 18.0;
    }
  }
}
