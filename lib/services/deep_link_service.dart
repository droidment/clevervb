import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  static final _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _logger = Logger();
  final _supabase = Supabase.instance.client;

  // Base URL for the app (you'll need to configure this)
  static const String _baseUrl =
      'https://clevervb.app'; // Replace with your actual domain
  static const String _fallbackUrl =
      'https://github.com/droidment/clevervb'; // Fallback to repo

  // ==================== GAME INVITE LINKS ====================

  /// Generate a deep link for a game
  String generateGameInviteLink(String gameId) {
    return '$_baseUrl/game/$gameId';
  }

  /// Generate a shareable message for a game invite
  Future<String> generateGameInviteMessage(String gameId) async {
    try {
      final response =
          await _supabase
              .from('st_games')
              .select('''
            title, sport, venue, scheduled_at,
            st_teams!inner(name),
            st_users!st_games_organizer_id_fkey(full_name)
          ''')
              .eq('id', gameId)
              .single();

      final title = response['title'] as String;
      final sport = response['sport'] as String;
      final venue = response['venue'] as String;
      final scheduledAt = DateTime.parse(response['scheduled_at'] as String);
      final teamName = response['st_teams']['name'] as String;
      final organizerName = response['st_users']['full_name'] as String;

      final dateStr = _formatDateTime(scheduledAt);
      final sportEmoji = _getSportEmoji(sport);

      final link = generateGameInviteLink(gameId);

      return '''$sportEmoji Join us for $sport!

📅 $title
🏟️ $venue
⏰ $dateStr
👥 Team: $teamName
🎯 Organized by $organizerName

Tap to join: $link

#$sport #CleverVB''';
    } catch (e) {
      _logger.e('Error generating game invite message: $e');
      return 'Join our game! ${generateGameInviteLink(gameId)}';
    }
  }

  /// Share game invite via WhatsApp
  Future<void> shareGameViaWhatsApp(
    String gameId, {
    String? phoneNumber,
  }) async {
    try {
      final message = await generateGameInviteMessage(gameId);
      await shareViaWhatsApp(message, phoneNumber: phoneNumber);
    } catch (e) {
      _logger.e('Error sharing game via WhatsApp: $e');
      rethrow;
    }
  }

  /// Share game invite via native share
  Future<void> shareGameInvite(String gameId) async {
    try {
      final message = await generateGameInviteMessage(gameId);
      await Share.share(message, subject: 'Join our game!');
    } catch (e) {
      _logger.e('Error sharing game invite: $e');
      rethrow;
    }
  }

  // ==================== TEAM INVITE LINKS ====================

  /// Generate a deep link for a team invite
  String generateTeamInviteLink(String teamId, String inviteToken) {
    return '$_baseUrl/team/$teamId/join?token=$inviteToken';
  }

  /// Generate a shareable message for a team invite
  Future<String> generateTeamInviteMessage(
    String teamId,
    String inviteToken,
  ) async {
    try {
      final response =
          await _supabase
              .from('st_teams')
              .select('''
            name, sport_type, description, location,
            st_users!st_teams_organizer_id_fkey(full_name)
          ''')
              .eq('id', teamId)
              .single();

      final teamName = response['name'] as String;
      final sport = response['sport_type'] as String;
      final description = response['description'] as String?;
      final location = response['location'] as String?;
      final organizerName = response['st_users']['full_name'] as String;

      final sportEmoji = _getSportEmoji(sport);
      final link = generateTeamInviteLink(teamId, inviteToken);

      return '''$sportEmoji Join our team!

🏆 $teamName
🎯 Sport: $sport
👤 Organizer: $organizerName${location != null ? '\n📍 $location' : ''}${description != null ? '\n\n$description' : ''}

Tap to join: $link

#$sport #CleverVB''';
    } catch (e) {
      _logger.e('Error generating team invite message: $e');
      return 'Join our team! ${generateTeamInviteLink(teamId, inviteToken)}';
    }
  }

  /// Share team invite via WhatsApp
  Future<void> shareTeamViaWhatsApp(
    String teamId,
    String inviteToken, {
    String? phoneNumber,
  }) async {
    try {
      final message = await generateTeamInviteMessage(teamId, inviteToken);
      await shareViaWhatsApp(message, phoneNumber: phoneNumber);
    } catch (e) {
      _logger.e('Error sharing team via WhatsApp: $e');
      rethrow;
    }
  }

  /// Share team invite via native share
  Future<void> shareTeamInvite(String teamId, String inviteToken) async {
    try {
      final message = await generateTeamInviteMessage(teamId, inviteToken);
      await Share.share(message, subject: 'Join our team!');
    } catch (e) {
      _logger.e('Error sharing team invite: $e');
      rethrow;
    }
  }

  // ==================== WHATSAPP INTEGRATION ====================

  /// Share message via WhatsApp
  Future<void> shareViaWhatsApp(String message, {String? phoneNumber}) async {
    try {
      String url;

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Clean phone number (remove non-digits)
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';
      } else {
        url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to native share
        await Share.share(message);
      }
    } catch (e) {
      _logger.e('Error sharing via WhatsApp: $e');
      // Fallback to native share
      await Share.share(message);
    }
  }

  // ==================== DEEP LINK HANDLING ====================

  /// Handle incoming deep link for game
  Future<Map<String, dynamic>?> handleGameDeepLink(String gameId) async {
    try {
      _logger.i('Handling game deep link: $gameId');

      // Get game details
      final response =
          await _supabase
              .from('st_games')
              .select('''
            id, title, sport, is_public, requires_rsvp,
            st_teams!inner(id, name, is_public)
          ''')
              .eq('id', gameId)
              .single();

      return {'type': 'game', 'id': gameId, 'data': response};
    } catch (e) {
      _logger.e('Error handling game deep link: $e');
      return null;
    }
  }

  /// Handle incoming deep link for team
  Future<Map<String, dynamic>?> handleTeamDeepLink(
    String teamId,
    String? inviteToken,
  ) async {
    try {
      _logger.i('Handling team deep link: $teamId with token: $inviteToken');

      if (inviteToken != null) {
        // Validate invite token
        final inviteResponse =
            await _supabase
                .from('st_invitations')
                .select('*')
                .eq('team_id', teamId)
                .eq('invite_token', inviteToken)
                .eq('status', 'pending')
                .gt('expires_at', DateTime.now().toIso8601String())
                .maybeSingle();

        if (inviteResponse == null) {
          throw Exception('Invalid or expired invite link');
        }
      }

      // Get team details
      final response =
          await _supabase
              .from('st_teams')
              .select('''
            id, name, sport_type, description, is_public,
            st_users!st_teams_organizer_id_fkey(full_name)
          ''')
              .eq('id', teamId)
              .single();

      return {
        'type': 'team',
        'id': teamId,
        'inviteToken': inviteToken,
        'data': response,
      };
    } catch (e) {
      _logger.e('Error handling team deep link: $e');
      return null;
    }
  }

  /// Auto-join user to team via deep link
  Future<void> autoJoinTeamViaDeepLink(
    String teamId,
    String inviteToken,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to join team');
      }

      _logger.i('Auto-joining user to team: $teamId');

      // Validate and consume invite
      final inviteResponse =
          await _supabase
              .from('st_invitations')
              .select('*')
              .eq('team_id', teamId)
              .eq('invite_token', inviteToken)
              .eq('status', 'pending')
              .gt('expires_at', DateTime.now().toIso8601String())
              .single();

      // Add user to team
      await _supabase.from('st_team_members').insert({
        'team_id': teamId,
        'user_id': user.id,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Mark invitation as used
      await _supabase
          .from('st_invitations')
          .update({
            'status': 'accepted',
            'accepted_by': user.id,
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', inviteResponse['id']);

      _logger.i('User successfully joined team via deep link');
    } catch (e) {
      _logger.e('Error auto-joining team via deep link: $e');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Format date time for sharing
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final gameDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (gameDate == today) {
      dateStr = 'Today';
    } else if (gameDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr =
          '${_getWeekday(dateTime.weekday)}, ${_getMonth(dateTime.month)} ${dateTime.day}';
    }

    final timeStr =
        '${dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';

    return '$dateStr at $timeStr';
  }

  /// Get sport emoji
  String _getSportEmoji(String sport) {
    switch (sport.toLowerCase()) {
      case 'volleyball':
        return '🏐';
      case 'pickleball':
        return '🏓';
      case 'basketball':
        return '🏀';
      case 'tennis':
        return '🎾';
      case 'badminton':
        return '🏸';
      case 'soccer':
        return '⚽';
      default:
        return '🏅';
    }
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Copy text to clipboard
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Open URL in browser
  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $url');
    }
  }
}
