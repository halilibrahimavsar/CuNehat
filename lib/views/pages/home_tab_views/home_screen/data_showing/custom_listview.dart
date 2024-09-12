import 'package:cunehat/constants/selected_option.dart';
import 'package:cunehat/firestore/firestore_models/model_provider.dart';
import 'package:cunehat/views/pages/home_tab_views/home_screen/data_showing/root_list_item.dart';
import 'package:flutter/material.dart';

class CustomListview extends StatelessWidget {
  final Map<DateTime, List<ModelProvider>> trnsformAllData;
  final SelectedOption selectedOption;

  const CustomListview(
      {super.key, required this.trnsformAllData, required this.selectedOption});

  @override
  Widget build(BuildContext context) {
    // print(trnsformAllData);
    return Expanded(
      child: ListView.builder(
        itemCount: trnsformAllData.length,
        itemBuilder: (context, index) {
          final header = trnsformAllData.keys.elementAt(index);
          return RootListItem(
            header: header,
            selectedOption: selectedOption,
            trnsformAllData: trnsformAllData,
          );
        },
      ),
    );
  }
}
