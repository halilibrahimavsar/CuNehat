import 'package:cunehat/views/view_utilities/glass_effect.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/firestore/firestore_service.dart';
import 'package:cunehat/views/pages/add_data_views/update_data_screen.dart';
import 'package:cunehat/views/pages/home_tab_views/home_screen/data_showing/sub_list_item.dart';
import 'package:cunehat/views/view_utilities/customizable_dialog.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class RootListItem extends StatefulWidget {
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
  RootListItemState createState() => RootListItemState();
}

class RootListItemState extends State<RootListItem> {
  @override
  Widget build(BuildContext context) {
    double totalAmount = _calculateTotal();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 1,
      ),
      child: GlassEffect(
        child: ExpansionTile(
          shape: Border.all(
            color: Colors.black,
          ),
          collapsedShape: Border.merge(
            const Border(bottom: BorderSide(color: Colors.black26)),
            const Border(
              bottom: BorderSide(color: Colors.black26),
            ),
          ),
          maintainState: true,
          // backgroundColor: widget.selectedOption == 1
          //     ? Colors.green.shade200
          //     : Colors.red.shade200,
          // collapsedIconColor:
          //     widget.selectedOption == 1 ? Colors.green : Colors.red,
          collapsedTextColor:
              widget.selectedOption == 1 ? Colors.green : Colors.red,
          // textColor: Colors.black,
          title: Text(DateFormat.yMMMd('tr').format(widget.header)),
          subtitle: Text(DateFormat.E('tr').format(widget.header)),
          leading:
              Text('   ${widget.trnsformAllData[widget.header]!.length}\nAdet'),
          children: [
            ...List.generate(
              widget.trnsformAllData[widget.header]!.length,
              (indx) {
                final data = widget.trnsformAllData[widget.header]?[indx];

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
                                selectedOption: widget.selectedOption,
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
                            msg:
                                "Bu veriyi tekrar getiremezsiniz. Silinsin mi?",
                            cancelButton: "VAZGEÇ",
                            confirmButton: "SİL",
                            color: Colors.amber,
                            functionWhenConfirm: () async {
                              (widget.selectedOption == 2)
                                  ? await FirestoreService()
                                      .deleteExpense(id: data!.id)
                                  : await FirestoreService()
                                      .deleteIncome(id: data!.id);
                            },
                          );
                        },
                        autoClose: true,
                        backgroundColor:
                            const Color.fromARGB(255, 255, 224, 23),
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: GlassEffect(
                    child: SubListItem(
                      data: widget.trnsformAllData[widget.header]?[indx],
                    ),
                  ),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerRight,
              child: Text(
                'Toplam : ${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (final data in widget.trnsformAllData[widget.header]!) {
      total += data.amount;
    }
    return total;
  }
}
