import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:turn_and_learn/screens/registration_screen.dart';
import 'package:turn_and_learn/screens/saved_products_screen.dart';
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
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirestoreAuthService _authService = FirestoreAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _products = [];
  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _loadUserProducts();
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        User? user = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (user != null) {
          setState(() {});
          _emailController.text = '';
          _passwordController.text = '';
        } else {
          _showDialog("Login failed", "User with these credentials not found");
        }
      } on FirebaseAuthException catch (e) {
        _showDialog("Login Failed", e.message ?? "An error occurred.");
      }
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Password"),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: _oldPasswordController,
                decoration: InputDecoration(hintText: "Enter old password"),
                obscureText: true,
              ),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(hintText: "Enter new password"),
                obscureText: true,
              ),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(hintText: "Confirm new password"),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(ctx).pop();
              _oldPasswordController.text = '';
              _newPasswordController.text = '';
              _confirmPasswordController.text = '';
            },
          ),
          TextButton(
            child: Text("Submit"),
            onPressed: () async {
              if (_newPasswordController.text == _confirmPasswordController.text && _newPasswordController.text.isNotEmpty) {
                try {
                  // Reauthenticate user before changing password
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: _user!.email!,
                    password: _oldPasswordController.text,
                  );

                  await _user!.reauthenticateWithCredential(credential);
                  await _user!.updatePassword(_newPasswordController.text);
                  Navigator.of(ctx).pop();
                  _showDialog("Success", "Password updated successfully.");
                } catch (e) {
                  _showDialog("Error", "Failed to update password. ${e}");
                }
              } else {
                _showDialog("Error", "Passwords do not match or are empty.");
              }
            },
          ),
        ],
      ),
    );
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

  Future<void> _loadUserProducts() async {
    var querySnapshot = await _firestore.collection('products')
        .where('userId', isEqualTo: _user?.uid)
        .get();

    setState(() {
      _products = querySnapshot.docs;
    });
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
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your email';
              }
              // Regular expression for email validation
              String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
              RegExp regex = RegExp(pattern);
              if (!regex.hasMatch(value!)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
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
          Text('Logged in as: ${_user?.email}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),  // Padding between text and first button
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SavedProductsScreen())),
            child: Text('View Saved Products'),
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
              minimumSize: Size(240, 48),  // Fixed width and height
            ),
          ),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: _changePassword,
            child: Text('Change password'),
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
              minimumSize: Size(240, 48),  // Fixed width and height
            ),
          ),
          SizedBox(height: 15),  // Padding between buttons
          ElevatedButton(
            onPressed: _logout,
            child: Text('Logout'),
            style: ElevatedButton.styleFrom(
              primary: Colors.red,
              minimumSize: Size(240, 48),  // Fixed width and height
            ),
          ),
          SizedBox(height: 15),  // Padding between buttons
          OutlinedButton(
            onPressed: _confirmDeactivation,
            child: Text('Deactivate Account'),
            style: OutlinedButton.styleFrom(
              primary: Colors.red,
              minimumSize: Size(240, 48),  // Fixed width and height
              side: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          SizedBox(height: 20),  // Padding below the last button
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
