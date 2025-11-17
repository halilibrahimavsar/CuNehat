// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/constants/repository_constants.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// Hive'ın bu nesneyi tanıması için 'part' dosyası
part 'income_model.g.dart';

// Hive için TypeAdapter'ı tanımlıyoruz. typeId benzersiz olmalı.
@HiveType(typeId: 0)
class Income extends HiveObject {
  // HiveObject'i extend etmesi, Hive'ın onu daha verimli yönetmesini sağlar.

  // Hive alanlarını numaralandırıyoruz.
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String tag;

  @HiveField(4)
  final double amount;

  // Firestore'daki Timestamp yerine saf DateTime kullanıyoruz.
  // Bu, hem Hive hem de Firestore için daha evrenseldir.
  @HiveField(5)
  final DateTime date;

  @HiveField(6)
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

  // Firestore'dan veri okumak için bir 'factory' constructor.
  // Artık QueryDocumentSnapshot'a bağımlı değiliz.
  factory Income.fromJson(String id, Map<String, dynamic> json) {
    return Income(
      id: id,
      userId: json[fieldUserId] ?? '',
      title: json[fieldTitle] ?? '',
      tag: json[fieldTag] ?? '',
      amount: (json[fieldAmount] as num? ?? 0.0).toDouble(),
      // Firestore'dan gelen Timestamp'i DateTime'a çeviriyoruz.
      date: (json[fieldDate] as Timestamp? ?? Timestamp.now()).toDate(),
      time: json[fieldTime] ?? '',
    );
  }

  // Firestore'a veri yazmak için 'toJson' metodu.
  Map<String, dynamic> toJson() {
    return {
      fieldUserId: userId,
      fieldTitle: title,
      fieldTag: tag,
      fieldAmount: amount,
      // DateTime'ı Firestore'un anlayacağı Timestamp'e çeviriyoruz.
      fieldDate: Timestamp.fromDate(date),
      fieldTime: time,
    };
  }

  // Yerel depolamada (Hive) yeni bir gelir oluştururken
  // kullanmak için yardımcı bir factory.
  factory Income.createLocal({
    required String userId,
    required String title,
    required String tag,
    required double amount,
    required DateTime date,
    required String time,
  }) {
    return Income(
      // Benzersiz bir ID oluşturmak için Uuid paketini kullanıyoruz.
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      tag: tag,
      amount: amount,
      date: date,
      time: time,
    );
  }
}
