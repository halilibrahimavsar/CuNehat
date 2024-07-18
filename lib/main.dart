import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/filtering/current_month_range.dart';
import 'package:cunehat/firestore/firestore_service.dart';
import 'package:cunehat/views/pages/add_data_views/add_data_screen.dart';
import 'package:cunehat/views/pages/app_bars.dart';
import 'package:cunehat/views/pages/home_tab_views/details_screen/details_screen.dart';
import 'package:cunehat/views/pages/home_tab_views/home_screen/home_screen.dart';
import 'package:cunehat/views/pages/home_tab_views/visalize_data_screen/visualize_data_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// import 'package:intl/date_symbol_data_local.dart';

int setCurrentPage = 1;

Timestamp firstDateForFilterHome = Timestamp.fromMillisecondsSinceEpoch(
  DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).millisecondsSinceEpoch,
);
Timestamp lastDateForFilterHome = Timestamp.fromMillisecondsSinceEpoch(
  DateTime.now().add(const Duration(hours: 3)).millisecondsSinceEpoch,
);

List<Widget> navigationDestinations = [
  const Icon(Icons.data_thresholding_outlined),
  const Icon(Icons.house),
  const Icon(Icons.bar_chart_sharp),
];

void main() async {
  // initialize firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // // initialize turkey language for date and time
  // initializeDateFormatting('tr_TR', null);

  runApp(const CallFirebaseAuth(privateWidget: CuNehatEngine()));
}

class CuNehatEngine extends StatefulWidget {
  const CuNehatEngine({super.key});

  @override
  State<CuNehatEngine> createState() => _CuNehatEngineState();
}

class _CuNehatEngineState extends State<CuNehatEngine> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CuNehat",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.cyan),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      locale: const Locale('tr'),
      home: Container(
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
          appBar: const HomeAppbar(),
          drawer: Drawer(
            child: ListView(children: [
              UserAccountsDrawerHeader(
                decoration: ShapeDecoration(
                  shape: Border.all(),
                ),
                accountName: Text(
                  '${FirebaseAuth.instance.currentUser?.displayName}',
                  style: const TextStyle(color: Colors.black),
                ),
                accountEmail: Text(
                  '${FirebaseAuth.instance.currentUser?.displayName}',
                  style: const TextStyle(color: Colors.black),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(
                    FirebaseAuth
                            .instance.currentUser?.providerData[0].photoURL ??
                        "/assets/images/logo.jpg",
                  ),
                ),
              ),
              const ProfileUpdatePage(),
            ]),
          ),
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
      ),
      routes: {
        detailsUi: (context) => const DetailsScreen(),
        homeUi: (context) => HomeScreen(
              firstDate: currentMonthRange['firstDate']!,
              lastDate: currentMonthRange['lastDate']!,
            ),
        visualizeUi: (context) => const VisualizeDataScreen(),
        addExpenseUi: (context) => AddDataScreen(
              colorOfClass: Colors.red,
              titleOfClass: "Gider",
              provider: FirestoreService().addExpense,
              tagProvider: FirestoreService().getExpenseTags,
            ),
        addIncomeUi: (context) => AddDataScreen(
              colorOfClass: Colors.green,
              titleOfClass: "Gelir",
              provider: FirestoreService().addIncome,
              tagProvider: FirestoreService().getIncomeTags,
            ),
      },
    );
  }
}
