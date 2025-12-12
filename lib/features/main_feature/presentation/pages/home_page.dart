// lib/features/main_feature/presentation/pages/home_page.dart

import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transection_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/compare_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transection_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transection_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_list_page.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/main_feature/presentation/animations/cube_animation_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/date_range_indicator.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/slider_button_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/build_drawer.dart';
import 'package:cunehat/core/shared/widgets/shared_appbar.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/widgets/no_wallet_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    _loadWallets();
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

  void _loadWallets() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Load wallets (will trigger transaction loading in listener)
    context.read<WalletBloc>().add(GetWalletsEvent(userId));
  }

  void _loadTransactions(String userId, String walletId) {
    context.read<TransactionBloc>().add(
          GetTransactionsEvent(
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
            switch (walletState) {
              case WalletDeletedSt():
                SnackbarHelper.showSuccess(context, 'Cüzdan silindi!');

                _loadWallets();
                break;
              case WalletCreatedSt():
                SnackbarHelper.showSuccess(context, 'Cüzdan oluşturuldu!');
                _loadWallets();
                break;
              case WalletUpdatedSt():
                SnackbarHelper.showSuccess(context, 'Cüzdan güncellendi!');
                _loadWallets();
                break;
              default:
                break;
            }
          },
          builder: (context, walletState) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) {
              return const Center(child: Text('Kullanıcı girişi yapılmamış'));
            }
            switch (walletState) {
              case WalletLoadingSt():
                return const Center(child: CircularProgressIndicator());

              case WalletErrorSt():
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red[400]),
                      const SizedBox(height: 12),
                      Text(walletState.err),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadWallets,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                );

              case WalletLoadedSt():
                switch (walletState.activeWallet?.isActive) {
                  case true:
                    _loadTransactions(userId, walletState.activeWallet!.id);
                    return _buildBody(userId, walletState, context);
                  case false:
                    return NoWalletView(infoText: "Cüzdan seçiniz");
                  case null:
                    return NoWalletView(infoText: "Cüzdan oluşturunuz");
                }

              default:
                return const NoWalletView(
                  infoText: "Cüzdan oluşturunuz",
                );
            }
          },
        ),
      ),
    );
  }

  Column _buildBody(
      String userId, WalletLoadedSt walletState, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DateRangeIndicator(
          endDate: _endDate,
          startDate: _startDate,
          onTap: _showDateRangePicker,
        ),
        BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, transactionState) {
            switch (transactionState) {
              case TransactionActionSuccess():
                SnackbarHelper.showSuccess(context, transactionState.message);
                _loadTransactions(userId, walletState.activeWallet!.id);
                break;
              case TransactionError():
                SnackbarHelper.showError(context, transactionState.message);
                break;
            }
          },
          builder: (context, transactionState) {
            switch (transactionState) {
              case TransactionLoading():
                return const Center(child: CircularProgressIndicator());
              case TransactionError():
                return ErrorView(message: transactionState.message);

              case TransactionLoaded():
                return Expanded(
                  child: CubeAnimationView(
                    controller: _controller,
                    firstView: TransactionListPage(
                      type: TransactionTypeModel.expense,
                      userId: userId,
                      walletId: walletState.activeWallet!.id,
                      groupedTransactions: transactionState.groupedTransactions,
                    ),
                    secondView: TransactionListPage(
                      type: TransactionTypeModel.income,
                      userId: userId,
                      walletId: walletState.activeWallet!.id,
                      groupedTransactions: transactionState.groupedTransactions,
                    ),
                    thirdView: CompareView(
                      userId: userId,
                      wallet: walletState.activeWallet!,
                      startDate: _startDate,
                      endDate: _endDate,
                      allTransactions: transactionState.allTransactions,
                    ),
                  ),
                );

              default:
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
              walletState.activeWallet!,
            ),
          ),
        ),
      ],
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
