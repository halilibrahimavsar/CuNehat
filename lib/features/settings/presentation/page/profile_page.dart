import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil ayarları"),
      ),
      body: ProfileUpdatePage(),
    );
  }
}
