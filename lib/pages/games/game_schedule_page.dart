import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/game.dart';
import '../../models/team.dart';
import '../../services/game_service.dart';
import '../../services/auth_service.dart';
import '../../providers/team_provider.dart';

class GameSchedulePage extends ConsumerStatefulWidget {
  final String teamId;
  final Game? existingGame; // For editing

  const GameSchedulePage({super.key, required this.teamId, this.existingGame});

  @override
  ConsumerState<GameSchedulePage> createState() => _GameSchedulePageState();
}

class _GameSchedulePageState extends ConsumerState<GameSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _gameService = GameService();
  final _authService = AuthService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _feeController = TextEditingController();

  // Form state
  Sport _selectedSport = Sport.volleyball;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  int _durationMinutes = 120;
  int? _maxPlayers;
  bool _isPublic = false;
  bool _requiresRsvp = true;
  bool _autoConfirmRsvp = true;
  bool _weatherDependent = false;
  DateTime? _rsvpDeadline;
  List<String> _equipmentNeeded = [];
  double? _latitude;
  double? _longitude;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingGame != null) {
      final game = widget.existingGame!;
      _titleController.text = game.title;
      _descriptionController.text = game.description ?? '';
      _venueController.text = game.venue;
      _addressController.text = game.address ?? '';
      _notesController.text = game.notes ?? '';
      _feeController.text = game.feePerPlayer?.toStringAsFixed(2) ?? '';

      _selectedSport = Sport.values.firstWhere(
        (s) => s.name == game.sport.toLowerCase(),
        orElse: () => Sport.volleyball,
      );
      _selectedDate = DateTime(
        game.scheduledAt.year,
        game.scheduledAt.month,
        game.scheduledAt.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(game.scheduledAt);
      _durationMinutes = game.durationMinutes;
      _maxPlayers = game.maxPlayers;
      _isPublic = game.isPublic;
      _requiresRsvp = game.requiresRsvp;
      _autoConfirmRsvp = game.autoConfirmRsvp;
      _weatherDependent = game.weatherDependent;
      _rsvpDeadline = game.rsvpDeadline;
      _equipmentNeeded = List.from(game.equipmentNeeded);
      _latitude = game.latitude;
      _longitude = game.longitude;
    } else {
      // Set defaults for new game
      _maxPlayers = _selectedSport.defaultMaxPlayers;
      _feeController.text = _selectedSport.defaultFee.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectRsvpDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _rsvpDeadline?.toLocal() ?? _selectedDate,
      firstDate: DateTime.now(),
      lastDate: _selectedDate,
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime:
            _rsvpDeadline != null
                ? TimeOfDay.fromDateTime(_rsvpDeadline!)
                : const TimeOfDay(hour: 23, minute: 59),
      );

      if (pickedTime != null) {
        setState(() {
          _rsvpDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _onSportChanged(Sport sport) {
    setState(() {
      _selectedSport = sport;
      _maxPlayers = sport.defaultMaxPlayers;
      _feeController.text = sport.defaultFee.toStringAsFixed(2);
    });
  }

  void _addEquipment() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Equipment'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Equipment needed',
              hintText: 'e.g., Net, Ball, Cones',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _equipmentNeeded.add(controller.text.trim());
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectLocation() async {
    // For now, show a simple dialog to enter coordinates
    // In a real app, you'd integrate with Google Maps or similar
    showDialog(
      context: context,
      builder: (context) {
        final latController = TextEditingController(
          text: _latitude?.toString() ?? '',
        );
        final lngController = TextEditingController(
          text: _longitude?.toString() ?? '',
        );

        return AlertDialog(
          title: const Text('Set Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g., 40.7128',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g., -74.0060',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _latitude = double.tryParse(latController.text);
                  _longitude = double.tryParse(lngController.text);
                });
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGame() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final fee = double.tryParse(_feeController.text);

      if (widget.existingGame != null) {
        // Update existing game
        await _gameService.updateGame(
          widget.existingGame!.id,
          title: _titleController.text.trim(),
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
          venue: _venueController.text.trim(),
          address:
              _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          scheduledAt: scheduledAt,
          durationMinutes: _durationMinutes,
          maxPlayers: _maxPlayers,
          feePerPlayer: fee,
          isPublic: _isPublic,
          requiresRsvp: _requiresRsvp,
          autoConfirmRsvp: _autoConfirmRsvp,
          rsvpDeadline: _rsvpDeadline,
          weatherDependent: _weatherDependent,
          notes:
              _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
          equipmentNeeded: _equipmentNeeded,
        );
      } else {
        // Create new game
        await _gameService.createGame(
          teamId: widget.teamId,
          title: _titleController.text.trim(),
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
          sport: _selectedSport.name,
          venue: _venueController.text.trim(),
          address:
              _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          scheduledAt: scheduledAt,
          durationMinutes: _durationMinutes,
          maxPlayers: _maxPlayers ?? _selectedSport.defaultMaxPlayers,
          feePerPlayer: fee,
          isPublic: _isPublic,
          requiresRsvp: _requiresRsvp,
          autoConfirmRsvp: _autoConfirmRsvp,
          rsvpDeadline: _rsvpDeadline,
          weatherDependent: _weatherDependent,
          notes:
              _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
          equipmentNeeded: _equipmentNeeded,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingGame != null
                  ? 'Game updated successfully!'
                  : 'Game scheduled successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingGame != null ? 'Edit Game' : 'Schedule Game',
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveGame,
              child: Text(
                widget.existingGame != null ? 'Update' : 'Create',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Basic Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Game Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Game Title *',
                        hintText: 'e.g., Weekly Volleyball Match',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Game title is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sport Selection
                    DropdownButtonFormField<Sport>(
                      value: _selectedSport,
                      decoration: const InputDecoration(
                        labelText: 'Sport *',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          Sport.values.map((sport) {
                            return DropdownMenuItem(
                              value: sport,
                              child: Text('${sport.emoji} ${sport.display}'),
                            );
                          }).toList(),
                      onChanged: (sport) {
                        if (sport != null) {
                          _onSportChanged(sport);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional details about the game',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Selection
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(
                        DateFormat('EEEE, MMM d, y').format(_selectedDate),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectDate,
                    ),

                    // Time Selection
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Start Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectTime,
                    ),

                    // Duration
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('Duration'),
                      subtitle: Text('${_durationMinutes} minutes'),
                      trailing: SizedBox(
                        width: 100,
                        child: DropdownButton<int>(
                          value: _durationMinutes,
                          items:
                              [60, 90, 120, 150, 180, 240].map((minutes) {
                                return DropdownMenuItem(
                                  value: minutes,
                                  child: Text('${minutes}m'),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _durationMinutes = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Venue
                    TextFormField(
                      controller: _venueController,
                      decoration: const InputDecoration(
                        labelText: 'Venue Name *',
                        hintText: 'e.g., Central Park Courts',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Venue name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Full address for easy navigation',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Location Selection
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Set Coordinates'),
                      subtitle:
                          _latitude != null && _longitude != null
                              ? Text(
                                '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                              )
                              : const Text('Tap to set location for discovery'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectLocation,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Game Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Max Players
                    TextFormField(
                      initialValue: _maxPlayers?.toString(),
                      decoration: InputDecoration(
                        labelText: 'Max Players',
                        hintText:
                            'Default: ${_selectedSport.defaultMaxPlayers}',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        _maxPlayers = int.tryParse(value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Fee per Player
                    TextFormField(
                      controller: _feeController,
                      decoration: const InputDecoration(
                        labelText: 'Fee per Player (\$)',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Public Game Switch
                    SwitchListTile(
                      title: const Text('Public Game'),
                      subtitle: const Text(
                        'Allow non-team members to discover and join',
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),

                    // Weather Dependent Switch
                    SwitchListTile(
                      title: const Text('Weather Dependent'),
                      subtitle: const Text(
                        'Game may be cancelled due to weather',
                      ),
                      value: _weatherDependent,
                      onChanged: (value) {
                        setState(() {
                          _weatherDependent = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // RSVP Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RSVP Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Require RSVP Switch
                    SwitchListTile(
                      title: const Text('Require RSVP'),
                      subtitle: const Text(
                        'Players must RSVP to join the game',
                      ),
                      value: _requiresRsvp,
                      onChanged: (value) {
                        setState(() {
                          _requiresRsvp = value;
                        });
                      },
                    ),

                    if (_requiresRsvp) ...[
                      // Auto Confirm RSVP Switch
                      SwitchListTile(
                        title: const Text('Auto-confirm RSVPs'),
                        subtitle: const Text(
                          'Automatically accept RSVP responses',
                        ),
                        value: _autoConfirmRsvp,
                        onChanged: (value) {
                          setState(() {
                            _autoConfirmRsvp = value;
                          });
                        },
                      ),

                      // RSVP Deadline
                      ListTile(
                        leading: const Icon(Icons.event_available),
                        title: const Text('RSVP Deadline'),
                        subtitle:
                            _rsvpDeadline != null
                                ? Text(
                                  DateFormat(
                                    'MMM d, y • h:mm a',
                                  ).format(_rsvpDeadline!),
                                )
                                : const Text('Optional - tap to set'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_rsvpDeadline != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _rsvpDeadline = null;
                                  });
                                },
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: _selectRsvpDeadline,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Equipment & Notes Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equipment & Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Equipment Needed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Equipment Needed'),
                        TextButton.icon(
                          onPressed: _addEquipment,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),

                    if (_equipmentNeeded.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            _equipmentNeeded.map((equipment) {
                              return Chip(
                                label: Text(equipment),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _equipmentNeeded.remove(equipment);
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        hintText: 'Any special instructions or information',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          widget.existingGame != null
                              ? 'Update Game'
                              : 'Schedule Game',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
