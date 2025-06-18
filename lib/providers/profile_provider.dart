import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/profile_service.dart';
import '../models/user.dart' as models;

part 'profile_provider.g.dart';

@Riverpod(keepAlive: true)
ProfileService profileService(ProfileServiceRef ref) {
  return ProfileService();
}

@riverpod
Future<models.User?> currentUserProfile(CurrentUserProfileRef ref) async {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getCurrentUserProfile();
}

@riverpod
Future<Map<String, dynamic>> userStats(UserStatsRef ref, String userId) async {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getUserStats(userId);
}
