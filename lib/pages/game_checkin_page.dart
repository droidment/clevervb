import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../widgets/game_checkin_widget.dart';
import '../services/game_service.dart';

class GameCheckinPage extends ConsumerStatefulWidget {
  final String gameId;

  const GameCheckinPage({super.key, required this.gameId});

  @override
  ConsumerState<GameCheckinPage> createState() => _GameCheckinPageState();
}

class _GameCheckinPageState extends ConsumerState<GameCheckinPage> {
  final _gameService = GameService();
  Game? _game;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    setState(() => _isLoading = true);

    try {
      final game = await _gameService.getGame(widget.gameId);
      setState(() => _game = game);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_game?.title ?? 'Game Check-in'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _game == null
              ? const Center(
                child: Text('Game not found', style: TextStyle(fontSize: 18)),
              )
              : RefreshIndicator(
                onRefresh: _loadGame,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: GameCheckinWidget(
                    game: _game!,
                    onCheckinChanged: _loadGame,
                  ),
                ),
              ),
    );
  }
}
