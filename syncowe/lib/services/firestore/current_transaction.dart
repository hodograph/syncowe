import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncowe/models/transaction.dart' as syncowe;
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

part 'current_transaction.g.dart';

@riverpod
syncowe.Transaction? currentTransaction(Ref ref) {
  var transaction = ref.watch(currentTransactionAsyncProvider);

  switch (transaction) {
    case AsyncData(:final value):
      {
        return value;
      }
  }

  return null;
}

@riverpod
Future<syncowe.Transaction?> currentTransactionAsync(Ref ref) async {
  String? currentId = ref.watch(currentTransactionIdProvider);
  String? tripId = ref.watch(currentTripIdProvider);

  Map<String, syncowe.Transaction>? loadedTransactions =
      ref.watch(loadedTransactionsProvider);
  var tripFirestoreService = ref.read(tripFirestoreServiceProvider.notifier);

  if (currentId != null && tripId != null) {
    return loadedTransactions?[currentId] ??
        await tripFirestoreService.getTransaction(tripId, currentId);
  } else {
    return null;
  }
}

@riverpod
class CurrentTransactionId extends _$CurrentTransactionId {
  @override
  String? build() {
    return null;
  }

  void setTransactionId(String? id) {
    state = id;
  }
}

@riverpod
class LoadedTransactions extends _$LoadedTransactions {
  @override
  Map<String, syncowe.Transaction>? build() {
    return null;
  }

  void setTransactions(List<DocumentSnapshot<Object?>> transactions) {
    state = {for (var t in transactions) t.id: t.data() as syncowe.Transaction};
  }
}
