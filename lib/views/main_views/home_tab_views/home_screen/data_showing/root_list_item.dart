import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/add_data_views/update_data_screen.dart';
import 'package:cunehat/views/main_views/home_tab_views/home_screen/data_showing/list_item.dart';
import 'package:cunehat/views/utilities/customizable_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class RootListItem extends StatelessWidget {
  const RootListItem({
    super.key,
    required this.header,
    required this.selectedOption,
    required this.trnsformAllData,
  });

  final DateTime header;
  final int selectedOption;
  final Map<DateTime, List<ModelProvider>> trnsformAllData;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        DateFormat.yMMMd('tr').format(header),
        style: TextStyle(
          color: selectedOption == 2 ? Colors.red : Colors.green,
        ),
      ),
      subtitle: Text(
        DateFormat.E('tr').format(header),
        style: TextStyle(
          color: selectedOption == 2 ? Colors.red : Colors.green,
        ),
      ),
      leading: Text(
        '   ${trnsformAllData[header]!.length}\nAdet',
        style: TextStyle(
          color: selectedOption == 2 ? Colors.red : Colors.green,
        ),
      ),
      maintainState: true,
      children: List.generate(
        trnsformAllData[header]!.length,
        (indx) {
          final data = trnsformAllData[header]?[indx];

          return Slidable(
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) {
                    showModalBottomSheet(
                      enableDrag: true,
                      useSafeArea: true,
                      isScrollControlled: true,
                      isDismissible: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      context: context,
                      builder: (context) {
                        return UpdateDataScreen(
                          selectedOption: selectedOption,
                          id: data!.id,
                          note: data.title,
                          price: data.amount,
                          tag: data.tag,
                          tagList: data.tag.split(",.,.,.,.,.,"),
                          date: data.date,
                          time: data.time,
                        );
                      },
                    );
                  },
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  icon: Icons.update,
                  label: 'Update',
                ),
              ],
            ),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) async {
                    await showCustmDialog(
                      context,
                      title: "Sil",
                      msg: "Bu veriyi tekrar getiremezsiniz. Silinsin mi?",
                      cancelButton: "VAZGEÇ",
                      confirmButton: "SİL",
                      color: Colors.amber,
                      functionWhenConfirm: () async {
                        (selectedOption == 2)
                            ? await FirestoreService()
                                .deleteExpense(id: data!.id)
                            : await FirestoreService()
                                .deleteIncome(id: data!.id);
                      },
                    );
                  },
                  autoClose: true,
                  backgroundColor: const Color.fromARGB(255, 255, 224, 23),
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: ShowListWidget(
              selectedOption: selectedOption,
              data: trnsformAllData[header]?[indx],
            ),
          );
        },
      ),
    );
  }
}
