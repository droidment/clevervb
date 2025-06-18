import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart' as models;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _profileService = ProfileService();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  // Form state
  DateTime? _selectedDateOfBirth;
  String _selectedSkillLevel = 'beginner';
  List<String> _selectedSports = [];
  models.User? _currentProfile;
  Map<String, dynamic>? _userStats;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _currentProfile = profile;
          _fullNameController.text = profile.fullName;
          _phoneController.text = profile.phone ?? '';
          _locationController.text = profile.location ?? '';
          _bioController.text = profile.bio ?? '';
          _selectedDateOfBirth = profile.dateOfBirth;
          _selectedSkillLevel = profile.skillLevel;
          // Normalize sports casing to match available sports list
          _selectedSports =
              profile.preferredSports.map((sport) {
                // Find the matching sport from available sports (case-insensitive)
                final availableSports = _profileService.getAvailableSports();
                final matchingSport = availableSports.firstWhere(
                  (available) => available.toLowerCase() == sport.toLowerCase(),
                  orElse: () => sport, // Keep original if no match found
                );
                return matchingSport;
              }).toList();
        });

        // Load user stats
        final stats = await _profileService.getUserStats(profile.id);
        setState(() => _userStats = stats);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _profileService.updateProfile(
        fullName: _fullNameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        dateOfBirth: _selectedDateOfBirth,
        location:
            _locationController.text.isEmpty ? null : _locationController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        preferredSports: _selectedSports,
        skillLevel: _selectedSkillLevel,
      );

      await _loadUserProfile();
      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        // Handle web vs mobile file handling
        dynamic imageFile;
        if (kIsWeb) {
          // On web, read as bytes
          imageFile = await image.readAsBytes();
        } else {
          // On mobile, use File
          imageFile = File(image.path);
        }

        await _profileService.updateAvatar(imageFile);
        await _loadUserProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // Must be 18+
      helpText: 'Select your date of birth',
    );

    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            backgroundImage:
                _currentProfile?.avatarUrl != null &&
                        _currentProfile!.avatarUrl!.isNotEmpty
                    ? NetworkImage(_currentProfile!.avatarUrl!)
                    : null,
            child:
                _currentProfile?.avatarUrl == null ||
                        _currentProfile!.avatarUrl!.isEmpty
                    ? Text(
                      _currentProfile?.initials ?? '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _isLoading ? null : _updateAvatar,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    if (_currentProfile == null) return const SizedBox();

    return Column(
      children: [
        Text(
          _currentProfile!.fullName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _currentProfile!.email,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        if (_currentProfile!.location != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _currentProfile!.location!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getSkillLevelColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getSkillLevelColor()),
          ),
          child: Text(
            _currentProfile!.skillLevelDisplay,
            style: TextStyle(
              color: _getSkillLevelColor(),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSkillLevelColor() {
    switch (_currentProfile?.skillLevel) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatsSection() {
    if (_userStats == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stats',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Games Attended',
                    _userStats!['total_games_attended'].toString(),
                    Icons.sports_basketball,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Game Hours',
                    '${_userStats!['total_game_hours']}h',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Teams Joined',
                    _userStats!['teams_joined'].toString(),
                    Icons.group,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Attendance Rate',
                    '${_userStats!['attendance_rate']}%',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDateOfBirth,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDateOfBirth != null
                    ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                    : 'Select date of birth',
                style: TextStyle(
                  color: _selectedDateOfBirth != null ? null : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSkillLevel,
            decoration: const InputDecoration(
              labelText: 'Skill Level',
              prefixIcon: Icon(Icons.trending_up),
            ),
            items:
                _profileService.getSkillLevels().map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(
                      level.substring(0, 1).toUpperCase() + level.substring(1),
                    ),
                  );
                }).toList(),
            onChanged: (value) => setState(() => _selectedSkillLevel = value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio',
              prefixIcon: Icon(Icons.info),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 16),
          _buildSportsSelector(),
        ],
      ),
    );
  }

  Widget _buildSportsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Sports',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              _profileService.getAvailableSports().map((sport) {
                // Check if sport is selected using case-insensitive comparison
                final isSelected = _selectedSports.any(
                  (selected) => selected.toLowerCase() == sport.toLowerCase(),
                );
                return FilterChip(
                  label: Text(sport),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        // Remove any existing case variations and add the current one
                        _selectedSports.removeWhere(
                          (existing) =>
                              existing.toLowerCase() == sport.toLowerCase(),
                        );
                        _selectedSports.add(sport);
                      } else {
                        // Remove using case-insensitive comparison
                        _selectedSports.removeWhere(
                          (existing) =>
                              existing.toLowerCase() == sport.toLowerCase(),
                        );
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_isEditing && _currentProfile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing) ...[
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                _loadUserProfile(); // Reset form
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: const Text('Save'),
            ),
          ],
        ],
      ),
      body:
          _isLoading && _currentProfile == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserProfile,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 16),
                      if (!_isEditing) ...[
                        _buildProfileInfo(),
                        const SizedBox(height: 24),
                        _buildStatsSection(),
                        const SizedBox(height: 16),
                        if (_currentProfile?.preferredSports.isNotEmpty ==
                            true) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preferred Sports',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children:
                                        _currentProfile!.preferredSports.map((
                                          sport,
                                        ) {
                                          return Chip(
                                            label: Text(sport),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.1),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_currentProfile?.bio?.isNotEmpty == true) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_currentProfile!.bio!),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _authService.signOut();
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/login');
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ] else ...[
                        _buildEditForm(),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
