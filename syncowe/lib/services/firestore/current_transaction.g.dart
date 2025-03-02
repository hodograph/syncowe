// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_transaction.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentTransactionHash() =>
    r'1c3bda3b326071de1e76e5b7cc2224ccd36323e9';

/// See also [currentTransaction].
@ProviderFor(currentTransaction)
final currentTransactionProvider =
    AutoDisposeProvider<syncowe.Transaction?>.internal(
  currentTransaction,
  name: r'currentTransactionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTransactionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentTransactionRef = AutoDisposeProviderRef<syncowe.Transaction?>;
String _$currentTransactionAsyncHash() =>
    r'0354e3d94f08ac29412f2a82f7a8881f07b10133';

/// See also [currentTransactionAsync].
@ProviderFor(currentTransactionAsync)
final currentTransactionAsyncProvider =
    AutoDisposeFutureProvider<syncowe.Transaction?>.internal(
  currentTransactionAsync,
  name: r'currentTransactionAsyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTransactionAsyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentTransactionAsyncRef
    = AutoDisposeFutureProviderRef<syncowe.Transaction?>;
String _$currentTransactionIdHash() =>
    r'aace63ed3effe7e3d51f13e3da7515b4f381affe';

/// See also [CurrentTransactionId].
@ProviderFor(CurrentTransactionId)
final currentTransactionIdProvider =
    AutoDisposeNotifierProvider<CurrentTransactionId, String?>.internal(
  CurrentTransactionId.new,
  name: r'currentTransactionIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTransactionIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentTransactionId = AutoDisposeNotifier<String?>;
String _$loadedTransactionsHash() =>
    r'55b365b50a9adc94aa9f57789b56c5ff370dd387';

/// See also [LoadedTransactions].
@ProviderFor(LoadedTransactions)
final loadedTransactionsProvider = AutoDisposeNotifierProvider<
    LoadedTransactions, Map<String, syncowe.Transaction>?>.internal(
  LoadedTransactions.new,
  name: r'loadedTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadedTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LoadedTransactions
    = AutoDisposeNotifier<Map<String, syncowe.Transaction>?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
