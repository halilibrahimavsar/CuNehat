import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cunehat/constants/selected_option.dart';
import 'package:cunehat/firestore/firestore_bloc/firestore_bloc.dart';
import 'package:cunehat/views/pages/home_tab_views/home_screen/data_showing/custom_listview.dart';
import 'package:cunehat/views/view_utilities/custom_snackbar.dart';
import 'package:cunehat/views/view_utilities/date_rang_pck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  SelectedOption selectedOption = SelectedOption.all;
  Duration animateDuration = const Duration(seconds: 1);

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    context.read<FirestoreBloc>().add(GetCompareEvent(
          filterStart: DateTime(2021),
          filterEnd: DateTime(2022),
        ));
    _controller = AnimationController(
      duration: animateDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income option
            AnimatedContainer(
              width: 100.0,
              height: selectedOption == SelectedOption.income ? 60.0 : 30.0,
              decoration: BoxDecoration(
                color: selectedOption == SelectedOption.income
                    ? Colors.green
                    : Colors.blue.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              duration: animateDuration,
              curve: Curves.easeInOut,
              child: InkWell(
                onTap: () {
                  // TODO : Filter date
                  setState(() {
                    context.read<FirestoreBloc>().add(GetIncomeByDateRngEvent(
                          filterStart: filterStartDate,
                          filterEnd: filterEndDate,
                        ));
                    selectedOption = SelectedOption.income;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "GELİR",
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8.0),
                    selectedOption == SelectedOption.income
                        ? GestureDetector(
                            onTap: () {
                              // showModalBottomSheet(
                              //   enableDrag: true,
                              //   useSafeArea: true,
                              //   isScrollControlled: true,
                              //   isDismissible: true,
                              //   shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(25)),
                              //   context: context,
                              //   builder: (context) {
                              //     return AddDataScreen(
                              //       colorOfClass: Colors.green,
                              //       titleOfClass: "Gelir",
                              //       provider: FirestoreService().addIncome,
                              //       tagProvider:
                              //           FirestoreService().getIncomeTags,
                              //     );
                              //   },
                              // );
                            },
                            child: AnimatedOpacity(
                              opacity: selectedOption == SelectedOption.income
                                  ? 1.0
                                  : 0.0,
                              duration: animateDuration,
                              child: Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20.0),
            // Kıyasla option
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedOption = SelectedOption.all;
                  // TODO : Filter date
                  context.read<FirestoreBloc>().add(GetCompareEvent(
                        filterStart: filterStartDate,
                        filterEnd: filterEndDate,
                      ));
                });
              },
              child: AnimatedContainer(
                width: 100.0,
                height: selectedOption == SelectedOption.all ? 50.0 : 30.0,
                alignment: Alignment.center,
                duration: animateDuration,
                curve: Curves.fastOutSlowIn,
                decoration: BoxDecoration(
                  color: selectedOption == SelectedOption.all
                      ? Colors.blue
                      : Colors.blue.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "KIYASLA",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 20.0),
            // Gider option
            AnimatedContainer(
              width: 100.0,
              height: selectedOption == SelectedOption.expense ? 60.0 : 30.0,
              decoration: BoxDecoration(
                color: selectedOption == SelectedOption.expense
                    ? Colors.red
                    : Colors.blue.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              duration: animateDuration,
              curve: Curves.easeInOut,
              child: InkWell(
                onTap: () {
                  setState(() {
                    // TODO : Filter date
                    context.read<FirestoreBloc>().add(GetExpenseByDateRngEvent(
                          filterStart: filterStartDate,
                          filterEnd: filterEndDate,
                        ));
                    selectedOption = SelectedOption.expense;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "GİDER",
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8.0),
                    selectedOption == SelectedOption.expense
                        ? GestureDetector(
                            onTap: () {},
                            child: AnimatedOpacity(
                              opacity: selectedOption == SelectedOption.expense
                                  ? 1.0
                                  : 0.0,
                              duration: animateDuration,
                              child: Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
        BlocConsumer<FirestoreBloc, FirestoreState>(
          listener: (context, state) {
            if (state is DateIsEmptyState ||
                state is DateAlreadyExistsState ||
                state is NoDataState) {
              showSnackbar(
                context: context,
                title: "UYARI!",
                msg: state.toString(),
                type: ContentType.warning,
              );
            } else if (state is SuccessfullyCreatedItemState ||
                state is SuccessfullyDeletedItemState ||
                state is SuccessfullyUpdatedItemState) {
              showSnackbar(
                  context: context,
                  title: "Başarılı!",
                  msg: state.toString(),
                  type: ContentType.success,
                  keepAlive: const Duration(seconds: 1));
            } else if (state is ErrorState) {
              showSnackbar(
                  context: context,
                  title: "HATA !",
                  msg: state.err,
                  type: ContentType.failure);
            }
          },
          builder: (context, state) {
            if (state is SuccessfullyGetIncomeState) {
              // final allData = state.data;
              // Map<DateTime, List<ModelProvider>> trnsformAllData = {};

              // allData.toList().forEach((val) {
              //   // key for daily show data
              //   DateTime keyDaily = DateTime(
              //     val.date.toDate().year,
              //     val.date.toDate().month,
              //     val.date.toDate().day,
              //   );
              //   print(keyDaily);

              //   if (trnsformAllData.containsKey(keyDaily)) {
              //     trnsformAllData[keyDaily]?.add(state.data.first);
              //   } else {
              //     trnsformAllData[keyDaily] = [state.data.first];
              //   }
              // });
              return CustomListview(
                trnsformAllData: state.data,
                selectedOption: selectedOption,
              );
            } else if (state is SuccessfullyGetExpenseState) {
              return CustomListview(
                trnsformAllData: state.data,
                selectedOption: selectedOption,
              );
            } else if (state is SuccessfullyGetCompareState) {
              return SingleChildScrollView(
                  child: Text(state.expense.toString()));
            } else if (state is LoadingDataState) {
              return const CircularProgressIndicator(
                value: 20,
              );
            }
            {
              return const Center(child: Text("Something went wrong."));
            }

            // if (state is SuccessfullyGetDataState) {
            //   print("state is $state");
            //   // return CustomListview(
            //   //     trnsformAllData: trnsformAllData,
            //   //     selectedOption: selectedOption);
            // } else {
            //   return Text("yee ${state.props}");
            // }
          },
        ),
      ],
    );
  }
}
