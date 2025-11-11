import 'package:cunehat/firestore/firestore_bloc/data_bloc.dart';
import 'package:cunehat/firestore/firestore_bloc/data_event.dart';
import 'package:cunehat/firestore/firestore_bloc/data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 1. StatelessWidget'ı StatefulWidget'a dönüştürdük
class IncomeView extends StatefulWidget {
  const IncomeView({super.key});

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView> {
  @override
  void initState() {
    super.initState();
    // 2. Widget ilk yüklendiğinde, BLoC'a gelir verisini getirmesi için event gönder
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    context.read<DataBloc>().add(GetIncomeByDateRngEvent(
          filterStart: firstDayOfMonth,
          filterEnd: lastDayOfMonth,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      // 3. BlocBuilder ile DataBloc'u dinliyoruz
      child: BlocBuilder<DataBloc, DataState>(
        // 4. Sadece bu 'view' ile ilgili state'lerde yeniden çizim yap.
        buildWhen: (previous, current) {
          return current is LoadingDataState ||
              current is SuccessfullyGetIncomeState ||
              current is ErrorState ||
              current is NoDataState;
        },
        builder: (context, state) {
          // 5. Gelen state'e göre UI'ı çiz

          // YÜKLENİYOR DURUMU
          if (state is LoadingDataState) {
            return const CircularProgressIndicator(color: Colors.white);
          }

          // BAŞARILI DURUMU (GELİR)
          if (state is SuccessfullyGetIncomeState) {
            // Veri geldi ama boş mu?
            if (state.data.isEmpty) {
              return const Text(
                "Bu ay hiç gelir yok.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              );
            }

            // Veri var. Map<DateTime, List<Income>>'i düz bir listeye çevirelim.
            final allIncomes =
                state.data.values.expand((list) => list).toList();

            // Listede gösterelim
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: allIncomes.length,
              itemBuilder: (context, index) {
                final income = allIncomes[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.9),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(income.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(income.tag),
                    trailing: Text(
                      "+${income.amount.toStringAsFixed(2)} ₺",
                      style: const TextStyle(
                        color: Colors.green,
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

          // DİĞER TÜM DURUMLAR
          return const Text("INCOME",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
        },
      ),
    );
  }
}
