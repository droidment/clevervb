import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../models/game.dart';
import '../services/game_service.dart';
import '../services/deep_link_service.dart';
import '../providers/auth_provider.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({super.key});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  final _gameService = GameService();
  final _deepLinkService = DeepLinkService();
  final _searchController = TextEditingController();

  List<Game> _discoveredGames = [];
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String? _errorMessage;

  // Filter state
  String? _selectedSport;
  double _radiusKm = 25.0;
  DateTime? _startDate;
  DateTime? _endDate;
  Position? _currentPosition;
  String? _currentAddress;

  // Sport options
  final List<String> _sportOptions = [
    'volleyball',
    'pickleball',
    'basketball',
    'tennis',
    'badminton',
    'soccer',
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check location permission
      var permission = await Permission.location.status;
      if (permission.isDenied) {
        permission = await Permission.location.request();
      }

      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        // Get address from coordinates
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final address =
              '${placemark.locality}, ${placemark.administrativeArea}';

          setState(() {
            _currentPosition = position;
            _currentAddress = address;
          });

          // Reload games with location
          _loadGames();
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final games = await _gameService.discoverGames(
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        radiusKm: _radiusKm,
        sport: _selectedSport,
        startDate: _startDate,
        endDate: _endDate,
        limit: 50,
      );

      setState(() {
        _discoveredGames = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load games: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadGames();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadGames();
  }

  Future<void> _rsvpToGame(Game game, RsvpResponse response) async {
    try {
      await _gameService.rsvpToGame(game.id, response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RSVP ${response.display} submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload games to update RSVP counts
        _loadGames();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit RSVP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareGame(Game game) async {
    try {
      await _deepLinkService.shareGameInvite(game.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareGameViaWhatsApp(Game game) async {
    try {
      await _deepLinkService.shareGameViaWhatsApp(game.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share via WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover Games'), elevation: 0),
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(),

          // Games List
          Expanded(child: _buildGamesList()),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location display
          if (_isLoadingLocation)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Getting your location...'),
              ],
            )
          else if (_currentAddress != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Near $_currentAddress',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: _initializeLocation,
                  child: const Text('Refresh'),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.location_off, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                const Text('Location not available'),
                TextButton(
                  onPressed: _initializeLocation,
                  child: const Text('Enable'),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Filter row
          Row(
            children: [
              // Sport filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSport,
                  decoration: const InputDecoration(
                    labelText: 'Sport',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Sports'),
                    ),
                    ..._sportOptions.map(
                      (sport) => DropdownMenuItem(
                        value: sport,
                        child: Text(sport.capitalize()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSport = value);
                    _loadGames();
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Date range filter
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Range',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                              : 'Any time',
                          style: TextStyle(
                            color: _startDate != null ? null : Colors.grey[600],
                          ),
                        ),
                        if (_startDate != null)
                          GestureDetector(
                            onTap: _clearDateRange,
                            child: const Icon(Icons.clear, size: 18),
                          )
                        else
                          const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Radius slider
          Row(
            children: [
              const Text('Radius: '),
              Text(
                '${_radiusKm.round()} km',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() => _radiusKm = value);
                  },
                  onChangeEnd: (value) {
                    _loadGames();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadGames, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_discoveredGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No games found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or expanding your search radius',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadGames, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGames,
      child: ListView.builder(
        itemCount: _discoveredGames.length,
        itemBuilder: (context, index) {
          final game = _discoveredGames[index];
          return _GameDiscoveryCard(
            game: game,
            onRsvp: _rsvpToGame,
            onShare: _shareGame,
            onShareWhatsApp: _shareGameViaWhatsApp,
          );
        },
      ),
    );
  }
}

class _GameDiscoveryCard extends StatelessWidget {
  final Game game;
  final Function(Game, RsvpResponse) onRsvp;
  final Function(Game) onShare;
  final Function(Game) onShareWhatsApp;

  const _GameDiscoveryCard({
    required this.game,
    required this.onRsvp,
    required this.onShare,
    required this.onShareWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sport and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSportColor(game.sport).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.sport.capitalize(),
                    style: TextStyle(
                      color: _getSportColor(game.sport),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),

                // Share buttons
                PopupMenuButton<String>(
                  icon: const Icon(Icons.share, size: 20),
                  onSelected: (value) {
                    switch (value) {
                      case 'share':
                        onShare(game);
                        break;
                      case 'whatsapp':
                        onShareWhatsApp(game);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'whatsapp',
                          child: Row(
                            children: [
                              Icon(Icons.chat, color: Colors.green),
                              SizedBox(width: 8),
                              Text('WhatsApp'),
                            ],
                          ),
                        ),
                      ],
                ),

                const SizedBox(width: 8),

                if (game.status != 'scheduled')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(game.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      game.statusDisplay,
                      style: TextStyle(
                        color: _getStatusColor(game.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Game title and team
            Text(
              game.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            if (game.teamName != null) ...[
              const SizedBox(height: 4),
              Text(
                'by ${game.teamName}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],

            const SizedBox(height: 12),

            // Date, time, and venue
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y • h:mm a').format(game.scheduledAt),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(game.venue, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Players and fee info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        !game.isFull
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${game.rsvpCount ?? 0}/${game.maxPlayers} players',
                    style: TextStyle(
                      color:
                          !game.isFull ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                if (game.feePerPlayer != null && game.feePerPlayer! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${game.feePerPlayer!.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            if (game.description != null && game.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                game.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),

            // RSVP buttons
            if (game.isRsvpOpen) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onRsvp(game, RsvpResponse.no),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Can\'t Go'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          !game.isFull
                              ? () => onRsvp(game, RsvpResponse.yes)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(!game.isFull ? 'Join Game' : 'Full'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'RSVP Closed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSportColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'volleyball':
        return Colors.orange;
      case 'pickleball':
        return Colors.green;
      case 'basketball':
        return Colors.deepOrange;
      case 'tennis':
        return Colors.blue;
      case 'badminton':
        return Colors.purple;
      case 'soccer':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'postponed':
      case 'in progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
