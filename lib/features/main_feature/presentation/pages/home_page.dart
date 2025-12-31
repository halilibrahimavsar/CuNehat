import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/shared/widgets/date_range_picker.dart';
import 'package:cunehat/core/utilities/date_range_helper.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/compare_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_event.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/core/shared/animations/cube_animation_view.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_investment_dialog.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/slider_button_view.dart';
import 'package:cunehat/core/shared/widgets/build_drawer.dart';
import 'package:cunehat/core/shared/widgets/shared_appbar.dart';
import 'package:cunehat/features/main_feature/presentation/widgets/transaction_view_type.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_money_page.dart';
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
  late TransactionFilter _filter;
  bool _isFilterMenuOpen = false;

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
    final range = DateRangeHelper.getMonthRange(DateTime.now());
    _filter = TransactionFilter(
      financeMode: FinanceMode.compare,
      viewType: TransactionViewType.list,
      startDate: range.start,
      endDate: range.end,
    );
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
            startDate: _filter.startDate,
            endDate: _filter.endDate,
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
                var filteredTransactions = transactionState.allTransactions;

                // Kategori Filtresi
                if (_filter.selectedCategories.isNotEmpty) {
                  filteredTransactions = filteredTransactions
                      .where((t) => _filter.selectedCategories.contains(t.tag))
                      .toList();
                }

                // Fiyat Filtresi
                if (_filter.priceRange != null) {
                  filteredTransactions = filteredTransactions
                      .where((t) => _filter.priceRange!.isInRange(t.amount))
                      .toList();
                }

                return Expanded(
                  child: CubeAnimationView(
                    controller: _controller,
                    firstView: SaveMoneyPage(
                      key: const ValueKey('save-view'), // ✅ Unique key
                      wallet: walletState.activeWallet!,
                    ),
                    secondView: Text(" 2. View "),
                    thirdView: TransactionsPage(
                      key: const ValueKey('compare-view'), // ✅ Unique key
                      userId: userId,
                      wallet: walletState.activeWallet!,
                      startDate: _filter.startDate,
                      endDate: _filter.endDate,
                      allTransactions: filteredTransactions, // ✅ Veriyi geç
                      viewType: _filter.viewType,
                      mode: _filter.financeMode,
                      filterWidget: FilterView(
                        filter: _filter,
                        onFilterChanged: (newFilter) =>
                            setState(() => _filter = newFilter),
                        onDateTap: () => _showDateRangePicker(userId, walletId),
                        isMenuOpen: _isFilterMenuOpen,
                        onMenuToggle: () => setState(() {
                          _isFilterMenuOpen = !_isFilterMenuOpen;
                        }),
                      ),
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
            miniButtons: {
              SliderState.savedMoney: [
                MiniButtonData(
                  icon: Icons.inventory_sharp,
                  label: 'Birikim',
                  color: Colors.red,
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) {
                      return AddInvestmentDialog(
                        onAddInvestment: (investment) {
                          context
                              .read<InvestmentBloc>()
                              .add(CreateInvestmentEvent(investment));
                        },
                      );
                    },
                  ),
                ),
              ],
              SliderState.transactions: [
                MiniButtonData(
                  icon: Icons.remove,
                  label: 'Gider',
                  color: Colors.red,
                  onTap: () {
                    TransactionSheetHandler.showExpenseSheet(
                      context,
                      userId,
                      walletId,
                    );
                  },
                ),
                MiniButtonData(
                  icon: Icons.add,
                  label: 'Gelir',
                  color: Colors.green,
                  onTap: () {
                    TransactionSheetHandler.showIncomeSheet(
                      context,
                      userId,
                      walletId,
                    );
                  },
                ),
              ],
              SliderState.debt: [
                MiniButtonData(
                  icon: Icons.add,
                  label: 'Gelir',
                  color: Colors.green,
                  onTap: () {},
                ),
                MiniButtonData(
                  icon: Icons.abc,
                  label: "gid",
                  color: Colors.yellow,
                  onTap: () {},
                )
              ],
            },
            onValueChanged: (action) {},
            onTap: (value) {},
          ),
        ),
      ],
    );
  }

  Future<void> _showDateRangePicker(String userId, String walletId) async {
    await showModernDateRangePicker(
      context: context,
      start: _filter.startDate,
      end: _filter.endDate,
      onApply: (startDate, endDate) {
        setState(() {
          _filter = _filter.copyWith(startDate: startDate, endDate: endDate);
        });

        // Reload transactions with new date range
        _loadTransactions(userId, walletId);
      },
    );
  }
}
