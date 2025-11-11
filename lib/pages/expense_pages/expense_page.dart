import 'package:cunehat/firestore/firestore_bloc/data_bloc.dart';
import 'package:cunehat/firestore/firestore_bloc/data_event.dart';
import 'package:cunehat/firestore/firestore_bloc/data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 1. StatelessWidget'ı StatefulWidget'a dönüştürdük
class ExpenseView extends StatefulWidget {
  const ExpenseView({super.key});

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  @override
  void initState() {
    super.initState();
    // 2. Widget ilk yüklendiğinde, BLoC'a veri getirmesi için event gönder
    // Varsayılan olarak bu ayın verilerini isteyelim
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth =
        DateTime(now.year, now.month + 1, 0); // Ayın son gününü bulma

    // context.read<DataBloc>() ile BLoC'a erişip event'i ekliyoruz
    context.read<DataBloc>().add(GetExpenseByDateRngEvent(
          filterStart: firstDayOfMonth,
          filterEnd: lastDayOfMonth,
        ));
  }

  @override
  Widget build(BuildContext context) {
    // 3. Orijinal Container'ı koruyoruz, ama 'child' kısmını BlocBuilder yapıyoruz
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      // 4. BlocBuilder ile DataBloc'u dinliyoruz
      child: BlocBuilder<DataBloc, DataState>(
        // 5. ÖNEMLİ: Sadece bu 'view' ile ilgili state'lerde yeniden çizim yap.
        // Bu, LoadingDataState, ErrorState veya SADECE ExpenseState olduğunda tetiklenir.
        buildWhen: (previous, current) {
          return current is LoadingDataState ||
              current is SuccessfullyGetExpenseState ||
              current is ErrorState ||
              current is NoDataState;
        },
        builder: (context, state) {
          // 6. Gelen state'e göre UI'ı çiz

          // YÜKLENİYOR DURUMU
          if (state is LoadingDataState) {
            return const CircularProgressIndicator(color: Colors.white);
          }

          // BAŞARILI DURUMU (HARCAMA)
          if (state is SuccessfullyGetExpenseState) {
            // Veri geldi ama boş mu?
            if (state.data.isEmpty) {
              return const Text(
                "Bu ay hiç harcama yok.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              );
            }

            // Veri var. Map<DateTime, List<Expense>>'i düz bir listeye çevirelim.
            final allExpenses =
                state.data.values.expand((list) => list).toList();

            // Listede gösterelim
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: allExpenses.length,
              itemBuilder: (context, index) {
                final expense = allExpenses[index];
                return Card(
                  color: Colors.white
                      .withValues(alpha: 0.9), // Hafif transparan kart
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(expense.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(expense.tag),
                    trailing: Text(
                      "-${expense.amount.toStringAsFixed(2)} ₺",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            );
          }

          // HATA DURUMU
          if (state is ErrorState) {
            return Text("Hata: ${state.err}",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold));
          }

          // DİĞER TÜM DURUMLAR (NoDataState veya SuccessfullyGetIncomeState gibi ilgisiz durumlar)
          // Varsayılan görünümü göster
          return const Text("EXPENSE",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
        },
      ),
    );
  }
}
