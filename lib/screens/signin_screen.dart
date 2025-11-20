import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart'; // Import the AuthService

class SignInScreen extends StatefulWidget {
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Controllers to capture user input
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Instance of AuthService to handle Firebase operations
  final AuthService _authService = AuthService();

  // Loading state to show spinner during sign in
  bool isLoading = false;

  /// Handle the Sign In button press
  void _handleSignIn() async {
    // Validate that both fields are filled
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Show loading spinner
    setState(() {
      isLoading = true;
    });

    // Attempt to sign in with Firebase
    var user = await _authService.signInWithEmail(
      emailController.text,
      passwordController.text,
    );

    // Hide loading spinner
    setState(() {
      isLoading = false;
    });

    // Check if sign in was successful
    if (user != null) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${user.email}!')),
      );

      // Navigate to HomeScreen after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      // Show error message if sign in failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed. Check your email/password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SIGN IN")), // Top bar title
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Gender equality icon
              Icon(Icons.transgender, size: 80),
              SizedBox(height: 20),

              // Email input field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Password input field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // Hide password characters
              ),
              SizedBox(height: 8),

              // Forgot Password button
              TextButton(
                onPressed: () {
                  // TODO: Implement forgot password functionality
                },
                child: Text("Forgot Password?"),
              ),
              SizedBox(height: 20),

              // Sign In button with loading indicator
              isLoading
                  ? CircularProgressIndicator() // Show spinner while loading
                  : ElevatedButton(
                      child: Text("Sign In"),
                      onPressed: _handleSignIn, // Call sign in handler
                    ),
              SizedBox(height: 16),

              // Navigate to Sign Up screen
              TextButton(
                child: Text("Don't have an account? Sign up"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignUpScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}