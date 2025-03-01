import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:syncowe/services/auth/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signIn() async {
    final authService = ref.read(authServiceProvider.notifier);

    try {
      await authService.signInWIthEmailAndPassword(
          emailController.text, passwordController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> signInWithGoogle() async {
    final authService = ref.read(authServiceProvider.notifier);

    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> signInWithApple() async {
    final authService = ref.read(authServiceProvider.notifier);

    try {
      await authService.signInWithApple();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              children: [
                const SizedBox(height: 25),

                // Header message
                const Text("Log in", style: TextStyle(fontSize: 16)),

                const SizedBox(height: 25),

                // Email field
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: 'Email'),
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 10),

                // Password field
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(hintText: 'Password'),
                  obscureText: true,
                  onFieldSubmitted: (password) => signIn(),
                ),

                const SizedBox(height: 25),

                // Sign in button
                FilledButton(onPressed: signIn, child: const Text('Sign In')),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Not a member?"),
                    const SizedBox(width: 4),
                    TextButton(
                        onPressed: widget.onTap,
                        child: const Text("Create Account"))
                  ],
                ),

                const SizedBox(
                  height: 25,
                ),
                const Divider(),
                const SizedBox(
                  height: 25,
                ),

                SignInButton(
                    Theme.of(context).brightness == Brightness.light
                        ? Buttons.Google
                        : Buttons.GoogleDark,
                    onPressed: signInWithGoogle),
                const SizedBox(
                  height: 25,
                ),
                SignInButton(
                  Theme.of(context).brightness == Brightness.light
                      ? Buttons.Apple
                      : Buttons.AppleDark,
                  onPressed: signInWithApple,
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
