import 'dart:async';

import 'package:cunehat/services/crud/database_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

// Database name
const dbName = "cunehat.db";

// Table names
const userTable = "users";
const expenseTable = "expense";
const incomeTable = "income";

// For the field of the user table
const idColmn = "id";
const emailColmn = "email";

// Below variables is the same for both Expense and Income databases.
// The table title will be same but content(data inside of the tables)
// will be different.
const userIdColmn = "user_id";
const priceColmn = "price";
const noteColmn = "note";
const tagColmn = "tag";
const dateColmn = "date";
const timeColmn = "time";
const isSyncedWithCloudColmn = "is_synced_with_cloud";

const createUserTable = '''CREATE TABLE IF NOT EXISTS "users" (
                          "id"	INTEGER NOT NULL UNIQUE,
                          "email"	TEXT NOT NULL UNIQUE,
                          PRIMARY KEY("id" AUTOINCREMENT)
                        );''';

// create tables in sql syntax
const createExpenseTable = '''CREATE TABLE IF NOT EXISTS "$expenseTable" (
                          "id"	INTEGER NOT NULL UNIQUE,
                          "$priceColmn"	REAL,
                          "$noteColmn"	TEXT,
                          "$tagColmn"	TEXT,
                          "$dateColmn"	TEXT,
                          "$timeColmn"	TEXT,
                          "$userIdColmn"	INTEGER NOT NULL,
                          "$isSyncedWithCloudColmn"	INTEGER NOT NULL DEFAULT 0,
                          PRIMARY KEY("id" AUTOINCREMENT),
                          FOREIGN KEY("$userIdColmn") REFERENCES "$userTable"("id")
                        );''';

const createIncomeTable = '''CREATE TABLE IF NOT EXISTS "$incomeTable" (
                          "id"	INTEGER NOT NULL UNIQUE,
                          "$priceColmn"	REAL,
                          "$noteColmn"	TEXT,
                          "$tagColmn"	TEXT,
                          "$dateColmn"	TEXT,
                          "$timeColmn"	TEXT,
                          "$userIdColmn"	INTEGER NOT NULL,
                          "$isSyncedWithCloudColmn"	INTEGER NOT NULL DEFAULT 0,
                          PRIMARY KEY("id" AUTOINCREMENT),
                          FOREIGN KEY("$userIdColmn") REFERENCES "$userTable"("id")
                        );''';

class CunehatServices {
  Database? _db;

  DatabaseUser? _user;

  List<DbExpense> _expenseList = [];
  List<DbIncome> _incomeList = [];

  late final StreamController<List<DbExpense>> _expenseStream;
  late final StreamController<List<DbIncome>> _incomeStream;

  // singleton pattern
  static final CunehatServices _shared = CunehatServices._sharedInstance();
  CunehatServices._sharedInstance() {
    // initialize _expenseStream
    _expenseStream = StreamController<List<DbExpense>>.broadcast(
      onListen: () {
        _expenseStream.sink.add(_expenseList);
      },
    );

    // initialize _incomeStream
    _incomeStream = StreamController<List<DbIncome>>.broadcast(
      onListen: () {
        _incomeStream.sink.add(_incomeList);
      },
    );
  }
  factory CunehatServices() => _shared;

  // Stream<List<DbExpense>> get expenseLastMnth =>
  //     _expenseStream.stream.where((expense) {
  //       final currentUser = _user;
  //       if (currentUser != null) {
  //         return expense.userId == currentUser.id;
  //       } else {
  //         throw UserShouldBeSetBeforeReadingAllNotes();
  //       }
  //     });

  // private and open/close fields
  Future<void> _cacheExpense() async {
    final expenses = await expenseGetLastMonth();
    _expenseList = expenses.toList();
    _expenseStream.add(_expenseList);
  }

  Future<void> _cacheIncome() async {
    final incomes = await incomeGetLastMonth();
    _incomeList = incomes.toList();
    _incomeStream.add(_incomeList);
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      // empty
    }
  }

  Future<void> close() async {
    final db = _getDatabaseOrThrow();

    await db.close();
    _db = null;
  }

  Future<void> open() async {
    // if database is opened throw an error
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db; // assign to our private variable
      // create tables
      await db.execute(createUserTable);
      await db.execute(createExpenseTable);
      await db.execute(createIncomeTable);
      await _cacheExpense();
      await _cacheIncome();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDirectoryException;
    }
  }

  // user services
  Future<DatabaseUser> userGetOrCreate({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      final user = await userGet(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CouldNotFindUser {
      final createdUser = await userCreate(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<DatabaseUser> userCreate({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {
      emailColmn: email.toLowerCase(),
    });

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<DatabaseUser> userGet({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<void> userDelete({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  //expense services
  Future<DbExpense> expenseCreate({
    required DatabaseUser owner,
    required double price,
    required String note,
    required String tag,
    required String date,
    required String time,
    required bool isSynecWithCloud,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure owner exists in the database with the correct id
    final dbUser = await userGet(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    // create Expense
    final expenseId = await db.insert(expenseTable, {
      priceColmn: price,
      noteColmn: note,
      tagColmn: tag,
      dateColmn: date,
      timeColmn: time,
      userIdColmn: owner.id,
    });

    final expense = DbExpense(
      id: expenseId,
      price: price,
      note: note,
      tag: tag,
      date: date,
      time: time,
      isSyncedWithCloud: isSynecWithCloud,
      userId: owner.id,
    );

    _expenseList.add(expense);
    _expenseStream.add(_expenseList);

    return expense;
  }

  Future<void> expenseDelete({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      expenseTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteData();
    } else {
      _expenseList.removeWhere((element) => element.id == id);
      _expenseStream.add(_expenseList);
    }
  }

  Future<DbExpense> expenseGet({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final expenses = await db.query(
      expenseTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (expenses.isEmpty) {
      throw CouldNotFindData();
    } else {
      final expense = DbExpense.fromRow(expenses.first);

      _expenseList.removeWhere((element) => element.id == id);
      _expenseList.add(expense);
      _expenseStream.add(_expenseList);
      return expense;
    }
  }

  Future<DbExpense> expenseUpdate({
    required DbExpense expense,
    required double price,
    required String note,
    required String tag,
    required String date,
    required String time,
    required bool isSynecWithCloud,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure note exists
    await expenseGet(id: expense.id);

    // update DB
    final updatesCount = await db.update(
      expenseTable,
      {
        priceColmn: price,
        noteColmn: note,
        tagColmn: tag,
        dateColmn: date,
        timeColmn: time,
      },
      where: 'id = ?',
      whereArgs: [expense.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateData();
    } else {
      final updatedExpense = await expenseGet(id: expense.id);

      _expenseList.removeWhere((element) => element.id == updatedExpense.id);
      _expenseList.add(updatedExpense);
      _expenseStream.add(_expenseList);
      return updatedExpense;
    }
  }

  Future<Iterable<DbExpense>> expenseGetLastMonth() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final expenses = await db.query(
      expenseTable,
      limit: 31,
    );

    return expenses.map((expenseRow) => DbExpense.fromRow(expenseRow));
  }

  // income service
  Future<DbIncome> incomeCreate({
    required DatabaseUser owner,
    required double price,
    required String note,
    required String tag,
    required String date,
    required String time,
    required bool isSynecWithCloud,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure owner exists in the database with the correct id
    final dbUser = await userGet(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    final incomeId = await db.insert(incomeTable, {
      priceColmn: price,
      noteColmn: note,
      tagColmn: tag,
      dateColmn: date,
      timeColmn: time,
      userIdColmn: owner.id,
    });

    final income = DbIncome(
      id: incomeId,
      price: price,
      note: note,
      tag: tag,
      date: date,
      time: time,
      isSyncedWithCloud: isSynecWithCloud,
      userId: owner.id,
    );

    // _notes.add(expense);
    // _notesStreamController.add(expense);
    _incomeList.add(income);
    _incomeStream.add(_incomeList);

    return income;
  }

  Future<void> incomeDelete({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      incomeTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteData();
    } else {
      _incomeList.removeWhere((element) => element.id == id);
      _incomeStream.add(_incomeList);
    }
  }

  Future<DbIncome> incomeGet({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final incomes = await db.query(
      incomeTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (incomes.isEmpty) {
      throw CouldNotFindData();
    } else {
      final income = DbIncome.fromRow(incomes.first);
      _incomeList.removeWhere((element) => element.id == id);
      _incomeList.add(income);
      _incomeStream.add(_incomeList);
      return income;
    }
  }

  Future<DbIncome> incomeUpdate({
    required DbIncome income,
    required double price,
    required String note,
    required String tag,
    required String date,
    required String time,
    required bool isSynecWithCloud,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure note exists
    await incomeGet(id: income.id);

    // update DB
    final updatesCount = await db.update(
      incomeTable,
      {
        priceColmn: price,
        noteColmn: note,
        tagColmn: tag,
        dateColmn: date,
        timeColmn: time,
      },
      where: 'id = ?',
      whereArgs: [income.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateData();
    } else {
      final updatedIncome = await incomeGet(id: income.id);
      _incomeList.removeWhere((note) => note.id == updatedIncome.id);
      _incomeList.add(updatedIncome);
      _incomeStream.add(_incomeList);
      return updatedIncome;
    }
  }

  Future<Iterable<DbIncome>> incomeGetLastMonth() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final incomes = await db.query(
      incomeTable,
      limit: 31,
    );

    return incomes.map((incomeRow) => DbIncome.fromRow(incomeRow));
  }
}

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
