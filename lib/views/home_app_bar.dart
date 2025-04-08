import 'package:cunehat/views/view_utilities/date_rang_pck.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

// TODO Home page will be responsible for showing-adding expense and income,
/// detail page will be responsible for shows expense-income and difference between them. We should also add tag differences
/// dashboard page will be responsible for showing the online finance, gold etc...
///    - dashboard will contain a menu for redirecting user to the setting, help, finance, theme...

class HomeAppbar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppbar({super.key});

  @override
  State<HomeAppbar> createState() => _HomeAppbarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 50);
}

class _HomeAppbarState extends State<HomeAppbar> {
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
                    "/assets/images/logo.jpg",
              ),
            ),
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
            ))
      ],
      backgroundColor: Colors.indigo.withOpacity(0.6),
    );
  }
}
