import 'package:flutter/material.dart';
import 'package:turn_and_learn/screens/registration_screen.dart';
import 'package:turn_and_learn/services/firestore_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirestoreAuthService _authService = FirestoreAuthService();

  // Gets the current user from FirebaseAuth
  User? get _user => FirebaseAuth.instance.currentUser;

  // Login function
  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        User? user = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (user != null) {
          setState(() {
            // User is automatically updated in _user via FirebaseAuth
          });
        }
      } on FirebaseAuthException catch (e) {
        _showDialog("Login Failed", e.message ?? "An error occurred.");
      }
    }
  }

  // Logout function
  void _logout() async {
    await _authService.logout();
    setState(() {
    });
  }

  // Dialog to display messages
  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _user == null ? _buildLoginForm() : _buildUserPanel(),
      ),
    );
  }

  // Builds the login form
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) => value?.isEmpty ?? true ? 'Please enter your email' : null,
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
            validator: (value) => value?.isEmpty ?? true ? 'Please enter your password' : null,
          ),
          ElevatedButton(
            onPressed: _login,
            child: Text('Login'),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationScreen())),
            child: Text('Create Account'),
          ),
        ],
      ),
    );
  }

  // Builds user panel when logged in
  Widget _buildUserPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Logged in as: ${_user?.uid}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: _logout,
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
