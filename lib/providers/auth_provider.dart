import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
});

// Is signed in provider
final isSignedInProvider = Provider<bool>((ref) {
  final asyncUser = ref.watch(currentUserProvider);
  return asyncUser.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// User profile provider
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  if (!authService.isSignedIn) return null;

  return await authService.getUserProfile();
});

// Profile completion status provider
final isProfileCompleteProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  if (!authService.isSignedIn) return false;

  return await authService.isProfileComplete();
});

// Auth state notifier for complex auth operations
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((authState) {
      state = AsyncValue.data(authState.session?.user);
    });
  }

  final AuthService _authService;

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signInWithGoogle();
      state = AsyncValue.data(response.user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required DateTime dateOfBirth,
    String? phone,
    String? bio,
    List<String>? preferredSports,
    String? skillLevel,
    String? location,
  }) async {
    try {
      await _authService.updateUserProfile(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        phone: phone,
        bio: bio,
        preferredSports: preferredSports,
        skillLevel: skillLevel,
        location: location,
      );
      // Profile updated successfully, state remains the same
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Auth notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthNotifier(authService);
    });
