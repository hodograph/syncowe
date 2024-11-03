import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/services/auth/auth_service.dart';

class RegisterPage extends ConsumerStatefulWidget{
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
{

  // text controllers
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmationController = TextEditingController();

  void signUp() async
  {
    if(passwordController.text != passwordConfirmationController.text)
    {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
    }
    else
    {
      final authService = ref.read(authServiceProvider.notifier);
      try
      {
        await authService.signUpWithEmailAndPassword(emailController.text, passwordController.text, nameController.text);
      }
      catch(e) 
      {
        if(mounted)
        {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
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
                  const Text("Create Account",
                    style: TextStyle(fontSize: 16)),

                  const SizedBox(height: 25),

                  // Email field
                  TextField(
                    controller: emailController, 
                    decoration: const InputDecoration(hintText: 'Email'),
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 10),

                  // Name field
                  TextField(
                    controller: nameController, 
                    decoration: const InputDecoration(hintText: 'Full Name'),
                    obscureText: false
                  ),

                  const SizedBox(height: 10),

                  // Password field
                  TextField(
                    controller: passwordController, 
                    decoration: const InputDecoration(hintText: 'Password'),
                    obscureText: true
                  ),

                  const SizedBox(height: 10),

                  // Password confirmation field
                  TextFormField(
                    controller: passwordConfirmationController, 
                    decoration: const InputDecoration(hintText: 'Confirm Password'),
                    obscureText: true,
                    onFieldSubmitted: (password) => signUp(),
                  ),

                  const SizedBox(height: 25),
                  
                  // Sign up button
                  FilledButton(
                    onPressed: signUp,
                    child: const Text('Sign Up')
                  ),
                  
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already a member?"),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: widget.onTap, 
                        child: const Text("Login now")
                      )
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