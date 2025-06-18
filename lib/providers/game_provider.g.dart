// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gameServiceHash() => r'ae708711aa5b51b64b58853d7f38a19f32b42f93';

/// Provider for GameService
///
/// Copied from [gameService].
@ProviderFor(gameService)
final gameServiceProvider = AutoDisposeProvider<GameService>.internal(
  gameService,
  name: r'gameServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$gameServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GameServiceRef = AutoDisposeProviderRef<GameService>;
String _$teamGamesHash() => r'31e27b813ea3ae339d4d6b6d8c979efac9ae64e1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider to get games for a specific team
///
/// Copied from [teamGames].
@ProviderFor(teamGames)
const teamGamesProvider = TeamGamesFamily();

/// Provider to get games for a specific team
///
/// Copied from [teamGames].
class TeamGamesFamily extends Family<AsyncValue<List<Game>>> {
  /// Provider to get games for a specific team
  ///
  /// Copied from [teamGames].
  const TeamGamesFamily();

  /// Provider to get games for a specific team
  ///
  /// Copied from [teamGames].
  TeamGamesProvider call(String teamId) {
    return TeamGamesProvider(teamId);
  }

  @override
  TeamGamesProvider getProviderOverride(covariant TeamGamesProvider provider) {
    return call(provider.teamId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'teamGamesProvider';
}

/// Provider to get games for a specific team
///
/// Copied from [teamGames].
class TeamGamesProvider extends AutoDisposeFutureProvider<List<Game>> {
  /// Provider to get games for a specific team
  ///
  /// Copied from [teamGames].
  TeamGamesProvider(String teamId)
    : this._internal(
        (ref) => teamGames(ref as TeamGamesRef, teamId),
        from: teamGamesProvider,
        name: r'teamGamesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teamGamesHash,
        dependencies: TeamGamesFamily._dependencies,
        allTransitiveDependencies: TeamGamesFamily._allTransitiveDependencies,
        teamId: teamId,
      );

  TeamGamesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teamId,
  }) : super.internal();

  final String teamId;

  @override
  Override overrideWith(
    FutureOr<List<Game>> Function(TeamGamesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeamGamesProvider._internal(
        (ref) => create(ref as TeamGamesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teamId: teamId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Game>> createElement() {
    return _TeamGamesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamGamesProvider && other.teamId == teamId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teamId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TeamGamesRef on AutoDisposeFutureProviderRef<List<Game>> {
  /// The parameter `teamId` of this provider.
  String get teamId;
}

class _TeamGamesProviderElement
    extends AutoDisposeFutureProviderElement<List<Game>>
    with TeamGamesRef {
  _TeamGamesProviderElement(super.provider);

  @override
  String get teamId => (origin as TeamGamesProvider).teamId;
}

String _$upcomingTeamGamesHash() => r'fc22e0d90ead664ad6c20925ac6fe998eec7d0b0';

/// Provider to get upcoming games for a specific team
///
/// Copied from [upcomingTeamGames].
@ProviderFor(upcomingTeamGames)
const upcomingTeamGamesProvider = UpcomingTeamGamesFamily();

/// Provider to get upcoming games for a specific team
///
/// Copied from [upcomingTeamGames].
class UpcomingTeamGamesFamily extends Family<AsyncValue<List<Game>>> {
  /// Provider to get upcoming games for a specific team
  ///
  /// Copied from [upcomingTeamGames].
  const UpcomingTeamGamesFamily();

  /// Provider to get upcoming games for a specific team
  ///
  /// Copied from [upcomingTeamGames].
  UpcomingTeamGamesProvider call(String teamId) {
    return UpcomingTeamGamesProvider(teamId);
  }

  @override
  UpcomingTeamGamesProvider getProviderOverride(
    covariant UpcomingTeamGamesProvider provider,
  ) {
    return call(provider.teamId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'upcomingTeamGamesProvider';
}

/// Provider to get upcoming games for a specific team
///
/// Copied from [upcomingTeamGames].
class UpcomingTeamGamesProvider extends AutoDisposeFutureProvider<List<Game>> {
  /// Provider to get upcoming games for a specific team
  ///
  /// Copied from [upcomingTeamGames].
  UpcomingTeamGamesProvider(String teamId)
    : this._internal(
        (ref) => upcomingTeamGames(ref as UpcomingTeamGamesRef, teamId),
        from: upcomingTeamGamesProvider,
        name: r'upcomingTeamGamesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$upcomingTeamGamesHash,
        dependencies: UpcomingTeamGamesFamily._dependencies,
        allTransitiveDependencies:
            UpcomingTeamGamesFamily._allTransitiveDependencies,
        teamId: teamId,
      );

  UpcomingTeamGamesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teamId,
  }) : super.internal();

  final String teamId;

  @override
  Override overrideWith(
    FutureOr<List<Game>> Function(UpcomingTeamGamesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpcomingTeamGamesProvider._internal(
        (ref) => create(ref as UpcomingTeamGamesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teamId: teamId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Game>> createElement() {
    return _UpcomingTeamGamesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingTeamGamesProvider && other.teamId == teamId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teamId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpcomingTeamGamesRef on AutoDisposeFutureProviderRef<List<Game>> {
  /// The parameter `teamId` of this provider.
  String get teamId;
}

class _UpcomingTeamGamesProviderElement
    extends AutoDisposeFutureProviderElement<List<Game>>
    with UpcomingTeamGamesRef {
  _UpcomingTeamGamesProviderElement(super.provider);

  @override
  String get teamId => (origin as UpcomingTeamGamesProvider).teamId;
}

String _$userGamesHash() => r'b4e836636824bf062bfa07df7715d4149e7ce7d2';

/// Provider to get games for current user's teams
///
/// Copied from [userGames].
@ProviderFor(userGames)
final userGamesProvider = AutoDisposeFutureProvider<List<Game>>.internal(
  userGames,
  name: r'userGamesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userGamesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserGamesRef = AutoDisposeFutureProviderRef<List<Game>>;
String _$upcomingUserGamesHash() => r'e22b4488832e5b04d47e86c7f79b9f17994f97be';

/// Provider to get upcoming games for current user's teams
///
/// Copied from [upcomingUserGames].
@ProviderFor(upcomingUserGames)
final upcomingUserGamesProvider =
    AutoDisposeFutureProvider<List<Game>>.internal(
      upcomingUserGames,
      name: r'upcomingUserGamesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$upcomingUserGamesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpcomingUserGamesRef = AutoDisposeFutureProviderRef<List<Game>>;
String _$userRsvpedGamesHash() => r'61c37e9ecd52a82ace8aa77b8e5fc222dc0f8f6f';

/// Provider to get games the user has RSVP'd to
///
/// Copied from [userRsvpedGames].
@ProviderFor(userRsvpedGames)
final userRsvpedGamesProvider = AutoDisposeFutureProvider<List<Game>>.internal(
  userRsvpedGames,
  name: r'userRsvpedGamesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userRsvpedGamesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRsvpedGamesRef = AutoDisposeFutureProviderRef<List<Game>>;
String _$upcomingUserRsvpedGamesHash() =>
    r'6623db5ac7fdc488e319edc4db863f95fbf27cdb';

/// Provider to get upcoming games the user has RSVP'd to
///
/// Copied from [upcomingUserRsvpedGames].
@ProviderFor(upcomingUserRsvpedGames)
final upcomingUserRsvpedGamesProvider =
    AutoDisposeFutureProvider<List<Game>>.internal(
      upcomingUserRsvpedGames,
      name: r'upcomingUserRsvpedGamesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$upcomingUserRsvpedGamesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpcomingUserRsvpedGamesRef = AutoDisposeFutureProviderRef<List<Game>>;
String _$gameHash() => r'08fa4a9b8dd27846fec75f737c56ac8078b579df';

/// Provider to get a specific game by ID
///
/// Copied from [game].
@ProviderFor(game)
const gameProvider = GameFamily();

/// Provider to get a specific game by ID
///
/// Copied from [game].
class GameFamily extends Family<AsyncValue<Game>> {
  /// Provider to get a specific game by ID
  ///
  /// Copied from [game].
  const GameFamily();

  /// Provider to get a specific game by ID
  ///
  /// Copied from [game].
  GameProvider call(String gameId) {
    return GameProvider(gameId);
  }

  @override
  GameProvider getProviderOverride(covariant GameProvider provider) {
    return call(provider.gameId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'gameProvider';
}

/// Provider to get a specific game by ID
///
/// Copied from [game].
class GameProvider extends AutoDisposeFutureProvider<Game> {
  /// Provider to get a specific game by ID
  ///
  /// Copied from [game].
  GameProvider(String gameId)
    : this._internal(
        (ref) => game(ref as GameRef, gameId),
        from: gameProvider,
        name: r'gameProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product') ? null : _$gameHash,
        dependencies: GameFamily._dependencies,
        allTransitiveDependencies: GameFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  GameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.gameId,
  }) : super.internal();

  final String gameId;

  @override
  Override overrideWith(FutureOr<Game> Function(GameRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: GameProvider._internal(
        (ref) => create(ref as GameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        gameId: gameId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Game> createElement() {
    return _GameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GameProvider && other.gameId == gameId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, gameId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GameRef on AutoDisposeFutureProviderRef<Game> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _GameProviderElement extends AutoDisposeFutureProviderElement<Game>
    with GameRef {
  _GameProviderElement(super.provider);

  @override
  String get gameId => (origin as GameProvider).gameId;
}

String _$discoverGamesHash() => r'68c30fd828c279191c10fefd2c6433237521c981';

/// Provider to discover public games
///
/// Copied from [discoverGames].
@ProviderFor(discoverGames)
const discoverGamesProvider = DiscoverGamesFamily();

/// Provider to discover public games
///
/// Copied from [discoverGames].
class DiscoverGamesFamily extends Family<AsyncValue<List<Game>>> {
  /// Provider to discover public games
  ///
  /// Copied from [discoverGames].
  const DiscoverGamesFamily();

  /// Provider to discover public games
  ///
  /// Copied from [discoverGames].
  DiscoverGamesProvider call({
    double? latitude,
    double? longitude,
    double radiusKm = 25.0,
    String? sport,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    return DiscoverGamesProvider(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      sport: sport,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  @override
  DiscoverGamesProvider getProviderOverride(
    covariant DiscoverGamesProvider provider,
  ) {
    return call(
      latitude: provider.latitude,
      longitude: provider.longitude,
      radiusKm: provider.radiusKm,
      sport: provider.sport,
      startDate: provider.startDate,
      endDate: provider.endDate,
      limit: provider.limit,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'discoverGamesProvider';
}

/// Provider to discover public games
///
/// Copied from [discoverGames].
class DiscoverGamesProvider extends AutoDisposeFutureProvider<List<Game>> {
  /// Provider to discover public games
  ///
  /// Copied from [discoverGames].
  DiscoverGamesProvider({
    double? latitude,
    double? longitude,
    double radiusKm = 25.0,
    String? sport,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) : this._internal(
         (ref) => discoverGames(
           ref as DiscoverGamesRef,
           latitude: latitude,
           longitude: longitude,
           radiusKm: radiusKm,
           sport: sport,
           startDate: startDate,
           endDate: endDate,
           limit: limit,
         ),
         from: discoverGamesProvider,
         name: r'discoverGamesProvider',
         debugGetCreateSourceHash:
             const bool.fromEnvironment('dart.vm.product')
                 ? null
                 : _$discoverGamesHash,
         dependencies: DiscoverGamesFamily._dependencies,
         allTransitiveDependencies:
             DiscoverGamesFamily._allTransitiveDependencies,
         latitude: latitude,
         longitude: longitude,
         radiusKm: radiusKm,
         sport: sport,
         startDate: startDate,
         endDate: endDate,
         limit: limit,
       );

  DiscoverGamesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.sport,
    required this.startDate,
    required this.endDate,
    required this.limit,
  }) : super.internal();

  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final String? sport;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<Game>> Function(DiscoverGamesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DiscoverGamesProvider._internal(
        (ref) => create(ref as DiscoverGamesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        sport: sport,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Game>> createElement() {
    return _DiscoverGamesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoverGamesProvider &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.radiusKm == radiusKm &&
        other.sport == sport &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, latitude.hashCode);
    hash = _SystemHash.combine(hash, longitude.hashCode);
    hash = _SystemHash.combine(hash, radiusKm.hashCode);
    hash = _SystemHash.combine(hash, sport.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DiscoverGamesRef on AutoDisposeFutureProviderRef<List<Game>> {
  /// The parameter `latitude` of this provider.
  double? get latitude;

  /// The parameter `longitude` of this provider.
  double? get longitude;

  /// The parameter `radiusKm` of this provider.
  double get radiusKm;

  /// The parameter `sport` of this provider.
  String? get sport;

  /// The parameter `startDate` of this provider.
  DateTime? get startDate;

  /// The parameter `endDate` of this provider.
  DateTime? get endDate;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _DiscoverGamesProviderElement
    extends AutoDisposeFutureProviderElement<List<Game>>
    with DiscoverGamesRef {
  _DiscoverGamesProviderElement(super.provider);

  @override
  double? get latitude => (origin as DiscoverGamesProvider).latitude;
  @override
  double? get longitude => (origin as DiscoverGamesProvider).longitude;
  @override
  double get radiusKm => (origin as DiscoverGamesProvider).radiusKm;
  @override
  String? get sport => (origin as DiscoverGamesProvider).sport;
  @override
  DateTime? get startDate => (origin as DiscoverGamesProvider).startDate;
  @override
  DateTime? get endDate => (origin as DiscoverGamesProvider).endDate;
  @override
  int get limit => (origin as DiscoverGamesProvider).limit;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
