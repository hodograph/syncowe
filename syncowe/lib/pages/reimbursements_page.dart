import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncowe/models/reimbursement.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class ReimbursementsPage extends StatefulWidget
{
  final String tripId;

  const ReimbursementsPage({super.key, required this.tripId});

  @override
  State<StatefulWidget> createState() => _ReimbursementsPage();
}

class _ReimbursementsPage extends State<ReimbursementsPage>
{
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();
  final UserFirestoreService _userFirestoreService = UserFirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder
    (
      stream: _tripFirestoreService.listenToReimbursements(widget.tripId), 
      builder: (context, snapshot)
      {
        if (snapshot.hasError) 
        {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        else if (!snapshot.hasData) 
        {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        else
        {
          final reimbursements = snapshot.data!.docs.where((doc) => doc.data() is Reimbursement).toList();
          if (reimbursements.isEmpty)
          {
            return const Center(
              child: Text("There are no reimbursements in this trip."),
            );
          }

          
          reimbursements.sort((a, b) => 
            ((a.data() as Reimbursement).createdDate as DateTime).compareTo((b.data() as Reimbursement).createdDate as DateTime));

          return StreamBuilder
          (
            stream: _userFirestoreService.listToUsers(Provider.of<Trip?>(context)?.sharedWith ?? []), 
            builder: (context, snapshot)
            {
              if (snapshot.hasError) 
              {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              else if (!snapshot.hasData) 
              {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              else
              {
                Map<String, User> users = { for (var doc in snapshot.data!.docs) doc.id : doc.data() as User };

                return ListView.builder
                (
                  itemCount: reimbursements.length,
                  itemBuilder: (context, index) 
                  {
                    final reimbursement = reimbursements[index] as Reimbursement;
                    Widget? trailing;

                    if (reimbursement.recipient == _userFirestoreService.currentUserId() && !reimbursement.confirmed)
                    {
                      trailing = IconButton(onPressed: () async
                      {
                        bool? confirmed = await showDialog<bool>
                        (
                          context: context,
                          builder: (context) => AlertDialog
                          (
                            title: const Text ("Confirm Reimbursement"),
                            content: Text("Confirm recieving ${reimbursement.amount} from ${users[reimbursement.payer]!.getDisplayString()}?"),
                            actions: 
                            [
                              TextButton
                              (
                                onPressed: () => Navigator.of(context).pop(false), 
                                child: const Text("Cancel")
                              ),
                              TextButton
                              (
                                onPressed: () => Navigator.of(context).pop(true), 
                                child: const Text("Confirm")
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true)
                        {
                          reimbursement.confirmed = true;
                          _tripFirestoreService.addOrUpdateReimbursement(reimbursement, widget.tripId, reimbursements[index].id);
                        }
                      }, 
                      icon: const Icon(Icons.pending_outlined, color: Colors.yellow,));
                    }
                    else if(reimbursement.confirmed)
                    {
                      trailing = const Icon(Icons.check_box_outlined, color: Colors.green,);
                    }
                    else
                    {
                      trailing = const Icon(Icons.pending_outlined);
                    }

                    return ListTile(
                      title: Text(users[reimbursement.recipient]!.getDisplayString()),
                      subtitle: Text("Received from: ${users[reimbursement.payer]!.getDisplayString()}"),
                      leading: Text(
                        NumberFormat.currency(
                          locale: "en_US", 
                          symbol: "\$")
                        .format(reimbursement.amount),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      trailing: trailing
                    );
                  }
                );
              }
            }
          );
        }
      }
    );
  }
}