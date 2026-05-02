import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/models/user.dart' as syncowe_user;
import 'package:syncowe/pages/home_page.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final UserFirestoreService userFirestoreService = UserFirestoreService();
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // User is not signed in
            return SignInScreen(
              providers: [
                EmailAuthProvider(),
                // IMPORTANT: Replace "YOUR_WEB_CLIENT_ID" with your actual Google Web OAuth 2.0 client ID.
                // You can find this in your Google Cloud Console under "APIs & Services" > "Credentials".
                // This ID is typically used for web applications but is also often required by the
                // firebase_ui_oauth_google package for mobile platforms to work correctly with Google Sign-In.
                // Example: "1234567890-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com"
                // If you haven't set up Google Sign-In in Firebase and Google Cloud Console,
                // you'll need to do that first.
                // See: https://firebase.google.com/docs/auth/web/google-signin
                // and https://pub.dev/packages/firebase_ui_oauth_google
                GoogleProvider(
                  clientId:
                      "134068539303-j1b2q171ns7s6jj1v93uck83cclglvat.apps.googleusercontent.com",
                ),
                AppleProvider(),
              ],
              headerBuilder: (context, constraints, shrinkOffset) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    // Added Center for better visual
                    child: Text(
                      'Trip Planner',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    // Optional: Replace with your app logo
                    // child: AspectRatio(
                    //   aspectRatio: 1,
                    //   child: Image.asset('assets/your_logo.png'),
                    // ),
                  ),
                );
              },
              subtitleBuilder: (context, action) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child:
                      action == AuthAction.signIn
                          ? const Text(
                            'Welcome back, please sign in to continue!',
                          )
                          : const Text('Create an account to plan your trips!'),
                );
              },
              footerBuilder: (context, action) {
                return const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'By signing in, you agree to our terms and conditions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
            );
          }

          // User is signed in
          final user = snapshot.data!;
          // Ensure user document exists in Firestore
          // This is a "fire and forget" call, meaning we don't wait for it to complete
          // before rendering the HomePage. It will happen in the background.
          userFirestoreService.addOrUpdateUser(syncowe_user.User(displayName: user.displayName, email: user.email!, id: user.uid, picture: user.photoURL));

          return const HomePage(); // Render your application
        }
      ),
    );
  }
}