import 'package:json_annotation/json_annotation.dart';

part 'team.g.dart';

@JsonSerializable()
class Team {
  final String id;
  final String name;
  @JsonKey(name: 'sport_type')
  final String sportType;
  final String? description;
  @JsonKey(name: 'organizer_id')
  final String organizerId;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'max_members')
  final int? maxMembers;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Additional computed fields
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int? memberCount;
  
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? organizerName;
  
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? organizerAvatarUrl;

  const Team({
    required this.id,
    required this.name,
    required this.sportType,
    this.description,
    required this.organizerId,
    required this.isPublic,
    this.maxMembers,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount,
    this.organizerName,
    this.organizerAvatarUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);

  Team copyWith({
    String? id,
    String? name,
    String? sportType,
    String? description,
    String? organizerId,
    bool? isPublic,
    int? maxMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    String? organizerName,
    String? organizerAvatarUrl,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      sportType: sportType ?? this.sportType,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      isPublic: isPublic ?? this.isPublic,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      organizerName: organizerName ?? this.organizerName,
      organizerAvatarUrl: organizerAvatarUrl ?? this.organizerAvatarUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Team(id: $id, name: $name, sportType: $sportType, isPublic: $isPublic)';
  }

  // Helper getters
  bool get hasMaxMembers => maxMembers != null;
  bool get isFull => hasMaxMembers && memberCount != null && memberCount! >= maxMembers!;
  bool get hasDescription => description != null && description!.isNotEmpty;
  
  String get displaySportType {
    return sportType.substring(0, 1).toUpperCase() + sportType.substring(1);
  }
}

@JsonSerializable()
class TeamMember {
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'user_id')
  final String userId;
  final TeamRole role;
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;

  // User details (populated from joins)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? fullName;
  
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? email;
  
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? avatarUrl;

  const TeamMember({
    required this.teamId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.fullName,
    this.email,
    this.avatarUrl,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => _$TeamMemberFromJson(json);
  Map<String, dynamic> toJson() => _$TeamMemberToJson(this);

  TeamMember copyWith({
    String? teamId,
    String? userId,
    TeamRole? role,
    DateTime? joinedAt,
    String? fullName,
    String? email,
    String? avatarUrl,
  }) {
    return TeamMember(
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamMember && 
           other.teamId == teamId && 
           other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(teamId, userId);

  @override
  String toString() {
    return 'TeamMember(teamId: $teamId, userId: $userId, role: $role)';
  }

  bool get isOrganizer => role == TeamRole.organizer;
  bool get isMember => role == TeamRole.member;
}

@JsonSerializable()
class TeamInvitation {
  final String id;
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'invited_by')
  final String invitedBy;
  @JsonKey(name: 'invited_email')
  final String invitedEmail;
  final String token;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;
  @JsonKey(name: 'used_at')
  final DateTime? usedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // Additional computed fields
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? teamName;
  
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? inviterName;

  const TeamInvitation({
    required this.id,
    required this.teamId,
    required this.invitedBy,
    required this.invitedEmail,
    required this.token,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
    this.teamName,
    this.inviterName,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) => _$TeamInvitationFromJson(json);
  Map<String, dynamic> toJson() => _$TeamInvitationToJson(this);

  TeamInvitation copyWith({
    String? id,
    String? teamId,
    String? invitedBy,
    String? invitedEmail,
    String? token,
    DateTime? expiresAt,
    DateTime? usedAt,
    DateTime? createdAt,
    String? teamName,
    String? inviterName,
  }) {
    return TeamInvitation(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      teamName: teamName ?? this.teamName,
      inviterName: inviterName ?? this.inviterName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamInvitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TeamInvitation(id: $id, teamId: $teamId, invitedEmail: $invitedEmail)';
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedAt != null;
  bool get isValid => !isExpired && !isUsed;
}

@JsonEnum()
enum TeamRole {
  @JsonValue('organizer')
  organizer,
  @JsonValue('member')
  member,
}

// Extension for display names
extension TeamRoleExtension on TeamRole {
  String get displayName {
    switch (this) {
      case TeamRole.organizer:
        return 'Organizer';
      case TeamRole.member:
        return 'Member';
    }
  }
}

// Sport types enum for consistency
enum SportType {
  volleyball,
  pickleball,
  basketball,
  tennis,
  badminton,
  soccer;

  String get displayName {
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }

  static List<String> get allValues => SportType.values.map((e) => e.name).toList();
} 