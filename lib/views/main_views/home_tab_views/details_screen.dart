import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/firestore/firestore_service.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<Iterable<Income>>(
      stream: FirestoreService().getAllIncomes(ownerUserId: uid),
      builder: (context, incomeSnapshot) {
        return StreamBuilder<Iterable<Expense>>(
          stream: FirestoreService().getAllExpenses(ownerUserId: uid),
          builder: (context, expenseSnapshot) {
            // final incomes = incomeSnapshot.data;
            // final expense = expenseSnapshot.data;

            return Container();
          },
        );
      },
    );
  }
}
