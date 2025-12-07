// // lib/features/main_feature/presentation/pages/home_page.dart

// import 'package:cunehat/features/compare/presentation/bloc/compare_bloc.dart';
// import 'package:cunehat/features/compare/presentation/page/compare_view.dart';
// import 'package:cunehat/features/old_main/presentation/animations/cube_animation_view.dart';
// import 'package:cunehat/features/old_main/presentation/widgets/date_range_indicator.dart';
// import 'package:cunehat/features/old_main/presentation/widgets/finance_entry_handler.dart';
// import 'package:cunehat/features/old_main/presentation/widgets/slider_button_view.dart';
// import 'package:cunehat/features/old_main/presentation/widgets/build_drawer.dart';
// import 'package:cunehat/core/shared/widgets/shared_appbar.dart';
// import 'package:cunehat/features/old_main/presentation/pages/expense_page.dart';
// import 'package:cunehat/features/old_main/presentation/pages/income_page.dart';
// import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
// import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
// import 'package:cunehat/models/expense_model.dart';
// import 'package:cunehat/models/income_model.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// // Dummy data için mock
// Map<DateTime, List<IncomeModel>> incomeData = {};
// Map<DateTime, List<ExpenseModel>> expenseData = {};

// /// **HomePage**: Main page with wallet-based data display
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   late DateTime _startDate;
//   late DateTime _endDate;

//   @override
//   void initState() {
//     super.initState();
//     _initAnimation();
//     _initDateRange();
//     _loadUserWallets();
//   }

//   void _initAnimation() {
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 750),
//       value: 0.5,
//     );
//   }

//   void _initDateRange() {
//     _endDate = DateTime.now();
//     _startDate = DateTime.now().subtract(const Duration(days: 30));
//   }

//   void _loadUserWallets() {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId != null) {
//       context.read<WalletBloc>().add(GetWalletsEvent(userId));
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Scaffold(
//         appBar: PreferredSize(
//           preferredSize: const Size(double.maxFinite, 50),
//           child: AnimatedBuilder(
//             animation: _controller,
//             builder: (context, child) {
//               return SharedAppbar(currentSliderValue: _controller.value);
//             },
//           ),
//         ),
//         drawer: const SharedDrawer(),
//         body: BlocBuilder<WalletBloc, WalletState>(
//           builder: (context, walletState) {
//             // Aktif cüzdanı bul
//             WalletModel? activeWallet;
//             if (walletState is WalletLoadedSt) {
//               activeWallet = walletState.wallets.firstWhere((w) => w.isActive,
//                   orElse: () => walletState.wallets.first);
//             }

//             return Column(
//               children: [
//                 DateRangeIndicator(
//                   endDate: _endDate,
//                   startDate: _startDate,
//                   onTap: () {
//                     // TODO: Date range picker
//                   },
//                 ),
//                 Expanded(
//                   child: activeWallet != null
//                       ? CubeAnimationView(
//                           controller: _controller,
//                           firstView: ExpenseView(expenseData: expenseData),
//                           secondView: IncomeView(incomeData: incomeData),
//                           thirdView: CompareView(
//                             userId: FirebaseAuth.instance.currentUser!.uid,
//                             wallet: activeWallet,
//                             startDate: _startDate,
//                             endDate: _endDate,
//                           ),
//                         )
//                       : const Center(
//                           child: Text('Cüzdan bulunamadı'),
//                         ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: SliderButtonEnhanced(
//                     controller: _controller,
//                     onTap: (value) => _handleSliderAction(context, value),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   void _handleSliderAction(BuildContext context, SliderState value) {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     // Aktif cüzdanı al
//     final walletState = context.read<WalletBloc>().state;
//     if (walletState is! WalletLoadedSt) return;

//     final activeWallet = walletState.wallets
//         .firstWhere((w) => w.isActive, orElse: () => walletState.wallets.first);

//     switch (value) {
//       case SliderState.compare:
//         // Compare view için veri yükle
//         context.read<CompareBloc>().add(
//               GetTransactionsEvent(
//                 userId: userId,
//                 walletId: activeWallet.id,
//                 startDate: _startDate,
//                 endDate: _endDate,
//               ),
//             );
//         break;
//       case SliderState.expense:
//         FinanceSheetHandler.showExpenseSheet(context);
//         break;
//       case SliderState.income:
//         FinanceSheetHandler.showIncomeSheet(context);
//         break;
//     }
//   }
// }
