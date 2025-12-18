import 'package:cunehat/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SharedDrawer extends StatelessWidget {
  const SharedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      elevation: 1,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ============ HEADER ============
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  backgroundImage: NetworkImage(
                    FirebaseAuth
                            .instance.currentUser?.providerData[0].photoURL ??
                        "assets/images/logo.jpg",
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.displayName ?? "Anonymous",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // ============ NAVIGATION ITEMS ============
          const Divider(),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Yatırım Takip'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.investment);
            },
          ),
        ],
      ),
    );
  }
}
