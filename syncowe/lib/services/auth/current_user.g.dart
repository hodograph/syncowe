// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_user.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserStreamHash() => r'5822f49e295c8ad0c8bd6b0649ed765f3ca690b0';

/// See also [currentUserStream].
@ProviderFor(currentUserStream)
final currentUserStreamProvider = AutoDisposeStreamProvider<User?>.internal(
  currentUserStream,
  name: r'currentUserStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentUserStreamRef = AutoDisposeStreamProviderRef<User?>;
String _$currentFireAuthUserHash() =>
    r'ca0a9f11800f4d8e68897870701a7722a9a52479';

/// See also [currentFireAuthUser].
@ProviderFor(currentFireAuthUser)
final currentFireAuthUserProvider =
    AutoDisposeStreamProvider<fireauth.User?>.internal(
  currentFireAuthUser,
  name: r'currentFireAuthUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentFireAuthUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentFireAuthUserRef = AutoDisposeStreamProviderRef<fireauth.User?>;
String _$currentUserHash() => r'58a3d22287f505137771e7586ea91567ca4786a8';

/// See also [CurrentUser].
@ProviderFor(CurrentUser)
final currentUserProvider =
    AutoDisposeNotifierProvider<CurrentUser, User?>.internal(
  CurrentUser.new,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUser = AutoDisposeNotifier<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
