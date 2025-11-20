import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/auth_service.dart'; // Import AuthService

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for form fields
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Instance of AuthService to handle Firebase operations
  final AuthService _authService = AuthService();

  // Loading state to show spinner during sign up
  bool isLoading = false;

  /// Validate password strength
  /// Returns true if password is strong enough
  bool _isPasswordStrong(String password) {
    // Password must be at least 6 characters
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return false;
    }
    return true;
  }

  /// Handle the Sign Up button press
  void _handleSignUp() async {
    // Validate that all fields are filled
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Validate that passwords match
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Validate password strength
    if (!_isPasswordStrong(passwordController.text)) {
      return;
    }

    // Show loading spinner
    setState(() {
      isLoading = true;
    });

    // Attempt to sign up with Firebase
    var user = await _authService.signUpWithEmail(
      emailController.text,
      passwordController.text,
    );

    // Hide loading spinner
    setState(() {
      isLoading = false;
    });

    // Check if sign up was successful
    if (user != null) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully!')),
      );

      // Navigate to HomeScreen after successful sign up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      // Show error message if sign up failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed. Try again!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SIGN UP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Gender equality icon
              Icon(Icons.transgender, size: 80),
              SizedBox(height: 20),

              // Name input field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Email input field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),

              // Password input field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  hintText: "At least 6 characters",
                ),
                obscureText: true, // Hide password characters
              ),
              SizedBox(height: 16),

              // Confirm Password input field
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // Hide password characters
              ),
              SizedBox(height: 24),

              // Sign Up button with loading indicator
              isLoading
                  ? CircularProgressIndicator() // Show spinner while loading
                  : ElevatedButton(
                      child: Text("Sign Up"),
                      onPressed: _handleSignUp, // Call sign up handler
                    ),
              SizedBox(height: 16),

              // Navigate back to Sign In screen
              TextButton(
                child: Text("Already have an account? Sign in"),
                onPressed: () {
                  Navigator.pop(context); // Go back to SignIn
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}