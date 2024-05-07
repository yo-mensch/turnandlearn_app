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

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        User? user = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (user != null) {
          setState(() {});
        }
      } on FirebaseAuthException catch (e) {
        _showDialog("Login Failed", e.message ?? "An error occurred.");
      }
    }
  }

  void _logout() async {
    await _authService.logout();
    setState(() {});
  }

  void _deactivateAccount() async {
    try {
      await _user?.delete();
      _logout(); // Logs out the user and clears the UI
    } catch (e) {
      _showDialog("Deactivation Failed", "Failed to deactivate account. ${e}");
    }
  }

  void _confirmDeactivation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Deactivation"),
        content: Text("Are you sure you want to deactivate your account? This cannot be undone."),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text("Deactivate"),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              _deactivateAccount();
            },
          ),
        ],
      ),
    );
  }

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
          ElevatedButton(
            onPressed: _confirmDeactivation,
            child: Text('Deactivate Account'),
            style: ElevatedButton.styleFrom(primary: Colors.red),
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
