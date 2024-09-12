import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/firestore/cloud_const.dart';
import 'package:cunehat/firestore/firestore_models/model_provider.dart';

class Income implements ModelProvider {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String tag;
  @override
  final double amount;
  @override
  final Timestamp date;
  @override
  final String time;

  Income({
    required this.id,
    required this.userId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
  });

  Income.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : id = snapshot.id,
        userId = snapshot.data()[fieldUserId],
        title = snapshot.data()[fieldTitle],
        tag = snapshot.data()[fieldTag],
        amount = snapshot.data()[fieldAmount],
        date = snapshot.data()[fieldDate],
        time = snapshot.data()[fieldTime];

  @override
  set amount(double amount) {}

  @override
  set date(Timestamp date) {}

  @override
  set id(String id) {}

  @override
  set tag(String tag) {}

  @override
  set time(String time) {}

  @override
  set title(String title) {}

  @override
  set userId(String userId) {}

  @override
  String toString() => """
---------------------
amount : $amount
date : $date
id : $id
tag : $tag
time : $time
title : $title
user id : $userId
---------------------""";
}
