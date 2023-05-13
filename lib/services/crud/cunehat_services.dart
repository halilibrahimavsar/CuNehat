import 'package:cunehat/services/crud/database_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

// Database name
const dbName = "cunehat.db";

// Table names
const userTable = "users";
const dataTable = "data";

// For the field of the user table
const idColmn = "id";
const emailColmn = "email";

// For the field of the data table
const userIdColmn = "user_id";
const priceColmn = "price";
const noteColmn = "note";
const tagColmn = "tag";
const dateColmn = "date";
const timeColmn = "time";
const isSyncedWithCloudColmn = "is_synced_with_cloud";

// create tables in sql syntax
const createDataTable = '''CREATE TABLE IF NOT EXISTS "data" (
                          "id"	INTEGER NOT NULL UNIQUE,
                          "price"	REAL,
                          "note"	TEXT,
                          "tag"	TEXT,
                          "date"	TEXT,
                          "time"	TEXT,
                          "user_id"	INTEGER NOT NULL,
                          "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
                          PRIMARY KEY("id" AUTOINCREMENT),
                          FOREIGN KEY("user_id") REFERENCES "users"("id")
                        );''';

const createUserTable = '''CREATE TABLE IF NOT EXISTS "users" (
                          "id"	INTEGER NOT NULL UNIQUE,
                          "email"	TEXT NOT NULL UNIQUE,
                          PRIMARY KEY("id" AUTOINCREMENT)
                        );''';

class CunehatServices {
  Database? _db;

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
      await db.execute(createDataTable);
    } on MissingPlatformDirectoryException {
      throw UnableToGetDirectoryException;
    }
  }

  Future<void> close() async {
    // if (_db != null) {
    //   throw DatabaseAlreadyOpenException();
    // }
    // try {
    //   await _db.close();
    // }
  }
}

class DatabaseUser {
  final int id;
  final String email;

  DatabaseUser({required this.id, required this.email});

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

class DatabaseCunehat {
  final int id;
  final double price;
  final String note;
  final String tag;
  final String date;
  final String time;
  final int userId;
  final bool isSyncedWithCloud;

  DatabaseCunehat({
    required this.id,
    required this.price,
    required this.note,
    required this.tag,
    required this.date,
    required this.time,
    required this.userId,
    required this.isSyncedWithCloud,
  });

  DatabaseCunehat.fromRow(Map<String, Object?> map)
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
  operator ==(covariant DatabaseCunehat other) {
    return id == other.id;
  }

  // Below code is also part of the overriding `==` operator.
  @override
  int get hashCode => id.hashCode;
}
