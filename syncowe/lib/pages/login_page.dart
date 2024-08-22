import 'package:flutter/material.dart';
import 'package:syncowe/services/auth/auth_service.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget{
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
{

  // text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
    
  void signIn() async
  {
    final authService = Provider.of<AuthService>(context, listen: false);

    try
    {
      await authService.signInWIthEmailAndPassword(emailController.text, passwordController.text);
    }
    catch(e)
    {
      if(mounted)
      {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
  
  @override
  Widget build(BuildContext context){

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView
          (
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  // Login Icon
                  const Icon(Icons.login,
                    size: 80),

                  const SizedBox(height: 25),

                  // Header message  
                  const Text("Log in",
                    style: TextStyle(fontSize: 16)),

                  const SizedBox(height: 25),

                  // Email field
                  TextField(
                    controller: emailController, 
                    decoration: const InputDecoration(hintText: 'Email'),
                    obscureText: false
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
                  FilledButton(
                    onPressed: signIn,
                    child: const Text('Sign In')
                  ),
                  
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
                  )

                  // Register button
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}