// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileServiceHash() => r'ff3a1fc08e2cafcce1c70ed8ea019f8108645889';

/// See also [profileService].
@ProviderFor(profileService)
final profileServiceProvider = Provider<ProfileService>.internal(
  profileService,
  name: r'profileServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileServiceRef = ProviderRef<ProfileService>;
String _$currentUserProfileHash() =>
    r'6b8f51919188bdd5376dc19d2bf53691f17a1bd9';

/// See also [currentUserProfile].
@ProviderFor(currentUserProfile)
final currentUserProfileProvider =
    AutoDisposeFutureProvider<models.User?>.internal(
      currentUserProfile,
      name: r'currentUserProfileProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$currentUserProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserProfileRef = AutoDisposeFutureProviderRef<models.User?>;
String _$userStatsHash() => r'9551055d9fdb0050c57e55e6f64620d899da0dda';

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

/// See also [userStats].
@ProviderFor(userStats)
const userStatsProvider = UserStatsFamily();

/// See also [userStats].
class UserStatsFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [userStats].
  const UserStatsFamily();

  /// See also [userStats].
  UserStatsProvider call(String userId) {
    return UserStatsProvider(userId);
  }

  @override
  UserStatsProvider getProviderOverride(covariant UserStatsProvider provider) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userStatsProvider';
}

/// See also [userStats].
class UserStatsProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [userStats].
  UserStatsProvider(String userId)
    : this._internal(
        (ref) => userStats(ref as UserStatsRef, userId),
        from: userStatsProvider,
        name: r'userStatsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$userStatsHash,
        dependencies: UserStatsFamily._dependencies,
        allTransitiveDependencies: UserStatsFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(UserStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserStatsProvider._internal(
        (ref) => create(ref as UserStatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _UserStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserStatsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserStatsRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserStatsProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with UserStatsRef {
  _UserStatsProviderElement(super.provider);

  @override
  String get userId => (origin as UserStatsProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
