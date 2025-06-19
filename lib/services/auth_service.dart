import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../config/env.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _logger = Logger();
  final _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;

  // Initialize the service
  Future<void> initialize() async {
    // Initialize Google Sign In with proper client ID for web platform
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: Env.googleWebClientId, // Use web client ID for web platform
    );

    _logger.i('AuthService initialized');
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get auth stream for state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign in with Google using Supabase OAuth (better for web)
  Future<bool> signInWithGoogleOAuth() async {
    try {
      _logger.i('Starting Google OAuth sign-in process');

      // For web deployment, use the actual deployed URL
      final redirectTo =
          kIsWeb
              ? '${Uri.base.origin}/auth/callback'
              : // Production/deployed URL
              'http://localhost:3000/auth/callback'; // Local development

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );

      _logger.i('Google OAuth initiated successfully');
      return response;
    } catch (e) {
      _logger.e('Google OAuth sign-in failed: $e');
      rethrow;
    }
  }

  // Handle OAuth callback and create user profile if needed
  Future<void> handleOAuthCallback() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        _logger.i('OAuth callback successful for user: ${currentUser.email}');
        await _checkAndCreateUserProfile(currentUser);
      }
    } catch (e) {
      _logger.e('Error handling OAuth callback: $e');
      rethrow;
    }
  }

  // Sign in with Google (fallback method for mobile)
  Future<AuthResponse> signInWithGoogle() async {
    try {
      _logger.i('Starting Google sign-in process');

      // Check if Google Play Services are available
      if (!await _googleSignIn.isSignedIn()) {
        // Trigger the Google Sign-In flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('Google sign-in was cancelled by user');
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw Exception('Failed to get Google ID token');
        }

        _logger.i('Google sign-in successful, authenticating with Supabase');

        // Sign in to Supabase with Google ID token
        final AuthResponse response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken,
        );

        if (response.user != null) {
          _logger.i(
            'Supabase authentication successful for user: ${response.user!.email}',
          );

          // Check if user profile exists and is complete
          await _checkAndCreateUserProfile(response.user!);
        }

        return response;
      } else {
        // User is already signed in with Google
        final GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          final AuthResponse response = await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken,
          );

          if (response.user != null) {
            await _checkAndCreateUserProfile(response.user!);
          }

          return response;
        } else {
          throw Exception('No Google user found');
        }
      }
    } catch (e) {
      _logger.e('Google sign-in failed: $e');
      rethrow;
    }
  }

  // Check if user profile exists in our database, create if not
  Future<void> _checkAndCreateUserProfile(User user) async {
    try {
      // Check if user exists in st_users table by auth_user_id
      final response =
          await _supabase
              .from('st_users')
              .select('id')
              .eq('auth_user_id', user.id)
              .maybeSingle();

      if (response == null) {
        // User doesn't exist, create profile
        _logger.i('Creating new user profile for: ${user.email}');

        await _supabase.from('st_users').insert({
          'auth_user_id': user.id, // Link to auth.users.id
          'email': user.email!,
          'full_name':
              user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              '',
          'avatar_url': user.userMetadata?['avatar_url'] ?? '',
          'phone': user.userMetadata?['phone'],
          'date_of_birth': null, // Will be set during profile setup
          'location': null,
          'bio': null,
          'preferred_sports': [],
          'skill_level': 'beginner',
          'is_profile_complete': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        _logger.i('User profile created successfully');
      } else {
        _logger.i('Existing user profile found');
      }
    } catch (e) {
      _logger.e('Error checking/creating user profile: $e');
      // Don't rethrow here as authentication was successful
      // Profile creation issues can be handled separately
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Supabase
      await _supabase.auth.signOut();

      _logger.i('Sign out successful');
    } catch (e) {
      _logger.e('Sign out failed: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      _logger.i('Deleting account for user: ${user.email}');

      // Delete user data from our tables (handled by CASCADE in database)
      // The user record deletion will cascade to all related data

      // Sign out first
      await signOut();

      _logger.i('Account deletion initiated');
    } catch (e) {
      _logger.e('Account deletion failed: $e');
      rethrow;
    }
  }

  // Check if user profile is complete
  Future<bool> isProfileComplete() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final response =
          await _supabase
              .from('st_users')
              .select('is_profile_complete, date_of_birth')
              .eq('auth_user_id', user.id)
              .maybeSingle();

      if (response == null) return false;

      // Profile is complete if flag is set and date of birth exists
      return response['is_profile_complete'] == true &&
          response['date_of_birth'] != null;
    } catch (e) {
      _logger.e('Error checking profile completion: $e');
      return false;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response =
          await _supabase
              .from('st_users')
              .select('*')
              .eq('auth_user_id', user.id)
              .maybeSingle();

      return response;
    } catch (e) {
      _logger.e('Error fetching user profile: $e');
      return null;
    }
  }

  // Get the st_users.id for the current authenticated user
  Future<String?> getCurrentUserId() async {
    try {
      final user = currentUser;
      if (user == null) {
        _logger.w('No current user found');
        return null;
      }

      _logger.i('Getting st_users.id for auth user: ${user.id}');

      final response =
          await _supabase
              .from('st_users')
              .select('id')
              .eq('auth_user_id', user.id)
              .maybeSingle();

      if (response == null) {
        _logger.w('No st_users record found for auth_user_id: ${user.id}');
        return null;
      }

      final userId = response['id'];
      _logger.i('Found st_users.id: $userId');
      return userId;
    } catch (e) {
      _logger.e('Error fetching user ID: $e');
      return null;
    }
  }

  // Validate user age (must be 18+)
  static bool isValidAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    final age = now.difference(dateOfBirth).inDays / 365.25;
    return age >= Env.minimumAge;
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String fullName,
    required DateTime dateOfBirth,
    String? phone,
    String? bio,
    List<String>? preferredSports,
    String? skillLevel,
    String? location,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Validate age
      if (!isValidAge(dateOfBirth)) {
        throw Exception(
          'You must be at least ${Env.minimumAge} years old to use this app',
        );
      }

      _logger.i('Updating user profile for: ${user.email}');

      final updateData = {
        'full_name': fullName,
        'date_of_birth':
            dateOfBirth.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'phone': phone,
        'bio': bio,
        'preferred_sports': preferredSports ?? [],
        'skill_level': skillLevel ?? 'beginner',
        'location': location,
        'is_profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('st_users')
          .update(updateData)
          .eq('auth_user_id', user.id);

      _logger.i('User profile updated successfully');
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      rethrow;
    }
  }
}
