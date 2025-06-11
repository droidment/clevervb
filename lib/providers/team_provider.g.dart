// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teamServiceHash() => r'451f345629a1378c0c75f93dc3108523ed7c1712';

/// Provider for team service singleton
///
/// Copied from [teamService].
@ProviderFor(teamService)
final teamServiceProvider = AutoDisposeProvider<TeamService>.internal(
  teamService,
  name: r'teamServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$teamServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TeamServiceRef = AutoDisposeProviderRef<TeamService>;
String _$teamHash() => r'61d9d9e6b6cb9c61c95ab5c8c3b155ce43f8d46b';

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

/// Provider to get a specific team by ID
///
/// Copied from [team].
@ProviderFor(team)
const teamProvider = TeamFamily();

/// Provider to get a specific team by ID
///
/// Copied from [team].
class TeamFamily extends Family<AsyncValue<Team>> {
  /// Provider to get a specific team by ID
  ///
  /// Copied from [team].
  const TeamFamily();

  /// Provider to get a specific team by ID
  ///
  /// Copied from [team].
  TeamProvider call(String teamId) {
    return TeamProvider(teamId);
  }

  @override
  TeamProvider getProviderOverride(covariant TeamProvider provider) {
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
  String? get name => r'teamProvider';
}

/// Provider to get a specific team by ID
///
/// Copied from [team].
class TeamProvider extends AutoDisposeFutureProvider<Team> {
  /// Provider to get a specific team by ID
  ///
  /// Copied from [team].
  TeamProvider(String teamId)
    : this._internal(
        (ref) => team(ref as TeamRef, teamId),
        from: teamProvider,
        name: r'teamProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product') ? null : _$teamHash,
        dependencies: TeamFamily._dependencies,
        allTransitiveDependencies: TeamFamily._allTransitiveDependencies,
        teamId: teamId,
      );

  TeamProvider._internal(
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
  Override overrideWith(FutureOr<Team> Function(TeamRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: TeamProvider._internal(
        (ref) => create(ref as TeamRef),
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
  AutoDisposeFutureProviderElement<Team> createElement() {
    return _TeamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamProvider && other.teamId == teamId;
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
mixin TeamRef on AutoDisposeFutureProviderRef<Team> {
  /// The parameter `teamId` of this provider.
  String get teamId;
}

class _TeamProviderElement extends AutoDisposeFutureProviderElement<Team>
    with TeamRef {
  _TeamProviderElement(super.provider);

  @override
  String get teamId => (origin as TeamProvider).teamId;
}

String _$userTeamsHash() => r'673bf51227258d2ec5ea8b2537b72e28cddd9643';

/// Provider to get user's teams
///
/// Copied from [userTeams].
@ProviderFor(userTeams)
final userTeamsProvider = AutoDisposeFutureProvider<List<Team>>.internal(
  userTeams,
  name: r'userTeamsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userTeamsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserTeamsRef = AutoDisposeFutureProviderRef<List<Team>>;
String _$searchTeamsHash() => r'9cb9200ab9d0fc48ab2f52ca39a40c39aa59eab1';

/// Provider to search teams with filters
///
/// Copied from [searchTeams].
@ProviderFor(searchTeams)
const searchTeamsProvider = SearchTeamsFamily();

/// Provider to search teams with filters
///
/// Copied from [searchTeams].
class SearchTeamsFamily extends Family<AsyncValue<List<Team>>> {
  /// Provider to search teams with filters
  ///
  /// Copied from [searchTeams].
  const SearchTeamsFamily();

  /// Provider to search teams with filters
  ///
  /// Copied from [searchTeams].
  SearchTeamsProvider call({
    String? teamName,
    String? sportType,
    bool? isPublic,
    int limit = 20,
    int offset = 0,
  }) {
    return SearchTeamsProvider(
      teamName: teamName,
      sportType: sportType,
      isPublic: isPublic,
      limit: limit,
      offset: offset,
    );
  }

  @override
  SearchTeamsProvider getProviderOverride(
    covariant SearchTeamsProvider provider,
  ) {
    return call(
      teamName: provider.teamName,
      sportType: provider.sportType,
      isPublic: provider.isPublic,
      limit: provider.limit,
      offset: provider.offset,
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
  String? get name => r'searchTeamsProvider';
}

/// Provider to search teams with filters
///
/// Copied from [searchTeams].
class SearchTeamsProvider extends AutoDisposeFutureProvider<List<Team>> {
  /// Provider to search teams with filters
  ///
  /// Copied from [searchTeams].
  SearchTeamsProvider({
    String? teamName,
    String? sportType,
    bool? isPublic,
    int limit = 20,
    int offset = 0,
  }) : this._internal(
         (ref) => searchTeams(
           ref as SearchTeamsRef,
           teamName: teamName,
           sportType: sportType,
           isPublic: isPublic,
           limit: limit,
           offset: offset,
         ),
         from: searchTeamsProvider,
         name: r'searchTeamsProvider',
         debugGetCreateSourceHash:
             const bool.fromEnvironment('dart.vm.product')
                 ? null
                 : _$searchTeamsHash,
         dependencies: SearchTeamsFamily._dependencies,
         allTransitiveDependencies:
             SearchTeamsFamily._allTransitiveDependencies,
         teamName: teamName,
         sportType: sportType,
         isPublic: isPublic,
         limit: limit,
         offset: offset,
       );

  SearchTeamsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teamName,
    required this.sportType,
    required this.isPublic,
    required this.limit,
    required this.offset,
  }) : super.internal();

  final String? teamName;
  final String? sportType;
  final bool? isPublic;
  final int limit;
  final int offset;

  @override
  Override overrideWith(
    FutureOr<List<Team>> Function(SearchTeamsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchTeamsProvider._internal(
        (ref) => create(ref as SearchTeamsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teamName: teamName,
        sportType: sportType,
        isPublic: isPublic,
        limit: limit,
        offset: offset,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Team>> createElement() {
    return _SearchTeamsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchTeamsProvider &&
        other.teamName == teamName &&
        other.sportType == sportType &&
        other.isPublic == isPublic &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teamName.hashCode);
    hash = _SystemHash.combine(hash, sportType.hashCode);
    hash = _SystemHash.combine(hash, isPublic.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchTeamsRef on AutoDisposeFutureProviderRef<List<Team>> {
  /// The parameter `teamName` of this provider.
  String? get teamName;

  /// The parameter `sportType` of this provider.
  String? get sportType;

  /// The parameter `isPublic` of this provider.
  bool? get isPublic;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;
}

class _SearchTeamsProviderElement
    extends AutoDisposeFutureProviderElement<List<Team>>
    with SearchTeamsRef {
  _SearchTeamsProviderElement(super.provider);

  @override
  String? get teamName => (origin as SearchTeamsProvider).teamName;
  @override
  String? get sportType => (origin as SearchTeamsProvider).sportType;
  @override
  bool? get isPublic => (origin as SearchTeamsProvider).isPublic;
  @override
  int get limit => (origin as SearchTeamsProvider).limit;
  @override
  int get offset => (origin as SearchTeamsProvider).offset;
}

String _$popularTeamsHash() => r'afa220614ee7e1149f233db705d196aa9216ba85';

/// Provider to get popular teams
///
/// Copied from [popularTeams].
@ProviderFor(popularTeams)
const popularTeamsProvider = PopularTeamsFamily();

/// Provider to get popular teams
///
/// Copied from [popularTeams].
class PopularTeamsFamily extends Family<AsyncValue<List<Team>>> {
  /// Provider to get popular teams
  ///
  /// Copied from [popularTeams].
  const PopularTeamsFamily();

  /// Provider to get popular teams
  ///
  /// Copied from [popularTeams].
  PopularTeamsProvider call({int limit = 10}) {
    return PopularTeamsProvider(limit: limit);
  }

  @override
  PopularTeamsProvider getProviderOverride(
    covariant PopularTeamsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'popularTeamsProvider';
}

/// Provider to get popular teams
///
/// Copied from [popularTeams].
class PopularTeamsProvider extends AutoDisposeFutureProvider<List<Team>> {
  /// Provider to get popular teams
  ///
  /// Copied from [popularTeams].
  PopularTeamsProvider({int limit = 10})
    : this._internal(
        (ref) => popularTeams(ref as PopularTeamsRef, limit: limit),
        from: popularTeamsProvider,
        name: r'popularTeamsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$popularTeamsHash,
        dependencies: PopularTeamsFamily._dependencies,
        allTransitiveDependencies:
            PopularTeamsFamily._allTransitiveDependencies,
        limit: limit,
      );

  PopularTeamsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<Team>> Function(PopularTeamsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PopularTeamsProvider._internal(
        (ref) => create(ref as PopularTeamsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Team>> createElement() {
    return _PopularTeamsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PopularTeamsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PopularTeamsRef on AutoDisposeFutureProviderRef<List<Team>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _PopularTeamsProviderElement
    extends AutoDisposeFutureProviderElement<List<Team>>
    with PopularTeamsRef {
  _PopularTeamsProviderElement(super.provider);

  @override
  int get limit => (origin as PopularTeamsProvider).limit;
}

String _$teamMembersHash() => r'9c7cb0cc7b51c98418c3b11b036eb13ceb65669a';

/// Provider to get team members
///
/// Copied from [teamMembers].
@ProviderFor(teamMembers)
const teamMembersProvider = TeamMembersFamily();

/// Provider to get team members
///
/// Copied from [teamMembers].
class TeamMembersFamily extends Family<AsyncValue<List<TeamMember>>> {
  /// Provider to get team members
  ///
  /// Copied from [teamMembers].
  const TeamMembersFamily();

  /// Provider to get team members
  ///
  /// Copied from [teamMembers].
  TeamMembersProvider call(String teamId) {
    return TeamMembersProvider(teamId);
  }

  @override
  TeamMembersProvider getProviderOverride(
    covariant TeamMembersProvider provider,
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
  String? get name => r'teamMembersProvider';
}

/// Provider to get team members
///
/// Copied from [teamMembers].
class TeamMembersProvider extends AutoDisposeFutureProvider<List<TeamMember>> {
  /// Provider to get team members
  ///
  /// Copied from [teamMembers].
  TeamMembersProvider(String teamId)
    : this._internal(
        (ref) => teamMembers(ref as TeamMembersRef, teamId),
        from: teamMembersProvider,
        name: r'teamMembersProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teamMembersHash,
        dependencies: TeamMembersFamily._dependencies,
        allTransitiveDependencies: TeamMembersFamily._allTransitiveDependencies,
        teamId: teamId,
      );

  TeamMembersProvider._internal(
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
    FutureOr<List<TeamMember>> Function(TeamMembersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeamMembersProvider._internal(
        (ref) => create(ref as TeamMembersRef),
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
  AutoDisposeFutureProviderElement<List<TeamMember>> createElement() {
    return _TeamMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamMembersProvider && other.teamId == teamId;
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
mixin TeamMembersRef on AutoDisposeFutureProviderRef<List<TeamMember>> {
  /// The parameter `teamId` of this provider.
  String get teamId;
}

class _TeamMembersProviderElement
    extends AutoDisposeFutureProviderElement<List<TeamMember>>
    with TeamMembersRef {
  _TeamMembersProviderElement(super.provider);

  @override
  String get teamId => (origin as TeamMembersProvider).teamId;
}

String _$teamInvitationsHash() => r'66d83bc15959a35234d1726bf23f2fbad396dc2c';

/// Provider to get team invitations
///
/// Copied from [teamInvitations].
@ProviderFor(teamInvitations)
const teamInvitationsProvider = TeamInvitationsFamily();

/// Provider to get team invitations
///
/// Copied from [teamInvitations].
class TeamInvitationsFamily extends Family<AsyncValue<List<TeamInvitation>>> {
  /// Provider to get team invitations
  ///
  /// Copied from [teamInvitations].
  const TeamInvitationsFamily();

  /// Provider to get team invitations
  ///
  /// Copied from [teamInvitations].
  TeamInvitationsProvider call(String teamId) {
    return TeamInvitationsProvider(teamId);
  }

  @override
  TeamInvitationsProvider getProviderOverride(
    covariant TeamInvitationsProvider provider,
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
  String? get name => r'teamInvitationsProvider';
}

/// Provider to get team invitations
///
/// Copied from [teamInvitations].
class TeamInvitationsProvider
    extends AutoDisposeFutureProvider<List<TeamInvitation>> {
  /// Provider to get team invitations
  ///
  /// Copied from [teamInvitations].
  TeamInvitationsProvider(String teamId)
    : this._internal(
        (ref) => teamInvitations(ref as TeamInvitationsRef, teamId),
        from: teamInvitationsProvider,
        name: r'teamInvitationsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teamInvitationsHash,
        dependencies: TeamInvitationsFamily._dependencies,
        allTransitiveDependencies:
            TeamInvitationsFamily._allTransitiveDependencies,
        teamId: teamId,
      );

  TeamInvitationsProvider._internal(
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
    FutureOr<List<TeamInvitation>> Function(TeamInvitationsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeamInvitationsProvider._internal(
        (ref) => create(ref as TeamInvitationsRef),
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
  AutoDisposeFutureProviderElement<List<TeamInvitation>> createElement() {
    return _TeamInvitationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamInvitationsProvider && other.teamId == teamId;
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
mixin TeamInvitationsRef on AutoDisposeFutureProviderRef<List<TeamInvitation>> {
  /// The parameter `teamId` of this provider.
  String get teamId;
}

class _TeamInvitationsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeamInvitation>>
    with TeamInvitationsRef {
  _TeamInvitationsProviderElement(super.provider);

  @override
  String get teamId => (origin as TeamInvitationsProvider).teamId;
}

String _$invitationHash() => r'0e2c8e992f90b124eaf40b7fed71944fba7b654a';

/// Provider to get a specific invitation
///
/// Copied from [invitation].
@ProviderFor(invitation)
const invitationProvider = InvitationFamily();

/// Provider to get a specific invitation
///
/// Copied from [invitation].
class InvitationFamily extends Family<AsyncValue<TeamInvitation>> {
  /// Provider to get a specific invitation
  ///
  /// Copied from [invitation].
  const InvitationFamily();

  /// Provider to get a specific invitation
  ///
  /// Copied from [invitation].
  InvitationProvider call(String invitationId) {
    return InvitationProvider(invitationId);
  }

  @override
  InvitationProvider getProviderOverride(
    covariant InvitationProvider provider,
  ) {
    return call(provider.invitationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'invitationProvider';
}

/// Provider to get a specific invitation
///
/// Copied from [invitation].
class InvitationProvider extends AutoDisposeFutureProvider<TeamInvitation> {
  /// Provider to get a specific invitation
  ///
  /// Copied from [invitation].
  InvitationProvider(String invitationId)
    : this._internal(
        (ref) => invitation(ref as InvitationRef, invitationId),
        from: invitationProvider,
        name: r'invitationProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$invitationHash,
        dependencies: InvitationFamily._dependencies,
        allTransitiveDependencies: InvitationFamily._allTransitiveDependencies,
        invitationId: invitationId,
      );

  InvitationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.invitationId,
  }) : super.internal();

  final String invitationId;

  @override
  Override overrideWith(
    FutureOr<TeamInvitation> Function(InvitationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InvitationProvider._internal(
        (ref) => create(ref as InvitationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        invitationId: invitationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TeamInvitation> createElement() {
    return _InvitationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InvitationProvider && other.invitationId == invitationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, invitationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin InvitationRef on AutoDisposeFutureProviderRef<TeamInvitation> {
  /// The parameter `invitationId` of this provider.
  String get invitationId;
}

class _InvitationProviderElement
    extends AutoDisposeFutureProviderElement<TeamInvitation>
    with InvitationRef {
  _InvitationProviderElement(super.provider);

  @override
  String get invitationId => (origin as InvitationProvider).invitationId;
}

String _$teamNotifierHash() => r'682eb5faa8e54390162baeef3baa83ffb85c8e9b';

/// State notifier for team operations
///
/// Copied from [TeamNotifier].
@ProviderFor(TeamNotifier)
final teamNotifierProvider =
    AutoDisposeNotifierProvider<TeamNotifier, AsyncValue<Team?>>.internal(
      TeamNotifier.new,
      name: r'teamNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$teamNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TeamNotifier = AutoDisposeNotifier<AsyncValue<Team?>>;
String _$invitationNotifierHash() =>
    r'59ec92b71fc6510c31fa68243b1f2f8186f14b79';

/// State notifier for invitation operations
///
/// Copied from [InvitationNotifier].
@ProviderFor(InvitationNotifier)
final invitationNotifierProvider = AutoDisposeNotifierProvider<
  InvitationNotifier,
  AsyncValue<TeamInvitation?>
>.internal(
  InvitationNotifier.new,
  name: r'invitationNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$invitationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InvitationNotifier = AutoDisposeNotifier<AsyncValue<TeamInvitation?>>;
String _$teamSearchNotifierHash() =>
    r'a17e1fc524b7a72645c6087fe8cf872066361fa5';

/// State notifier for team search functionality
///
/// Copied from [TeamSearchNotifier].
@ProviderFor(TeamSearchNotifier)
final teamSearchNotifierProvider =
    AutoDisposeNotifierProvider<TeamSearchNotifier, TeamSearchState>.internal(
      TeamSearchNotifier.new,
      name: r'teamSearchNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$teamSearchNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TeamSearchNotifier = AutoDisposeNotifier<TeamSearchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
