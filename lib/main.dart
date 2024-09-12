import 'package:cunehat/constants/routes.dart';
import 'package:cunehat/firestore/firestore_bloc/firestore_bloc.dart';
import 'package:cunehat/firestore/firestore_service.dart';
import 'package:cunehat/views/pages/app_bars.dart';
import 'package:cunehat/views/pages/home_tab_views/details_screen/details_screen.dart';
import 'package:cunehat/views/pages/home_tab_views/home_screen/home_screen.dart';
import 'package:cunehat/views/pages/home_tab_views/visalize_data_screen/visualize_data_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

int setCurrentPage = 1;

List<Widget> navigationDestinations = [
  const Icon(Icons.data_thresholding_outlined),
  const Icon(Icons.house),
  const Icon(Icons.bar_chart_sharp),
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();

  await Firebase.initializeApp();

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
    return RepositoryProvider(
      create: (context) => FirestoreService(),
      child: BlocProvider(
        create: (context) => FirestoreBloc(
          firestoreService: RepositoryProvider.of<FirestoreService>(context),
        ),
        child: MaterialApp(
          theme: ThemeData.dark(),
          title: "CuNehat",
          // initialRoute: '/', // starts with home page
          routes: {
            detailsUi: (context) => const DetailsScreen(),
            homeUi: (context) => const HomeScreen(),
            visualizeUi: (context) => const VisualizeDataScreen(),
            // instead of generating routing named ui like below,
            // we shows modalBottomSheet inplace
            // addExpenseUi: (context) => AddDataScreen(
            //       colorOfClass: colorOfClass,
            //       titleOfClass: titleOfClass,
            //       provider: provider,
            //       tagProvider: tagProvider,
            //     ),
          },
          debugShowCheckedModeBanner: false,
          home: Container(
            decoration: BoxDecoration(
              gradient: SweepGradient(
                endAngle: 9,
                startAngle: 2,
                center: Alignment.bottomLeft,
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
                backgroundColor: Colors.white70,
                child: ListView(children: [
                  UserAccountsDrawerHeader(
                    decoration: ShapeDecoration(
                      shape: Border.all(),
                    ),
                    accountName: Text(
                      '${FirebaseAuth.instance.currentUser?.displayName}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    accountEmail: const SizedBox.shrink(),
                    currentAccountPicture: CircleAvatar(
                      backgroundImage: NetworkImage(
                        FirebaseAuth.instance.currentUser?.providerData[0]
                                .photoURL ??
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
              body: const [
                DetailsScreen(),
                HomeScreen(),
                VisualizeDataScreen(),
              ][setCurrentPage],
            ),
          ),
        ),
      ),
    );
  }
}
