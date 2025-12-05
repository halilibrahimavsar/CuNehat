# Compare Feature - Architecture Documentation

## 📐 Overview

The **Compare Feature** displays combined income and expense transactions for a selected wallet and date range. It follows **Clean Architecture** principles with clear separation of concerns.

---

## 🗂️ Folder Structure

```
lib/features/compare/
├── data/
│   ├── datasources/
│   │   ├── compare_firestore_datasource.dart
│   │   └── compare_hive_datasource.dart
│   └── repositories/
│       └── compare_repository_impl.dart
├── domain/
│   ├── models/
│   │   └── combined_transaction.dart
│   ├── repositories/
│   │   └── compare_repository.dart
│   └── usecases/
│       └── get_transactions_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── compare_bloc.dart
    │   ├── compare_event.dart
    │   └── compare_state.dart
    ├── pages/
    │   └── compare_view.dart
    └── widgets/
        ├── balance_header.dart
        ├── compare_contents_view.dart
        ├── empty_item_view.dart
        ├── error_view.dart
        ├── finance_entry_widget.dart
        ├── no_wallet_view.dart
        └── transaction_item.dart
```

---

## 🔄 Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                       PRESENTATION                          │
│  ┌──────────────┐                                           │
│  │ CompareView  │ (Displays transactions)                   │
│  └──────┬───────┘                                           │
│         │                                                   │
│         ▼                                                   │
│  ┌──────────────┐                                           │
│  │ CompareBloc  │ (State management)                        │
│  └──────┬───────┘                                           │
└─────────┼─────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                        DOMAIN                               │
│  ┌──────────────────────────────┐                           │
│  │  GetTransactionsUseCase      │                           │
│  │  GetExpensesUseCase          │                           │
│  │  GetIncomesUseCase           │                           │
│  └──────────┬───────────────────┘                           │
│             │                                               │
│             ▼                                               │
│  ┌──────────────────────────────┐                           │
│  │   CompareRepository          │ (Interface)               │
│  └──────────┬───────────────────┘                           │
└─────────────┼─────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                         DATA                                │
│  ┌──────────────────────────────┐                           │
│  │  CompareRepositoryImpl       │ (Polymorphic adapter)     │
│  └──────────┬───────────────────┘                           │
│             │                                               │
│      ┌──────┴──────┐                                        │
│      ▼             ▼                                        │
│  ┌─────────┐  ┌──────────────┐                             │
│  │  Hive   │  │  Firestore   │                             │
│  │DataSource│ │ DataSource   │                             │
│  └─────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Structure

### Firestore (Cloud)

```
users/{userId}/
  └── wallets/{walletId}/
      ├── incomes/{incomeId}
      │   ├── title: string
      │   ├── amount: number
      │   ├── tag: string
      │   ├── date: timestamp
      │   ├── time: string
      │   └── walletId: string
      └── expenses/{expenseId}
          ├── title: string
          ├── amount: number
          ├── tag: string
          ├── date: timestamp
          ├── time: string
          └── walletId: string
```

### Hive (Local)

```
expenses_box: Box<ExpenseModel>
  ├── [expenseId]: ExpenseModel
  ├── [expenseId]: ExpenseModel
  └── ...

incomes_box: Box<IncomeModel>
  ├── [incomeId]: IncomeModel
  ├── [incomeId]: IncomeModel
  └── ...
```

---

## 🧩 Layer Responsibilities

### 1. **Domain Layer**

**Purpose**: Business logic and entities

#### Models
- `CombinedTransaction`: Wrapper for income/expense items

#### Repositories (Interfaces)
- `CompareRepository`: Defines data access contract

#### Use Cases
- `GetTransactionsUseCase`: Fetch all transactions
- `GetExpensesUseCase`: Fetch only expenses
- `GetIncomesUseCase`: Fetch only incomes

---

### 2. **Data Layer**

**Purpose**: Data persistence and retrieval

#### DataSources
- `CompareHiveDataSource`: Local storage (Hive)
- `CompareFirestoreDataSource`: Cloud storage (Firestore)

#### Repository Implementation
- `CompareRepositoryImpl`: Polymorphic adapter between datasources

**Example:**
```dart
// Switch between Hive and Firestore
final repository = CompareRepositoryImpl(
  dataSource: useCloud 
    ? CompareFirestoreDataSource() 
    : CompareHiveDataSource(),
);
```

---

### 3. **Presentation Layer**

**Purpose**: UI and state management

#### BLoC (State Management)
- `CompareBloc`: Manages transaction loading state
- `CompareEvent`: User actions (load transactions)
- `CompareState`: UI states (loading, loaded, error, empty)

#### Pages
- `CompareView`: Main page displaying transactions

#### Widgets
- `BalanceHeader`: Shows wallet balance and name
- `TransactionListView`: List of transactions
- `EmptyItemsView`: Empty state placeholder
- `ErrorView`: Error display

---

## 🚀 Usage Example

### 1. **Setup in main.dart**

```dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider(
      create: (context) => CompareRepositoryImpl(
        dataSource: CompareHiveDataSource(), // or CompareFirestoreDataSource()
      ),
    ),
  ],
  child: MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => CompareBloc(
          context.read<CompareRepositoryImpl>().dataSource,
        ),
      ),
    ],
    child: MyApp(),
  ),
)
```

### 2. **Load Transactions**

```dart
context.read<CompareBloc>().add(
  GetTransactionsEvent(
    userId: 'user123',
    walletId: 'wallet456',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
  ),
);
```

### 3. **Listen to State Changes**

```dart
BlocBuilder<CompareBloc, CompareState>(
  builder: (context, state) {
    return switch (state) {
      CompareLoadingSt() => CircularProgressIndicator(),
      CompareLoadedSt() => TransactionList(state.transactions),
      CompareEmptySt() => EmptyView(),
      CompareErrorSt() => ErrorView(state.error),
      _ => Container(),
    };
  },
)
```

---

## 🔧 Key Features

### Stream-Based Real-Time Updates

Both Hive and Firestore datasources return **Streams**, enabling real-time UI updates when data changes.

```dart
@override
Stream<List<CombinedTransaction>> getTransactions({...}) {
  return _firestore
    .collection('users/$userId/wallets/$walletId/expenses')
    .snapshots() // ✅ Real-time stream
    .map((snapshot) => ...);
}
```

### Polymorphic Data Source Switching

Easy switching between local and cloud storage:

```dart
// Local mode
final repo = CompareRepositoryImpl(
  dataSource: CompareHiveDataSource(),
);

// Cloud mode
final repo = CompareRepositoryImpl(
  dataSource: CompareFirestoreDataSource(),
);
```

### Date Range Filtering

Efficient filtering by date range at the data layer:

```dart
_firestore
  .collection('expenses')
  .where('date', isGreaterThanOrEqualTo: startDate)
  .where('date', isLessThanOrEqualTo: endDate)
  .snapshots();
```

---

## 📊 State Management Flow

```
User Action (e.g., "Load Transactions")
          ↓
CompareBloc.add(GetTransactionsEvent)
          ↓
_onGetTransactions() handler
          ↓
GetTransactionsUseCase.call()
          ↓
CompareRepository.getTransactions()
          ↓
[Hive/Firestore] DataSource.getTransactions()
          ↓
Stream<List<CombinedTransaction>>
          ↓
BLoC emits states:
  - CompareLoadingSt
  - CompareLoadedSt(transactions)
  - CompareEmptySt
  - CompareErrorSt(error)
          ↓
UI rebuilds via BlocBuilder
```

---

## 🧪 Testing Strategy

### Unit Tests (Domain Layer)

```dart
test('GetTransactionsUseCase returns combined transactions', () {
  final mockRepo = MockCompareRepository();
  final useCase = GetTransactionsUseCase(mockRepo);
  
  // Test business logic
});
```

### Integration Tests (Data Layer)

```dart
test('CompareHiveDataSource filters by date range', () async {
  final dataSource = CompareHiveDataSource();
  
  final transactions = await dataSource.getTransactions(
    userId: 'user1',
    walletId: 'wallet1',
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
  ).first;
  
  expect(transactions, isNotEmpty);
});
```

### Widget Tests (Presentation Layer)

```dart
testWidgets('CompareView displays transactions', (tester) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => CompareBloc(mockRepository),
      child: CompareView(...),
    ),
  );
  
  expect(find.byType(TransactionListView), findsOneWidget);
});
```

---

## 📝 Best Practices

### ✅ DO

- Use `Stream` for real-time data
- Filter data at the data layer (not UI)
- Keep UI widgets stateless when possible
- Use BLoC for all state management
- Handle errors gracefully with `CompareErrorSt`

### ❌ DON'T

- Don't access repository directly from UI
- Don't perform business logic in widgets
- Don't ignore empty states
- Don't forget to cancel stream subscriptions

---

## 🔄 Migration Notes

### Firestore Subcollection Structure

When migrating from old flat structure:

**Old:**
```
expenses/{expenseId}
incomes/{incomeId}
```

**New:**
```
users/{userId}/wallets/{walletId}/expenses/{expenseId}
users/{userId}/wallets/{walletId}/incomes/{incomeId}
```

This change enables:
- ✅ Better data isolation per wallet
- ✅ Efficient queries (no need to filter by walletId)
- ✅ Easier security rules in Firestore
- ✅ Scalable multi-wallet support

---

## 🚀 Future Improvements

- [ ] Add pagination for large transaction lists
- [ ] Implement transaction search/filter
- [ ] Add export to CSV/PDF
- [ ] Create analytics charts
- [ ] Support recurring transactions
- [ ] Add transaction categories

---

**Last Updated**: December 2024  
**Authors**: İbo + Claude