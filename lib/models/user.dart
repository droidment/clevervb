import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final String? phone;
  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;
  final String? location;
  final String? bio;
  @JsonKey(name: 'preferred_sports')
  final List<String> preferredSports;
  @JsonKey(name: 'skill_level')
  final String skillLevel;
  @JsonKey(name: 'is_profile_complete')
  final bool isProfileComplete;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.dateOfBirth,
    this.location,
    this.bio,
    this.preferredSports = const [],
    this.skillLevel = 'beginner',
    this.isProfileComplete = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? location,
    String? bio,
    List<String>? preferredSports,
    String? skillLevel,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      preferredSports: preferredSports ?? this.preferredSports,
      skillLevel: skillLevel ?? this.skillLevel,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate user's age based on date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    final difference = now.difference(dateOfBirth!);
    return (difference.inDays / 365.25).floor();
  }

  /// Check if user meets minimum age requirement
  bool get meetsAgeRequirement {
    final userAge = age;
    return userAge != null && userAge >= 18;
  }

  /// Get user's initials for avatar fallback
  String get initials {
    if (fullName.isEmpty) return email.substring(0, 1).toUpperCase();

    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Get skill level display text
  String get skillLevelDisplay {
    switch (skillLevel.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      case 'expert':
        return 'Expert';
      default:
        return 'Beginner';
    }
  }

  /// Get preferred sports as a formatted string
  String get preferredSportsDisplay {
    if (preferredSports.isEmpty) return 'No sports selected';
    if (preferredSports.length == 1) return preferredSports.first;
    if (preferredSports.length == 2) {
      return '${preferredSports[0]} and ${preferredSports[1]}';
    }
    return '${preferredSports.take(preferredSports.length - 1).join(', ')}, and ${preferredSports.last}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, email: $email, fullName: $fullName, isProfileComplete: $isProfileComplete}';
  }
}
