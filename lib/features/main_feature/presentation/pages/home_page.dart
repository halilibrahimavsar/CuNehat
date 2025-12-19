import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/shared/widgets/date_range_picker.dart';
import 'package:cunehat/core/utilities/date_range_helper.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/compare_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_list_page.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/core/shared/animations/cube_animation_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/slider_button_view.dart';
import 'package:cunehat/core/shared/widgets/build_drawer.dart';
import 'package:cunehat/core/shared/widgets/shared_appbar.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
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
  TransactionViewType _currentViewType = TransactionViewType.list;

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
    final now = DateRangeHelper.getMonthRange(DateTime.now());
    _startDate = now['firstDate']!;
    _endDate = now['lastDate']!;
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
    final scaffoldKey = GlobalKey<AnimatedScaffoldWrapperState>();

    return SafeArea(
      top: false,
      child: AnimatedScaffoldWrapper(
        key: scaffoldKey,
        drawer: const ModernSharedDrawer(),
        appBar: PreferredSize(
          preferredSize: const Size(double.maxFinite, 50),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ModernSharedAppbar(currentSliderValue: _controller.value);
            },
          ),
        ),
        child: BlocConsumer<WalletBloc, WalletState>(
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
              case WalletErrorSt():
                SnackbarHelper.showError(context, walletState.err);
                break;
              default:
                break;
            }
          },
          builder: (context, walletState) {
            switch (walletState) {
              case WalletLoadingSt():
                return const Center(child: CircularProgressIndicator());

              case WalletErrorSt():
                return ErrorView(
                  message: walletState.err,
                  onPressed: _loadWallets,
                  buttonText: "Tekrar Dene",
                  customIcon: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                );

              case WalletLoadedSt():
                final userId = walletState.wallets.first.userId;
                final activeWalletId = walletState.activeWallet!.id;

                switch (walletState.activeWallet?.isActive) {
                  case false:
                    return const NoWalletView(infoText: "Cüzdan seçiniz");
                  case null:
                    return const NoWalletView(infoText: "Cüzdan oluşturunuz");
                  case true:
                    _loadTransactions(userId, activeWalletId!);
                    return _buildBody(
                      context: context,
                      userId: userId,
                      walletState: walletState,
                    );
                }

              default:
                return const NoWalletView(infoText: "Cüzdan oluşturunuz");
            }
          },
        ),
      ),
    );
  }

  Column _buildBody({
    required BuildContext context,
    required String userId,
    required WalletLoadedSt walletState,
  }) {
    final String walletId = walletState.activeWallet!.id!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ✅ UPDATED: Use shared DateRangeIndicator
        FilterView(
          endDate: _endDate,
          startDate: _startDate,
          currentViewType: _currentViewType,
          onViewTypeChanged: (newType) {
            setState(() {
              _currentViewType = newType;
            });
          },
          onDateTap: () => _showDateRangePicker(userId, walletId),
        ),
        BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, transactionState) {
            switch (transactionState) {
              case TransactionActionSuccess():
                SnackbarHelper.showSuccess(context, transactionState.message);
                _loadTransactions(userId, walletId);
                _loadWallets(); // update balance
                break;
              case TransactionError():
                SnackbarHelper.showError(context, transactionState.message);
                break;
            }
          },
          builder: (context, transactionState) {
            switch (transactionState) {
              case TransactionLoading():
                return const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              case TransactionError():
                return Expanded(
                  child: ErrorView(message: transactionState.message),
                );

              case TransactionLoaded():
                return Expanded(
                  child: CubeAnimationView(
                    controller: _controller,
                    firstView: TransactionListPage(
                      key: const ValueKey('expense-list'), // ✅ Unique key
                      type: TransactionTypeModel.expense,
                      userId: userId,
                      wallet: walletState.activeWallet!,

                      allTransactions:
                          transactionState.allTransactions, // ✅ Veriyi geç
                      viewType: _currentViewType,
                    ),
                    secondView: TransactionListPage(
                      key: const ValueKey('income-list'), // ✅ Unique key
                      type: TransactionTypeModel.income,
                      userId: userId,
                      wallet: walletState.activeWallet!,
                      allTransactions:
                          transactionState.allTransactions, // ✅ Veriyi geç
                      viewType: _currentViewType,
                    ),
                    thirdView: CompareView(
                      key: const ValueKey('compare-view'), // ✅ Unique key
                      userId: userId,
                      wallet: walletState.activeWallet!,
                      startDate: _startDate,
                      endDate: _endDate,
                      allTransactions:
                          transactionState.allTransactions, // ✅ Veriyi geç
                      viewType: _currentViewType,
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
    WalletEntity activeWallet,
  ) {
    switch (value) {
      case SliderState.compare:
        break;
      case SliderState.expense:
        TransactionSheetHandler.showExpenseSheet(
          context,
          userId,
          activeWallet.id!,
        );
        break;
      case SliderState.income:
        TransactionSheetHandler.showIncomeSheet(
          context,
          userId,
          activeWallet.id!,
        );
        break;
    }
  }

  /// ✅ UPDATED: Use shared DateRangePicker
  Future<void> _showDateRangePicker(String userId, String walletId) async {
    await showDateRangePickerBottomSheet(
      context: context,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
      onDateRangeSelected: (startDate, endDate) {
        setState(() {
          _startDate = startDate;
          _endDate = endDate;
        });

        // Reload transactions with new date range
        _loadTransactions(userId, walletId);
      },
    );
  }
}
