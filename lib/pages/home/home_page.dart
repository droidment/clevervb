import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../teams/teams_page.dart';
import '../discovery_page.dart';
import 'dashboard_page.dart';
import '../profile/profile_page.dart';
import '../organizer/organizer_dashboard_page.dart';
import '../../providers/auth_provider.dart';
import '../../services/game_service.dart';
import '../../services/auth_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();
  bool _hasOrganizedGames = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOrganizerStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh organizer status when app comes back to foreground
      _checkOrganizerStatus();
    }
  }

  Future<void> _checkOrganizerStatus() async {
    print('🔍 Checking organizer status...');
    final asyncUser = ref.read(currentUserProvider);
    final user = asyncUser.value;

    if (user != null) {
      print('✅ User found: ${user.email}');
      try {
        // Get the st_users.id instead of auth.users.id
        final currentUserId = await _authService.getCurrentUserId();
        print('📍 Current user ID: $currentUserId');

        if (currentUserId != null) {
          final games = await _gameService.getOrganizerGames(currentUserId);
          print('🎮 Found ${games.length} organized games');

          if (games.isNotEmpty) {
            print('🎯 Games organized by user:');
            for (final game in games) {
              print('  - ${game.title} (${game.id})');
            }
          }

          if (mounted) {
            setState(() {
              _hasOrganizedGames = games.isNotEmpty;
            });
            print(
              '🚀 Navigation updated - hasOrganizedGames: $_hasOrganizedGames',
            );
          }
        } else {
          print('❌ No user ID found');
        }
      } catch (e) {
        print('💥 Error checking organizer status: $e');
        // If there's an error, assume no organized games
        if (mounted) {
          setState(() {
            _hasOrganizedGames = false;
          });
        }
      }
    } else {
      print('❌ No user logged in');
    }
  }

  List<Widget> get _pages {
    final basePages = [
      const DashboardPage(),
      const TeamsPage(),
      const DiscoveryPage(),
      const ProfilePage(),
    ];

    if (_hasOrganizedGames) {
      basePages.insert(
        3,
        const OrganizerDashboardPage(),
      ); // Insert before Profile
    }

    return basePages;
  }

  List<NavigationDestination> get _destinations {
    final baseDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(icon: Icon(Icons.group), label: 'Teams'),
      const NavigationDestination(icon: Icon(Icons.explore), label: 'Games'),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
    ];

    if (_hasOrganizedGames) {
      baseDestinations.insert(
        3,
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Organizer',
        ),
      ); // Insert before Profile
    }

    return baseDestinations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: _destinations,
      ),
    );
  }
}
