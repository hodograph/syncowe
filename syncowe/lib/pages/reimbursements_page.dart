import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncowe/models/reimbursement.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/auth/current_user.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class ReimbursementsPage extends ConsumerStatefulWidget {
  const ReimbursementsPage({super.key});

  @override
  ConsumerState<ReimbursementsPage> createState() => _ReimbursementsPage();
}

class _ReimbursementsPage extends ConsumerState<ReimbursementsPage> {
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  @override
  Widget build(BuildContext context) {
    User? currentUser = ref.watch(currentUserProvider);
    String? tripId = ref.watch(currentTripIdProvider);

    if (tripId == null || currentUser == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return FirestorePagination(
        limit: 15,
        padding: const EdgeInsets.only(bottom: 75),
        isLive: true,
        viewType: ViewType.list,
        query: _tripFirestoreService
            .reimbursements(tripId!)
            .orderBy(NameofReimbursement.fieldCreatedDate, descending: true),
        itemBuilder: (context, snapshots, index) {
          var users = ref.watch(tripUsersProvider);

          if (users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final reimbursement = snapshots[index].data() as Reimbursement;
          Widget? trailing;

          if (reimbursement.recipient == currentUser?.id &&
              !reimbursement.confirmed) {
            trailing = IconButton(
                onPressed: () async {
                  bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Reimbursement"),
                      content: Text(
                          "Confirm recieving ${reimbursement.amount} from ${users[reimbursement.payer]!.getDisplayString()}?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel")),
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Confirm")),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    reimbursement.confirmed = true;
                    _tripFirestoreService.addOrUpdateReimbursement(
                        reimbursement, tripId, snapshots[index].id);
                  }
                },
                icon: const Icon(
                  Icons.pending_outlined,
                  color: Colors.yellow,
                ));
          } else if (reimbursement.confirmed) {
            trailing = const Icon(
              Icons.check_box_outlined,
              color: Colors.green,
            );
          } else {
            trailing = const Icon(Icons.pending_outlined);
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(users[reimbursement.recipient]!.getDisplayString()),
              subtitle: Text(
                  "Received from: ${users[reimbursement.payer]!.getDisplayString()}"),
              leading: Text(
                NumberFormat.currency(locale: "en_US", symbol: "\$")
                    .format(reimbursement.amount),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              trailing: trailing,
            ),
          );
        });
  }
}
