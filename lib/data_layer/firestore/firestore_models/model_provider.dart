// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ModelProvider {
  String id = "";
  String userId = "";
  String title = "";
  String tag = "";
  double amount = 0;
  Timestamp date = Timestamp.now();
  String time = "";
}
