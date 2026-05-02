// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_transaction.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentTransactionHash() =>
    r'f0e5bee6f1f68d17ee8f23b23ac9eff741311180';

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

typedef CurrentTransactionRef = Ref<syncowe.Transaction?>;
String _$currentTransactionAsyncHash() =>
    r'4b32c9b433e7e4d9fe7f8a84ac853d3cd52bdd0b';

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

typedef CurrentTransactionAsyncRef
    = Ref<syncowe.Transaction?>;
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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
