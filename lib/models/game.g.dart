// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Game _$GameFromJson(Map<String, dynamic> json) => Game(
  id: json['id'] as String,
  teamId: json['team_id'] as String,
  organizerId: json['organizer_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  sport: json['sport'] as String,
  venue: json['venue'] as String,
  address: json['address'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  scheduledAt: DateTime.parse(json['scheduled_at'] as String),
  durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 120,
  maxPlayers: (json['max_players'] as num?)?.toInt() ?? 8,
  feePerPlayer: (json['fee_per_player'] as num?)?.toDouble(),
  isPublic: json['is_public'] as bool? ?? false,
  requiresRsvp: json['requires_rsvp'] as bool? ?? true,
  autoConfirmRsvp: json['auto_confirm_rsvp'] as bool? ?? true,
  rsvpDeadline:
      json['rsvp_deadline'] == null
          ? null
          : DateTime.parse(json['rsvp_deadline'] as String),
  status: json['status'] as String? ?? 'scheduled',
  cancelledReason: json['cancelled_reason'] as String?,
  weatherDependent: json['weather_dependent'] as bool? ?? false,
  notes: json['notes'] as String?,
  equipmentNeeded:
      (json['equipment_needed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$GameToJson(Game instance) => <String, dynamic>{
  'id': instance.id,
  'team_id': instance.teamId,
  'organizer_id': instance.organizerId,
  'title': instance.title,
  'description': instance.description,
  'sport': instance.sport,
  'venue': instance.venue,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'scheduled_at': instance.scheduledAt.toIso8601String(),
  'duration_minutes': instance.durationMinutes,
  'max_players': instance.maxPlayers,
  'fee_per_player': instance.feePerPlayer,
  'is_public': instance.isPublic,
  'requires_rsvp': instance.requiresRsvp,
  'auto_confirm_rsvp': instance.autoConfirmRsvp,
  'rsvp_deadline': instance.rsvpDeadline?.toIso8601String(),
  'status': instance.status,
  'cancelled_reason': instance.cancelledReason,
  'weather_dependent': instance.weatherDependent,
  'notes': instance.notes,
  'equipment_needed': instance.equipmentNeeded,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
