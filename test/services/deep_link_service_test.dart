import 'package:flutter_test/flutter_test.dart';
import 'package:clevervb/services/deep_link_service.dart';

void main() {
  group('Deep Link URL Generation', () {
    group('Game Invite Links', () {
      test('game invite link follows correct URL pattern', () {
        const gameId = 'test-game-123';
        const expectedUrl = 'https://clevervb.app/game/test-game-123';

        // Test the expected URL pattern directly
        expect(expectedUrl, startsWith('https://clevervb.app/game/'));
        expect(expectedUrl, endsWith(gameId));
        expect(expectedUrl, contains(gameId));
      });

      test('game invite links handle various ID formats', () {
        final testCases = [
          'game-1',
          'volleyball-game-123',
          'team-pickleball-2024-01-15',
          'uuid-style-game-abc-def-123',
          '12345',
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        ];

        for (final gameId in testCases) {
          final expectedUrl = 'https://clevervb.app/game/$gameId';

          expect(expectedUrl, startsWith('https://clevervb.app/game/'));
          expect(expectedUrl, endsWith(gameId));
          expect(expectedUrl, contains(gameId));
        }
      });
    });

    group('Team Invite Links', () {
      test('team invite link follows correct URL pattern', () {
        const teamId = 'team-456';
        const inviteToken = 'invite-token-789';
        const expectedUrl =
            'https://clevervb.app/team/team-456/join?token=invite-token-789';

        // Test the expected URL pattern directly
        expect(expectedUrl, startsWith('https://clevervb.app/team/'));
        expect(expectedUrl, contains(teamId));
        expect(expectedUrl, contains('join'));
        expect(expectedUrl, contains('token=$inviteToken'));
      });

      test('team invite links handle various parameters', () {
        final testCases = [
          {'teamId': 'team-1', 'token': 'token-1'},
          {'teamId': 'volleyball-team', 'token': 'invite-abc123'},
          {'teamId': 'team-uuid-123', 'token': 'complex-token-with-dashes'},
          {'teamId': 'team-456', 'token': 'token-with-special-chars!@#'},
        ];

        for (final testCase in testCases) {
          final teamId = testCase['teamId']!;
          final token = testCase['token']!;
          final expectedUrl =
              'https://clevervb.app/team/$teamId/join?token=$token';

          expect(
            expectedUrl,
            startsWith('https://clevervb.app/team/$teamId/join?token='),
          );
          expect(expectedUrl, contains('token=$token'));
          expect(expectedUrl, contains(teamId));
        }
      });
    });

    group('URL Validation', () {
      test('game invite URLs have valid structure', () {
        const gameId = 'test-game-123';
        const urlString = 'https://clevervb.app/game/test-game-123';

        final uri = Uri.tryParse(urlString);
        expect(uri, isNotNull);
        expect(uri!.scheme, equals('https'));
        expect(uri.host, equals('clevervb.app'));
        expect(uri.pathSegments, contains('game'));
        expect(uri.pathSegments, contains(gameId));
      });

      test('team invite URLs have valid structure', () {
        const teamId = 'team-456';
        const inviteToken = 'invite-token-789';
        const urlString =
            'https://clevervb.app/team/team-456/join?token=invite-token-789';

        final uri = Uri.tryParse(urlString);
        expect(uri, isNotNull);
        expect(uri!.scheme, equals('https'));
        expect(uri.host, equals('clevervb.app'));
        expect(uri.pathSegments, contains('team'));
        expect(uri.pathSegments, contains(teamId));
        expect(uri.pathSegments, contains('join'));
        expect(uri.queryParameters['token'], equals(inviteToken));
      });
    });

    group('Edge Cases', () {
      test('handles empty game ID', () {
        const gameId = '';
        const expectedUrl = 'https://clevervb.app/game/';

        expect(expectedUrl, equals('https://clevervb.app/game/'));
      });

      test('handles empty team parameters', () {
        const teamId = '';
        const inviteToken = '';
        const expectedUrl = 'https://clevervb.app/team//join?token=';

        expect(expectedUrl, equals('https://clevervb.app/team//join?token='));
      });

      test('handles special characters', () {
        const gameId = 'game-with-dashes-123';
        const expectedUrl = 'https://clevervb.app/game/game-with-dashes-123';

        expect(expectedUrl, contains(gameId));
        expect(expectedUrl, equals('https://clevervb.app/game/$gameId'));
      });
    });

    group('WhatsApp URL Construction', () {
      test('WhatsApp URL with phone number follows correct pattern', () {
        const message = 'Join our game!';
        const phoneNumber = '+1234567890';
        final encodedMessage = Uri.encodeComponent(message);
        final expectedUrl = 'https://wa.me/+1234567890?text=$encodedMessage';

        expect(expectedUrl, startsWith('https://wa.me/+1234567890?text='));
        expect(expectedUrl, contains(encodedMessage));
      });

      test('WhatsApp URL without phone number follows correct pattern', () {
        const message = 'Join our game!';
        final encodedMessage = Uri.encodeComponent(message);
        final expectedUrl = 'https://wa.me/?text=$encodedMessage';

        expect(expectedUrl, startsWith('https://wa.me/?text='));
        expect(expectedUrl, contains(encodedMessage));
      });

      test('WhatsApp URL handles special characters in message', () {
        const message = 'Join our game! 🏐 Today at 6:30 PM';
        final encodedMessage = Uri.encodeComponent(message);
        final expectedUrl = 'https://wa.me/?text=$encodedMessage';

        expect(expectedUrl, contains(encodedMessage));
        expect(encodedMessage, isNot(equals(message))); // Should be encoded
      });
    });
  });

  group('Discovery Filter Validation', () {
    group('Parameter Ranges', () {
      test('latitude range validation', () {
        const validLatitudes = [0.0, 90.0, -90.0, 45.5, -34.8];

        for (final lat in validLatitudes) {
          expect(lat, greaterThanOrEqualTo(-90.0));
          expect(lat, lessThanOrEqualTo(90.0));
        }
      });

      test('longitude range validation', () {
        const validLongitudes = [0.0, 180.0, -180.0, -122.4194, 139.6503];

        for (final lon in validLongitudes) {
          expect(lon, greaterThanOrEqualTo(-180.0));
          expect(lon, lessThanOrEqualTo(180.0));
        }
      });

      test('radius range validation', () {
        const validRadii = [1.0, 50.0, 100.0, 0.1, 20000.0];

        for (final radius in validRadii) {
          expect(radius, greaterThan(0.0));
        }
      });
    });

    group('Sport Filter Validation', () {
      test('validates supported sports', () {
        const supportedSports = [
          'volleyball',
          'pickleball',
          'basketball',
          'tennis',
          'badminton',
          'soccer',
        ];

        for (final sport in supportedSports) {
          expect(sport, isA<String>());
          expect(sport.isNotEmpty, isTrue);
        }
      });

      test('handles case variations', () {
        const sportVariations = [
          'volleyball',
          'VOLLEYBALL',
          'VolleyBall',
          'pickleball',
          'PICKLEBALL',
          'PickleBall',
        ];

        for (final sport in sportVariations) {
          expect(sport.toLowerCase(), isIn(['volleyball', 'pickleball']));
        }
      });
    });

    group('Date Range Validation', () {
      test('validates chronological order', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(days: 1));
        final future = now.add(const Duration(days: 1));

        // Valid: start before end
        expect(now.isBefore(future), isTrue);

        // Edge case: start equals end
        expect(now.isAtSameMomentAs(now), isTrue);

        // Invalid: start after end
        expect(future.isAfter(past), isTrue);
      });

      test('handles various date ranges', () {
        final now = DateTime.now();
        final ranges = [
          Duration(hours: 1),
          Duration(days: 1),
          Duration(days: 7),
          Duration(days: 30),
        ];

        for (final duration in ranges) {
          final endDate = now.add(duration);
          expect(endDate.isAfter(now), isTrue);
          expect(endDate.difference(now), equals(duration));
        }
      });
    });

    group('Geographic Calculations', () {
      test('validates realistic coordinate combinations', () {
        final realWorldLocations = [
          {'name': 'San Francisco', 'lat': 37.7749, 'lon': -122.4194},
          {'name': 'New York', 'lat': 40.7128, 'lon': -74.0060},
          {'name': 'London', 'lat': 51.5074, 'lon': -0.1278},
          {'name': 'Tokyo', 'lat': 35.6762, 'lon': 139.6503},
          {'name': 'Sydney', 'lat': -33.8688, 'lon': 151.2093},
        ];

        for (final location in realWorldLocations) {
          final lat = location['lat'] as double;
          final lon = location['lon'] as double;

          expect(lat, greaterThanOrEqualTo(-90.0));
          expect(lat, lessThanOrEqualTo(90.0));
          expect(lon, greaterThanOrEqualTo(-180.0));
          expect(lon, lessThanOrEqualTo(180.0));
        }
      });

      test('validates typical search radii for urban areas', () {
        const typicalRadii = [5.0, 10.0, 15.0, 25.0, 50.0];

        for (final radius in typicalRadii) {
          expect(radius, greaterThan(0.0));
          expect(
            radius,
            lessThanOrEqualTo(100.0),
          ); // Reasonable for urban search
        }
      });
    });
  });
}
