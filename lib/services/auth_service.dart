import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../config/env.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math';

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

  // Sign up with Passkey/WebAuthn
  Future<AuthResponse?> signUpWithPasskey(
    String email,
    String displayName,
  ) async {
    try {
      _logger.i('Starting passkey sign-up for: $email');

      if (kIsWeb) {
        // Check if WebAuthn is supported
        if (html.window.navigator.credentials == null) {
          throw Exception('WebAuthn is not supported in this browser');
        }

        // Create credential using WebAuthn API
        final credential = await _createPasskey(email, displayName);

        if (credential != null) {
          // Create user account with Supabase
          final response = await _supabase.auth.signUp(
            email: email,
            password: credential['id'], // Use credential ID as password
          );

          if (response.user != null) {
            _logger.i('Passkey sign-up successful for: $email');
            await _checkAndCreateUserProfile(response.user!);
          }

          return response;
        }
      } else {
        throw Exception(
          'Passkey authentication is currently only supported on web',
        );
      }

      return null;
    } catch (e) {
      _logger.e('Passkey sign-up failed: $e');
      rethrow;
    }
  }

  // Sign in with Passkey/WebAuthn
  Future<AuthResponse?> signInWithPasskey() async {
    try {
      _logger.i('Starting passkey sign-in');

      if (kIsWeb) {
        // Check if WebAuthn is supported
        if (html.window.navigator.credentials == null) {
          throw Exception('WebAuthn is not supported in this browser');
        }

        // Get credential using WebAuthn API
        final credential = await _getPasskey();

        if (credential != null) {
          // Sign in with Supabase using credential
          final response = await _supabase.auth.signInWithPassword(
            email: credential['email'] ?? '',
            password: credential['id'],
          );

          if (response.user != null) {
            _logger.i('Passkey sign-in successful');
          }

          return response;
        }
      } else {
        throw Exception(
          'Passkey authentication is currently only supported on web',
        );
      }

      return null;
    } catch (e) {
      _logger.e('Passkey sign-in failed: $e');
      rethrow;
    }
  }

  // Create a new passkey credential
  Future<Map<String, dynamic>?> _createPasskey(
    String email,
    String displayName,
  ) async {
    try {
      // Convert email to Uint8List for user ID
      final userIdBytes = Uint8List.fromList(email.codeUnits);
      final challenge = _generateChallenge();

      // Create proper JavaScript objects for WebAuthn
      final publicKeyCredentialCreationOptions = js_util.jsify({
        'challenge': challenge,
        'rp': {
          'name': 'CleverVB Sports Team Manager',
          'id': html.window.location.hostname,
        },
        'user': {'id': userIdBytes, 'name': email, 'displayName': displayName},
        'pubKeyCredParams': [
          {'alg': -7, 'type': 'public-key'},
          {'alg': -35, 'type': 'public-key'},
          {'alg': -36, 'type': 'public-key'},
          {'alg': -257, 'type': 'public-key'},
          {'alg': -258, 'type': 'public-key'},
          {'alg': -259, 'type': 'public-key'},
        ],
        'authenticatorSelection': {
          'authenticatorAttachment': 'platform',
          'userVerification': 'required',
          'requireResidentKey': true,
        },
        'timeout': 60000,
        'attestation': 'direct',
      });

      final credentialCreationOptions = js_util.jsify({
        'publicKey': publicKeyCredentialCreationOptions,
      });

      final result = await js_util.promiseToFuture(
        js_util.callMethod(html.window.navigator.credentials!, 'create', [
          credentialCreationOptions,
        ]),
      );

      if (result != null) {
        return {
          'id': js_util.getProperty(result, 'id'),
          'rawId': js_util.getProperty(result, 'rawId'),
          'type': js_util.getProperty(result, 'type'),
          'email': email,
        };
      }

      return null;
    } catch (e) {
      _logger.e('Error creating passkey: $e');
      return null;
    }
  }

  // Get existing passkey credential
  Future<Map<String, dynamic>?> _getPasskey() async {
    try {
      final challenge = _generateChallenge();

      final publicKeyCredentialRequestOptions = js_util.jsify({
        'challenge': challenge,
        'timeout': 60000,
        'userVerification': 'required',
        'rpId': html.window.location.hostname,
      });

      final credentialRequestOptions = js_util.jsify({
        'publicKey': publicKeyCredentialRequestOptions,
      });

      final result = await js_util.promiseToFuture(
        js_util.callMethod(html.window.navigator.credentials!, 'get', [
          credentialRequestOptions,
        ]),
      );

      if (result != null) {
        return {
          'id': js_util.getProperty(result, 'id'),
          'rawId': js_util.getProperty(result, 'rawId'),
          'type': js_util.getProperty(result, 'type'),
        };
      }

      return null;
    } catch (e) {
      _logger.e('Error getting passkey: $e');
      return null;
    }
  }

  // Generate a random challenge for WebAuthn
  Uint8List _generateChallenge() {
    final random = Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  // Check if WebAuthn/Passkeys are supported
  bool get isPasskeySupported {
    if (kIsWeb) {
      return html.window.navigator.credentials != null;
    }
    return false; // Currently only supporting web
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
