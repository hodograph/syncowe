import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';
import 'package:syncowe/models/user.dart' as syncowe_user;

class AuthService extends ChangeNotifier{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserFirestoreService _userFirestoreService = UserFirestoreService();

  Future<UserCredential> signInWIthEmailAndPassword(String email, String password) async
  {
    try
    {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

      if( await _userFirestoreService.getUser(userCredential.user!.uid) == null)
      {
        _userFirestoreService.addOrUpdateUser(
          syncowe_user.User(displayName: userCredential.user!.displayName, email: email, id: userCredential.user!.uid, picture: userCredential.user!.photoURL)
        );
      }

      return userCredential;
    }
    on FirebaseAuthException catch (e)
    {
      throw Exception(e.code);
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(String email, String password, String name) async
  {
    try{
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      _userFirestoreService.addOrUpdateUser(
        syncowe_user.User(displayName: name, email: email, id: userCredential.user!.uid, picture: userCredential.user!.photoURL)
      );
      return userCredential;
    }
    on FirebaseAuthException catch(e)
    {
      throw Exception(e.code);
    }
  }

  Future<void> signOut() async
  {
    return await FirebaseAuth.instance.signOut();
  }
}