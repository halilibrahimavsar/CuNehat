// ==========================================
// UPDATED HOME PAGE
// ==========================================

// lib/features/main_feature/presentation/pages/home_page.dart
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_state.dart';
import 'package:cunehat/features/finance_transections/presentation/pages/compare_view.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_bloc.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_event.dart';
import 'package:cunehat/features/finance_transections/presentation/pages/transaction_list_page.dart';
import 'package:cunehat/features/finance_transections/presentation/widgets/compare_widgets/error_view.dart';
import 'package:cunehat/features/finance_transections/presentation/widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/main_feature/presentation/animations/cube_animation_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/date_range_indicator.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/slider_button_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/build_drawer.dart';
import 'package:cunehat/core/shared/widgets/shared_appbar.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// **HomePage**: Main page with wallet-based data display
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initDateRange();
    _loadUserData();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      value: 0.5, // Start at Compare view
    );
  }

  void _initDateRange() {
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
  }

  void _loadUserData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Load wallets
    context.read<WalletBloc>().add(GetWalletsEvent(userId));
  }

  void _loadTransactions(String userId, String walletId) {
    // Load all transactions (will be filtered in UI)
    context.read<TransactionBloc>().add(
          LoadTransactionsEvent(
            userId: userId,
            walletId: walletId,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size(double.maxFinite, 50),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SharedAppbar(currentSliderValue: _controller.value);
            },
          ),
        ),
        drawer: const SharedDrawer(),
        body: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, walletState) {
            // When wallet is loaded, load transactions
            if (walletState is WalletLoadedSt) {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                final activeWallet = walletState.wallets.firstWhere(
                  (w) => w.isActive,
                  orElse: () => walletState.wallets.first,
                );
                _loadTransactions(userId, activeWallet.id);
              }
            }
          },
          builder: (context, walletState) {
            if (walletState is WalletLoadingSt) {
              return const Center(child: CircularProgressIndicator());
            }

            if (walletState is WalletErrorSt) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 12),
                    Text(walletState.err),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadUserData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
            }

            if (walletState is WalletLoadedSt) {
              final activeWallet = walletState.wallets.firstWhere(
                (w) => w.isActive,
                orElse: () => walletState.wallets.first,
              );

              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId == null) {
                return const Center(child: Text('Kullanıcı girişi yapılmamış'));
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DateRangeIndicator(
                    endDate: _endDate,
                    startDate: _startDate,
                    onTap: _showDateRangePicker,
                  ),
                  BlocBuilder<TransactionBloc, TransactionState>(
                    builder: (context, transactionState) {
                      if (transactionState is TransactionLoaded) {
                        return Expanded(
                          child: CubeAnimationView(
                            controller: _controller,
                            firstView: TransactionListPage(
                              type: TransactionTypeModel.expense,
                              userId: userId,
                              walletId: activeWallet.id,
                              groupedTransactions:
                                  transactionState.groupedTransactions,
                            ),
                            secondView: TransactionListPage(
                              type: TransactionTypeModel.income,
                              userId: userId,
                              walletId: activeWallet.id,
                              groupedTransactions:
                                  transactionState.groupedTransactions,
                            ),
                            thirdView: CompareView(
                              userId: userId,
                              wallet: activeWallet,
                              startDate: _startDate,
                              endDate: _endDate,
                              allTransactions: transactionState.allTransactions,
                            ),
                          ),
                        );
                      } else if (transactionState is TransactionError) {
                        return ErrorView(message: transactionState.message);
                      } else if (transactionState is TransactionLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SliderButtonEnhanced(
                      controller: _controller,
                      onTap: (value) => _handleSliderAction(
                        context,
                        value,
                        userId,
                        activeWallet,
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text('Cüzdan bulunamadı'));
          },
        ),
      ),
    );
  }

  void _handleSliderAction(
    BuildContext context,
    SliderState value,
    String userId,
    WalletModel activeWallet,
  ) {
    switch (value) {
      case SliderState.compare:
        break;
      case SliderState.expense:
        TransactionSheetHandler.showExpenseSheet(
          context,
          userId,
          activeWallet.id,
        );
        break;
      case SliderState.income:
        TransactionSheetHandler.showIncomeSheet(
          context,
          userId,
          activeWallet.id,
        );
        break;
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Reload transactions with new date range
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final walletState = context.read<WalletBloc>().state;

      if (userId != null && walletState is WalletLoadedSt) {
        final activeWallet = walletState.wallets.firstWhere(
          (w) => w.isActive,
          orElse: () => walletState.wallets.first,
        );
        _loadTransactions(userId, activeWallet.id);
      }
    }
  }
}
