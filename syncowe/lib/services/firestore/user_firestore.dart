import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncowe/models/user.dart' as syncowe_user;

class UserFirestoreService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final CollectionReference users = FirebaseFirestore.instance.collection("Users").withConverter<syncowe_user.User>(
    fromFirestore: syncowe_user.User.fromFirestore,
    toFirestore: (user, options) => (user).toJson());

  Future<void> addOrUpdateUser(syncowe_user.User user) async{
    // Only let user update themselves.
    if(_firebaseAuth.currentUser!.uid == user.id)
    {
      await users.doc(user.id).set(user);
    }
  }

  String currentUserId()
  {
    return _firebaseAuth.currentUser!.uid;
  }

  Future<syncowe_user.User?> getUser(String? id) async
  {
    id ??= _firebaseAuth.currentUser!.uid;

    syncowe_user.User? user;
    final docRef = await users.doc(id).get();
    
    if(docRef.exists)
    {
      user = docRef.data() as syncowe_user.User;
    }

    return user;
  }

  Stream<syncowe_user.User> listenToUser(String? id)
  {
    id ??= _firebaseAuth.currentUser!.uid;
    return users.doc(id).snapshots().map(
      (snapshot) => snapshot.data()! as syncowe_user.User
    );
  }

  Stream<QuerySnapshot> listenToAllUsers()
  {
    return users.snapshots();
  }

  Stream<QuerySnapshot> listToUsers(List<String> ids)
  {
    return users.where(syncowe_user.NameofUser.fieldId, whereIn: ids).snapshots();
  }

  Future<Iterable<syncowe_user.User>> getUsers(List<syncowe_user.User> ignoreList) async
  {
    QuerySnapshot snapshot = await users.get();
    final allUsers = snapshot.docs.map((doc) => doc.data() as syncowe_user.User);

    return allUsers.where((user) => user.id != _firebaseAuth.currentUser!.uid && !ignoreList.any((ignore) => ignore.id == user.id));
  }
}