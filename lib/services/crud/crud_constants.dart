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
