import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/views/main_views/app_bars.dart';
import 'package:cunehat/views/main_views/home_tab_views/details_screen/details_screen.dart';
import 'package:cunehat/views/main_views/home_tab_views/home_screen/home_screen.dart';
import 'package:cunehat/views/main_views/home_tab_views/visalize_data_screen/visualize_data_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

int setCurrentPage = 1;

Timestamp firstDateForFilterHome = Timestamp.now();
Timestamp lastDateForFilterHome = Timestamp.now();

List<Widget> navigationDestinations = [
  const Icon(Icons.data_thresholding_outlined),
  const Icon(Icons.house),
  const Icon(Icons.bar_chart_sharp),
];

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final String? uid;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userPhoto =
        user?.providerData[0].photoURL ?? "/assets/images/logo.jpg";
    return Container(
      decoration: BoxDecoration(
        gradient: SweepGradient(
          endAngle: 9,
          startAngle: 2,
          center: Alignment.bottomLeft,
          tileMode: TileMode.clamp,
          colors: [
            Colors.black12,
            Colors.black12,
            Colors.blue.shade900,
            Colors.black12,
            Colors.purple.shade900,
            Colors.black12,
            Colors.blue,
            Colors.black12,
            Colors.black12,
            Colors.black,
          ],
        ),
      ),
      child: Scaffold(
        appBar: <PreferredSizeWidget>[
          DetailsAppbar(
            userPhoto: userPhoto,
            user: user,
            appBar: AppBar(),
          ),
          HomeAppbar(
            userPhoto: userPhoto,
            user: user,
            appBar: AppBar(),
            sendDataToParrent: (Map<String, DateTime> data) {
              setState(() {
                firstDateForFilterHome = Timestamp.fromDate(data['firstDate']!);
                lastDateForFilterHome = Timestamp.fromDate(data['lastDate']!);
                log(firstDateForFilterHome.toDate().toString());
                log(lastDateForFilterHome.toDate().toString());
              });
            },
          ),
          VisualizeAppbar(
            userPhoto: userPhoto,
            user: user,
            appBar: AppBar(),
          ),
        ][setCurrentPage],
        bottomNavigationBar: CurvedNavigationBar(
          items: navigationDestinations,
          onTap: (value) {
            setState(() {
              setCurrentPage = value;
            });
          },
          index: setCurrentPage,
          backgroundColor: Colors.transparent,
          color: Colors.indigo.withOpacity(0.7),
        ),
        backgroundColor: Colors.transparent,
        body: [
          const DetailsScreen(),
          HomeScreen(
            firstDate: firstDateForFilterHome,
            lastDate: lastDateForFilterHome,
          ),
          const VisualizeDataScreen(),
        ][setCurrentPage],
      ),
    );
  }
}
