import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/constants/model_provider_names.dart';
import 'package:cunehat/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/firestore/firestore_models/income_model.dart';
import 'package:cunehat/firestore/firestore_models/model_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:intl/intl.dart';

class CompareDataView extends StatelessWidget {
  final Map<DateTime, List<Income>> incomeData;
  final Map<DateTime, List<Expense>> expenseData;

  const CompareDataView({
    super.key,
    required this.incomeData,
    required this.expenseData,
  });

  @override
  Widget build(BuildContext context) {
    Map<DateTime, Map<ModelProviderNames, List<ModelProvider>>> allData = {};

    for (var i in incomeData.entries) {
      if (!allData.containsKey(i.key)) {
        // allData[i.key] = {ModelProviderNames.income: i.value};
        allData.putIfAbsent(i.key, () => {ModelProviderNames.income: i.value});
      } else {
        allData.update(i.key, (value) {
          value.putIfAbsent(ModelProviderNames.income, () => i.value);
          return value;
        });
      }
    }
    for (var i in expenseData.entries) {
      if (!allData.containsKey(i.key)) {
        allData.putIfAbsent(i.key, () => {ModelProviderNames.expense: i.value});
      } else {
        allData.update(i.key, (value) {
          value.putIfAbsent(ModelProviderNames.expense, () => i.value);
          return value;
        });
      }
    }

    return Expanded(
      child: ListView.builder(
        itemCount: allData.length,
        itemBuilder: (context, index) {
          // front data
          DateTime dateHeader = allData.keys.elementAt(index);
          int incomeCount =
              allData[dateHeader]?[ModelProviderNames.income]?.length ?? 0;
          int expenseCount =
              allData[dateHeader]?[ModelProviderNames.expense]?.length ?? 0;
      
          // if its empty, show the empty data to the near on the expense and vice versa for income
          List<ModelProvider> dateBasedIncome =
              allData[dateHeader]?[ModelProviderNames.income] ??
                  [
                    Income(
                        id: "",
                        userId: "",
                        title: "",
                        tag: "",
                        amount: 0,
                        date: Timestamp.fromMicrosecondsSinceEpoch(
                          dateHeader.microsecondsSinceEpoch,
                        ),
                        time: "")
                  ];
          List<ModelProvider> dateBasedExpense =
              allData[dateHeader]?[ModelProviderNames.expense] ??
                  [
                    Expense(
                        id: "",
                        userId: "",
                        title: "",
                        tag: "",
                        amount: 0,
                        date: Timestamp.fromMicrosecondsSinceEpoch(
                          dateHeader.microsecondsSinceEpoch,
                        ),
                        time: "")
                  ];

          return ExpansionTile(
            shape: Border.all(color: Colors.black),
            collapsedShape: Border.merge(
              const Border(bottom: BorderSide(color: Colors.black26)),
              const Border(
                bottom: BorderSide(color: Colors.black26),
              ),
            ),
            maintainState: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat.yMMMd('tr').format(dateHeader)),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Gelir Ad. : $incomeCount',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: 'Gider Ad. : $expenseCount',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // first row is income
                  Column(
                    children: [
                      ...List.generate(
                        dateBasedIncome.length,
                        (index) => Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateBasedIncome[index].title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Tag: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          TextSpan(
                                            text: dateBasedIncome[index].tag,
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Time: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          TextSpan(
                                            text: dateBasedIncome[index].time,
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Amount: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          TextSpan(
                                            text: dateBasedIncome[index]
                                                .amount
                                                .toString(),
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      ...List.generate(
                        dateBasedExpense.length,
                        (index) => Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateBasedExpense[index].title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Tag: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          TextSpan(
                                            text: dateBasedExpense[index].tag,
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Time: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          TextSpan(
                                            text: dateBasedExpense[index].time,
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Amount: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          TextSpan(
                                            text: dateBasedExpense[index]
                                                .amount
                                                .toString(),
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerRight,
                child: const Text(
                  'Fark : ',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
