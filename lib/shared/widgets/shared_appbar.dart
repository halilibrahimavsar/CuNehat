// ignore_for_file: depend_on_referenced_packages

import 'package:cunehat/shared/widgets/date_rang_pck.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class SharedAppbar extends StatefulWidget implements PreferredSizeWidget {
  const SharedAppbar({super.key});

  @override
  State<SharedAppbar> createState() => _SharedAppbarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 50);
}

class _SharedAppbarState extends State<SharedAppbar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // hide drawer menu icon
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: CircleAvatar(
                backgroundImage: NetworkImage(
              FirebaseAuth.instance.currentUser?.providerData[0].photoURL ??
                  "assets/images/logo.jpg",
            )),
          ),
          const SizedBox(width: 10),
          Text(
            FirebaseAuth.instance.currentUser?.displayName ?? "Anonymous",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () async {
            var dates = await getDateRange(context);
            setState(() {
              filterStartDate = dates['firstDate']!;
              filterEndDate = dates['lastDate']!;
            });
          },
          icon: const Icon(
            Icons.filter_list_outlined,
          ),
        )
      ],
    );
  }
}
