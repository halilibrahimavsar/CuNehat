import 'dart:async';

import 'package:cunehat/extensions/filter.dart';
import 'package:cunehat/services/crud/crud_models.dart';
import 'package:cunehat/services/crud/database_exceptions.dart';
import 'package:cunehat/services/crud/crud_constants.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class CunehatServices {
  Database? _db;

  DatabaseUser? _user;

  final List<DbExpense> _expenseList = [];
  final List<DbIncome> _incomeList = [];

  late final StreamController<List<DbExpense>> _expenseStream;
  late final StreamController<List<DbIncome>> _incomeStream;

  late final StreamController<List<DbIncome>> _incomeStreamMonth;
  late final StreamController<List<DbExpense>> _expenseStreamMonth;

  Stream<List<DbExpense>> get allExpense {
    return _expenseStream.stream.filter((expense) {
      final currentUser = _user;
      if (currentUser != null) {
        return expense.userId == currentUser.id;
      } else {
        throw UserShouldBeSetBeforeReadingAllNotes();
      }
    });
  }

  Stream<List<DbIncome>> get allIncome {
    return _incomeStream.stream.filter((income) {
      final currentUser = _user;
      if (currentUser != null) {
        return income.userId == currentUser.id;
      } else {
        throw UserShouldBeSetBeforeReadingAllNotes();
      }
    });
  }

  Stream<List<DbExpense>> getIncomeByMonth() {
    return _expenseStreamMonth.stream.filter((expense) {
      final currentUser = _user;
      if (currentUser != null) {
        return expense.userId == currentUser.id;
      } else {
        throw UserShouldBeSetBeforeReadingAllNotes();
      }
    });
  }

  Stream<List<DbIncome>> getExpenseByMonth() {
    return _incomeStreamMonth.stream.filter((expense) {
      final currentUser = _user;
      if (currentUser != null) {
        return expense.userId == currentUser.id;
      } else {
        throw UserShouldBeSetBeforeReadingAllNotes();
      }
    });
  }

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

  // private and open/close fields

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

  Future<List<DbExpense>> expenseGetDate({required String monthAndYear}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final expenses = await db.query(
      expenseTable,
      where: "date LIKE ?",
      whereArgs: ['%$monthAndYear%'],
    );

    final monthlyData =
        expenses.map((expenseRow) => DbExpense.fromRow(expenseRow)).toList();

    return monthlyData;
  }

  Future<List<String>> expenseGetMonthAndYear() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final dates =
        await db.query(expenseTable, columns: ['date'], orderBy: "date");

    final List<String> listOfDates =
        dates.map((e) => e.values.first.toString()).toList();

    final List<String> monthsAndYears = [];

    for (final String i in listOfDates) {
      final String year = i.split("/")[2].split("-")[0];
      final String month = i.split("/")[1];
      final String yearAndMonthDate = '$month/$year';

      if (!(monthsAndYears.contains(yearAndMonthDate))) {
        monthsAndYears.add(yearAndMonthDate);
      }
    }

    return monthsAndYears;
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

  Future<List<DbIncome>> incomeGetDate({required String monthAndYear}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final incomes = await db.query(
      incomeTable,
      where: "date LIKE ?",
      whereArgs: ['%$monthAndYear%'],
    );

    return incomes.map((incomeRow) => DbIncome.fromRow(incomeRow)).toList();
  }

  Future<List<String>> incomeGetMonthAndYear() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final dates =
        await db.query(incomeTable, columns: ['date'], orderBy: "date");

    final List<String> listOfDates =
        dates.map((e) => e.values.first.toString()).toList();

    final List<String> monthsAndYears = [];

    for (final String i in listOfDates) {
      final String year = i.split("/")[2].split("-")[0];
      final String month = i.split("/")[1];
      final String yearAndMonthDate = '$month/$year';
      if (!(monthsAndYears.contains(yearAndMonthDate))) {
        monthsAndYears.add(yearAndMonthDate);
      }
    }

    return monthsAndYears;
  }
}
