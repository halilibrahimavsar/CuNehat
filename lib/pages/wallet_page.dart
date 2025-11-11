import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_state.dart';
import 'package:cunehat/pages/expense_pages/expense_page.dart';
import 'package:cunehat/pages/income_pages/income_page.dart';
import 'package:cunehat/shared/animations/cube_animation_view.dart';
import 'package:cunehat/shared/animations/slider_button_view.dart';
import 'package:cunehat/shared/widgets/shared_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Tarih aralığını burada, yani üst widget'ta tanımlıyoruz
  late DateTime _filterStartDate;
  late DateTime _filterEndDate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    // Tarih aralığını ayarla ve veriyi çek
    _updateDateFilter();
    _fetchData();
  }

  void _updateDateFilter() {
    _filterEndDate = DateTime.now();
    _filterStartDate = _filterEndDate.subtract(const Duration(days: 30));
  }

  // Veri çekme işlemini artık WalletPage yapıyor
  void _fetchData() {
    // Hem gelir hem de gideri tek seferde çekmek için
    // GetCompareEvent kullanmak en verimlisidir.
    // Eğer BLoC'unuzda GetCompareEvent her iki veriyi de Successfully...State içinde
    // tutmuyorsa, iki ayrı event de gönderebilirsiniz.
    // Mevcut BLoC'unuza göre GetCompareEvent en iyisi.
    context.read<DataBloc>().add(
          GetCompareEvent(
            filterStart: _filterStartDate,
            filterEnd: _filterEndDate,
          ),
        );

    // VEYA ayrı ayrı çekmek isterseniz:
    // context.read<DataBloc>().add(
    //       GetExpenseByDateRngEvent(
    //         filterStart: _filterStartDate,
    //         filterEnd: _filterEndDate,
    //       ),
    //     );
    // context.read<DataBloc>().add(
    //       GetIncomeByDateRngEvent(
    //         filterStart: _filterStartDate,
    //         filterEnd: _filterEndDate,
    //       ),
    //     );
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
        appBar: SharedAppbar(),
        drawer: Drawer(
          elevation: 1,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'Menü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Ayarlar"),
                onTap: () {
                  Navigator.pop(context);
                  context.push("/settings");
                },
              ),
            ],
          ),
        ),
        // BlocListener'ı buraya taşıdık.
        // Ekleme veya silme işlemi başarılı olduğunda (Expense veya Income fark etmez),
        // tüm veriyi yeniden çekeriz (_fetchData)
        body: BlocListener<DataBloc, DataState>(
          listener: (context, state) {
            if (state is ErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("Hata: ${state.err}"),
                    backgroundColor: Colors.red),
              );
            } else if (state is SuccessfullyCreatedItemState ||
                state is SuccessfullyDeletedItemState ||
                state is SuccessfullyUpdatedItemState) {
              // Veri değiştiğinde (ekleme, silme, güncelleme),
              // her iki listeyi de yenilemek için _fetchData çağırılır.
              _fetchData();
            }
          },
          // BlocBuilder tüm veri çekme durumlarını yönetir
          child: BlocBuilder<DataBloc, DataState>(
            // Sadece veri çekme state'leri ile ilgilen
            // (SuccessfullyCreatedItemState vb. 'build'i tetiklemesin)
            buildWhen: (previous, current) {
              return current is LoadingDataState ||
                  current is SuccessfullyGetCompareState ||
                  current is NoDataState ||
                  current is ErrorState;
            },
            builder: (context, state) {
              // Başlangıçta boş haritalar oluştur
              Map<DateTime, List<Income>> incomeData = {};
              Map<DateTime, List<Expense>> expenseData = {};
              Widget? centerWidget; // Yüklenme veya hata durumu için

              // Duruma göre veriyi veya merkez widget'ı ayarla
              if (state is LoadingDataState) {
                centerWidget = const Center(child: CircularProgressIndicator());
              } else if (state is ErrorState) {
                centerWidget = Center(
                    child: Text("Veriler yüklenemedi: ${state.err}",
                        style: const TextStyle(color: Colors.red)));
              } else if (state is NoDataState) {
                // Veri yoksa, boş listelerle devam et
                // (IncomeView/ExpenseView kendi "veri yok" mesajını gösterebilir)
              } else if (state is SuccessfullyGetCompareState) {
                incomeData = state.income;
                expenseData = state.expense;
              }

              // centerWidget ayarlanmışsa (Loading/Error), animasyonu gösterme
              if (centerWidget != null) {
                return centerWidget;
              }

              // Veri hazır (veya boş), animasyonu ve listeleri göster
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: CubeAnimationView(
                        controller: _controller,
                        // Veriyi parametre olarak geçiyoruz
                        firstView: IncomeView(incomeData: incomeData),
                        secondView: ExpenseView(expenseData: expenseData),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SliderButtonExpenseIncome(controller: _controller),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
