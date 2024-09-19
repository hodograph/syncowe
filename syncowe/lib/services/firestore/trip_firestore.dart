import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncowe/models/debt_pair.dart';
import 'package:syncowe/models/overall_debt_summary.dart';
import 'package:syncowe/models/reimbursement.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/models/transaction.dart' as syncowe_transaction;

class TripFirestoreService
{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final CollectionReference _trips = FirebaseFirestore.instance.collection("Trips").withConverter<Trip>(
    fromFirestore: Trip.fromFirestore,
    toFirestore: (trip, options) => (trip).toJson());

  Stream<QuerySnapshot> listenToTrips()
  {
    return _trips.where(NameofTrip.fieldSharedWith, arrayContains: _firebaseAuth.currentUser!.uid).snapshots();
  }

  Stream<Trip?> listenToTrip(String id)
  {
    return _trips.doc(id).snapshots().map((snapshot) => snapshot.data() as Trip);
  }

  Future<Trip?> getTrip(String id) async
  {
    Trip? trip;
    final docRef = getTripDoc(id);
    final doc = await docRef.get();
    
    if(doc.exists)
    {
      trip = doc.data() as Trip;
    }

    return trip;
  }

  DocumentReference getTripDoc(String id)
  {
    return _trips.doc(id);
  }

  Future<void> addOrUpdateTrip(Trip trip, String? id) async
  {
    if(id == null)
    {
      await _trips.add(trip);
    }
    else
    {
      await _trips.doc(id).set(trip);
    }
  }

  CollectionReference transactions(String tripId)
  {
    return getTripDoc(tripId).collection("Transactions").withConverter<syncowe_transaction.Transaction>(
      fromFirestore: syncowe_transaction.Transaction.fromFirestore, 
      toFirestore: (transaction, options) => transaction.toJson());
  }

  Stream<syncowe_transaction.Transaction?> listenToTransaction(String tripId, String id)
  {
    return transactions(tripId).doc(id).snapshots().map((snapshot) => snapshot.data() as syncowe_transaction.Transaction);
  }

  Future<syncowe_transaction.Transaction?> getTransaction(String tripId, String id) async
  {
    syncowe_transaction.Transaction? transaction;
    final docRef = getTransactionDoc(tripId, id);
    final doc = await docRef.get();

    if(doc.exists)
    {
      transaction = doc.data() as syncowe_transaction.Transaction;
    }

    return transaction;
  }

  DocumentReference getTransactionDoc(String tripId, String transactionId)
  {
    return transactions(tripId).doc(transactionId);
  }

  Stream<QuerySnapshot> listenToTransactions(String tripId)
  {
    return transactions(tripId).snapshots();
  }

  Future<String> addOrUpdateTransaction(syncowe_transaction.Transaction transaction, String tripId, String? id) async
  {
    if (id == null)
    {
      var doc = await transactions(tripId).add(transaction);
      return doc.id;
    }
    else
    {
      await transactions(tripId).doc(id).set(transaction);
      return id;
    }
  }

  CollectionReference reimbursements(String tripId)
  {
    return getTripDoc(tripId).collection("Reimbursements").withConverter<Reimbursement>(
      fromFirestore: Reimbursement.fromFirestore, 
      toFirestore: (reimbursement, options) => reimbursement.toJson());
  }

  Future<void> addOrUpdateReimbursement(Reimbursement reimbursement, String tripId, String? id) async
  {
    if(id == null)
    {
      await reimbursements(tripId).add(reimbursement);
    }
    else
    {
      await reimbursements(tripId).doc(id).set(reimbursement);
    }
  }

  Stream<QuerySnapshot> listenToReimbursements(String tripId)
  {
    return reimbursements(tripId).snapshots();
  }

  CollectionReference _overallDebts(String tripId)
  {
    return _trips.doc(tripId).collection("OverallDebts").withConverter<DebtPair>(
      fromFirestore: DebtPair.fromFirestore,
      toFirestore: (debtPair, options) => debtPair.toJson());
  }

  Stream<QuerySnapshot> listenToOverallDebts(String tripId)
  {
    return _overallDebts(tripId).snapshots();
  }

  CollectionReference _overallDebtSummary(String tripId, String debtPairId)
  {
    return _overallDebts(tripId).doc(debtPairId).collection("OverallDebtSummary")
      .withConverter<OverallDebtSummary>(
        fromFirestore: OverallDebtSummary.fromFirestore,
        toFirestore: (summary, options) => summary.toJson());
  }

  Stream<QuerySnapshot> listenToOverallDebtSummary(String tripId, String debtPairId, {bool archived = false})
  {
    return _overallDebtSummary(tripId, debtPairId)
      .where(NameofOverallDebtSummary.fieldArchived, isEqualTo: archived).snapshots();
  }
}