import 'package:flutter/material.dart';

enum TransactionViewType {
  list,
  timeline;

  IconData get icon =>
      this == TransactionViewType.list ? Icons.view_list : Icons.account_tree;
}
