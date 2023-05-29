import 'package:cunehat/services/crud/crud_constants.dart';
import 'package:flutter/material.dart';

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColmn] as int,
        email = map[emailColmn] as String;

  @override
  String toString() {
    return "id : $id     email : $email";
  }

  @override
  operator ==(covariant DatabaseUser other) {
    // Lets explain abowe code ; We are overriding the "==" operator,
    // with help of `covariant` keyword. With `covariant`, we are simply
    // saying we want to take `DatabaseUser` object and compare our `id`
    // with `other.id`.
    return id == other.id;
  }

  // Below code is also part of the overriding `==` operator.
  @override
  int get hashCode => id.hashCode;
}

class DbExpense {
  final int id;
  final double price;
  final String note;
  final String tag;
  final String date;
  final String time;
  final int userId;
  final bool isSyncedWithCloud;

  DbExpense({
    required this.id,
    required this.price,
    required this.note,
    required this.tag,
    required this.date,
    required this.time,
    required this.userId,
    required this.isSyncedWithCloud,
  });

  DbExpense.fromRow(Map<String, Object?> map)
      : id = map[idColmn] as int,
        price = map[priceColmn] as double,
        note = map[noteColmn] as String,
        tag = map[tagColmn] as String,
        date = map[dateColmn] as String,
        time = map[timeColmn] as String,
        userId = map[userIdColmn] as int,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColmn] as int) == 1 ? true : false;

  @override
  String toString() {
    return 'id : $id \nprice : $price \nnote : $note \ntag : $tag \ndate : $date \ntime : $time \nuserId : $userId \nisSyncedWithCloud : $isSyncedWithCloud \n';
  }

  @override
  operator ==(covariant DbExpense other) {
    return id == other.id;
  }

  // Below code is also part of the overriding `==` operator.
  @override
  int get hashCode => id.hashCode;
}

class DbIncome {
  final int id;
  final double price;
  final String note;
  final String tag;
  final String date;
  final String time;
  final int userId;
  final bool isSyncedWithCloud;

  DbIncome({
    required this.id,
    required this.price,
    required this.note,
    required this.tag,
    required this.date,
    required this.time,
    required this.userId,
    required this.isSyncedWithCloud,
  });

  DbIncome.fromRow(Map<String, Object?> map)
      : id = map[idColmn] as int,
        price = map[priceColmn] as double,
        note = map[noteColmn] as String,
        tag = map[tagColmn] as String,
        date = map[dateColmn] as String,
        time = map[timeColmn] as String,
        userId = map[userIdColmn] as int,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColmn] as int) == 1 ? true : false;
  // as we dont have boolean in sqlite, we use as bool in program but
  // saving as 1 or 0 (which is int) inside of the database

  @override
  String toString() {
    return 'id : $id \nprice : $price \nnote : $note \ntag : $tag \ndate : $date \ntime : $time \nuserId : $userId \nisSyncedWithCloud : $isSyncedWithCloud \n';
  }

  @override
  operator ==(covariant DbExpense other) {
    return id == other.id;
  }

  // Below code is also part of the overriding `==` operator.
  @override
  int get hashCode => id.hashCode;
}
