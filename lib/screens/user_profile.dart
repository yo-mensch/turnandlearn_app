import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: Text('Login/Register'),
        onPressed: () {
          // Navigator.push to Login/Register screen (to be implemented)
        },
      ),
    );
  }
}
