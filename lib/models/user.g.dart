// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  avatarUrl: json['avatar_url'] as String?,
  phone: json['phone'] as String?,
  dateOfBirth:
      json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
  location: json['location'] as String?,
  bio: json['bio'] as String?,
  preferredSports:
      (json['preferred_sports'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  skillLevel: json['skill_level'] as String? ?? 'beginner',
  isProfileComplete: json['is_profile_complete'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'full_name': instance.fullName,
  'avatar_url': instance.avatarUrl,
  'phone': instance.phone,
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'location': instance.location,
  'bio': instance.bio,
  'preferred_sports': instance.preferredSports,
  'skill_level': instance.skillLevel,
  'is_profile_complete': instance.isProfileComplete,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
