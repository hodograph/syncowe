import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncowe/models/debt_pair.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

part 'current_trip.g.dart';

@riverpod
Trip? currentTrip(Ref ref) {
  String? currentTripId = ref.watch(currentTripIdProvider);
  var trips = ref.watch(tripsProvider);

  return trips[currentTripId];
}

@riverpod
class CurrentTripId extends _$CurrentTripId {
  @override
  String? build() => null;

  void setTrip(String? currentTripId) {
    state = currentTripId;
  }
}

@riverpod
class Trips extends _$Trips {
  @override
  Map<String, Trip> build() {
    var trips = ref.listen(tripsStreamProvider, setTrips);

    switch (trips) {
      case AsyncData(:final value):
        {
          return {for (var v in value.docs) v.id: v.data() as Trip};
        }
    }

    return {};
  }

  void setTrips(AsyncValue<QuerySnapshot<Object?>>? oldValue,
      AsyncValue<QuerySnapshot<Object?>> newValue) {
    switch (newValue) {
      case AsyncData(:final value):
        {
          state = {for (var v in value.docs) v.id: v.data() as Trip};
        }
    }
  }
}

@riverpod
class ArchivedTrips extends _$ArchivedTrips {
  @override
  Map<String, Trip> build() {
    var trips = ref.listen(archivedTripsStreamProvider, setTrips);

    switch (trips) {
      case AsyncData(:final value):
        {
          return {for (var v in value.docs) v.id: v.data() as Trip};
        }
    }

    return {};
  }

  void setTrips(AsyncValue<QuerySnapshot<Object?>>? oldValue,
      AsyncValue<QuerySnapshot<Object?>> newValue) {
    switch (newValue) {
      case AsyncData(:final value):
        {
          state = {for (var v in value.docs) v.id: v.data() as Trip};
        }
    }
  }
}

@riverpod
Stream<QuerySnapshot<Object?>> archivedTripsStream(Ref ref) {
  TripFirestoreService tripFirestoreService =
      ref.read(tripFirestoreServiceProvider.notifier);

  return tripFirestoreService.listenToTrips(archived: true);
}

@riverpod
Stream<QuerySnapshot<Object?>> tripsStream(Ref ref) {
  TripFirestoreService tripFirestoreService =
      ref.read(tripFirestoreServiceProvider.notifier);

  return tripFirestoreService.listenToTrips();
}

@riverpod
Map<String, User> tripUsers(Ref ref) {
  var users = ref.watch(tripUsersStreamProvider);

  switch (users) {
    case AsyncData(:final value):
      {
        return {for (var v in value.docs) v.id: v.data() as User};
      }
  }
  return {};
}

@riverpod
Stream<QuerySnapshot<Object?>> tripUsersStream(Ref ref) {
  Trip? currentTrip = ref.watch(currentTripProvider);
  UserFirestoreService userFirestoreService =
      ref.read(userFirestoreServiceProvider.notifier);

  return userFirestoreService.listenToUsers(currentTrip?.sharedWith ?? []);
}

@riverpod
class TripDebtPairs extends _$TripDebtPairs {
  @override
  Map<String, DebtPair> build() {
    var debtPairs = ref.listen(tripDebtPairsStreamProvider, setDebtPairs);

    switch (debtPairs) {
      case AsyncData(:final value):
        {
          return {
            for (var pair in value.docs) pair.id: pair.data() as DebtPair
          };
        }
    }

    return {};
  }

  void setDebtPairs(AsyncValue<QuerySnapshot<Object?>>? oldValue,
      AsyncValue<QuerySnapshot<Object?>> newValue) {
    switch (newValue) {
      case AsyncData(:final value):
        {
          state = {
            for (var pair in value.docs) pair.id: pair.data() as DebtPair
          };
        }
    }
  }
}

@riverpod
Stream<QuerySnapshot<Object?>> tripDebtPairsStream(Ref ref) {
  String? tripId = ref.watch(currentTripIdProvider);

  return ref
      .read(tripFirestoreServiceProvider.notifier)
      .listenToOverallDebts(tripId!);
}
