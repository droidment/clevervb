// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  id: json['id'] as String,
  name: json['name'] as String,
  sportType: json['sport_type'] as String,
  description: json['description'] as String?,
  organizerId: json['organizer_id'] as String,
  isPublic: json['is_public'] as bool,
  maxMembers: (json['max_members'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sport_type': instance.sportType,
  'description': instance.description,
  'organizer_id': instance.organizerId,
  'is_public': instance.isPublic,
  'max_members': instance.maxMembers,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

TeamMember _$TeamMemberFromJson(Map<String, dynamic> json) => TeamMember(
  teamId: json['team_id'] as String,
  userId: json['user_id'] as String,
  role: $enumDecode(_$TeamRoleEnumMap, json['role']),
  joinedAt: DateTime.parse(json['joined_at'] as String),
);

Map<String, dynamic> _$TeamMemberToJson(TeamMember instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'user_id': instance.userId,
      'role': _$TeamRoleEnumMap[instance.role]!,
      'joined_at': instance.joinedAt.toIso8601String(),
    };

const _$TeamRoleEnumMap = {
  TeamRole.organizer: 'organizer',
  TeamRole.member: 'member',
};

TeamInvitation _$TeamInvitationFromJson(Map<String, dynamic> json) =>
    TeamInvitation(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      invitedBy: json['invited_by'] as String,
      invitedEmail: json['invited_email'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt:
          json['used_at'] == null
              ? null
              : DateTime.parse(json['used_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TeamInvitationToJson(TeamInvitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'team_id': instance.teamId,
      'invited_by': instance.invitedBy,
      'invited_email': instance.invitedEmail,
      'token': instance.token,
      'expires_at': instance.expiresAt.toIso8601String(),
      'used_at': instance.usedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
