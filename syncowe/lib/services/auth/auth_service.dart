import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';
import 'package:syncowe/models/user.dart' as syncowe_user;
part 'auth_service.g.dart';

@riverpod
class AuthService extends _$AuthService{

  @override
  Object? build() => AuthService();

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

  Future<UserCredential> signInWithGoogle() async
  {
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication gAuth = await gUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    if( await _userFirestoreService.getUser(userCredential.user!.uid) == null)
    {
      _userFirestoreService.addOrUpdateUser(
        syncowe_user.User(
          displayName: userCredential.user!.displayName, 
          email: userCredential.user!.email!, 
          id: userCredential.user!.uid, 
          picture: userCredential.user!.photoURL)
      );
    }

    return userCredential;
  }

  Future<UserCredential> signInWithApple() async
  {
    UserCredential userCredential;

    if (kIsWeb)
    {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: "SyncOwe", 
          redirectUri: Uri.parse("${Uri.base}__/auth/handler")
        )
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode
      );

      userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    }
    else
    {
      final provider = AppleAuthProvider();
      provider.addScope('email');
      provider.addScope('name');

      userCredential = await FirebaseAuth.instance.signInWithProvider(provider);
    }
    

    if( await _userFirestoreService.getUser(userCredential.user!.uid) == null)
    {
      _userFirestoreService.addOrUpdateUser(
        syncowe_user.User(
          displayName: userCredential.user!.displayName, 
          email: userCredential.user!.email ?? "Unknown", 
          id: userCredential.user!.uid, 
          picture: userCredential.user!.photoURL)
      );
    }

    return userCredential;
  }
}