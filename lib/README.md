# CuNehat - Project Architecture

## 📐 Architecture Overview

```
┌───────────────────────────────────────────────────┐
│                     PRESENTATION                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │  Wallet  │  │ Expense  │  │ Income   │         │
│  │   Page   │  │   Page   │  │   Page   │         │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘         │
│        │             │              │             │
│        └─────────────┴──────────────┘             │
│                      │                            │
└──────────────────────┼────────────────────────────┘
                       │
                       ▼
┌───────────────────────────────────────────────────┐
│                    BUSINESS LOGIC                 │
│              ┌──────────────────────┐             │
│              │      DataBloc        │             │
│              │  ┌────────────────┐  │             │
│              │  │  State Mgmt    │  │             │
│              │  │  Event Handler │  │             │
│              │  └────────────────┘  │             │
│              └──────────┬───────────┘             │
└─────────────────────────┼─────────────────────────┘
                          │
                          ▼
┌───────────────────────────────────────────────────┐
│                   DATA LAYER                      │
│         ┌──────────────────────────────┐          │
│         │      DataRepository          │          │
│         │  (Single Source of Truth)    │          │
│         └──────┬───────────────┬───────┘          │
│                │               │                  │
│       ┌────────▼──────┐   ┌───▼────────┐          │
│       │ LocalStorage  │   │ Firestore  │          │
│       │    (Hive)     │   │  Service   │          │
│       └───────────────┘   └────────────┘          │
│                                                   │
│         ┌──────────────────────────────┐          │
│         │       SyncService            │          │
│         │  (Offline Sync Queue)        │          │
│         └──────────────────────────────┘          │
└───────────────────────────────────────────────────┘
```

## 🏗️ Layer Responsibilities

### 1. **Presentation Layer** (`lib/pages/`)
- **Responsibility**: UI rendering and user interactions
- **Rules**: 
  - Never access repository directly
  - Always communicate through BLoC
  - No business logic
  - Focus on user experience

**Example:**
```dart
// ✅ CORRECT
context.read<DataBloc>().add(AddExpenseEvent(expense: newExpense));

// ❌ WRONG
await dataRepository.addExpense(expense: newExpense);
```

### 2. **Business Logic Layer** (`lib/data_layer/shared_data_bloc/`)
- **Responsibility**: State management and business rules
- **Rules**:
  - Process events
  - Emit states
  - Coordinate data operations
  - No UI dependencies

**Key Files:**
- `data_bloc.dart` - Main BLoC implementation
- `data_event.dart` - All possible user actions
- `data_state.dart` - All possible UI states

### 3. **Data Layer** (`lib/data_layer/`)
- **Responsibility**: Data persistence and retrieval
- **Components**:

#### a) DataRepository (Façade)
```dart
class DataRepository {
  // Abstracts storage mode
  // Handles sync coordination
  // Manages balance calculations
}
```

#### b) LocalDataService (Hive)
```dart
class LocalDataService {
  // Fast local storage
  // Offline-first
  // Always available
}
```

#### c) FirestoreService (Cloud)
```dart
class FirestoreService {
  // Cloud backup
  // Multi-device sync
  // Optional
}
```

#### d) SyncService (Queue)
```dart
class SyncService {
  // Queues offline operations
  // Auto-retries on connection
  // Guarantees eventual consistency
}
```

## 🔄 Data Flow

### Example: Adding an Expense

```
1. USER INTERACTION
   └─> User fills form and clicks "Save"

2. UI LAYER (expense_page.dart)
   └─> context.read<DataBloc>().add(AddExpenseEvent(...))

3. BLOC LAYER (data_bloc.dart)
   └─> _onAddExpense() handler receives event
       ├─> emit(LoadingDataState())
       ├─> await dataRepository.addExpense()
       └─> emit(SuccessfullyCreatedItemState())

4. DATA REPOSITORY (data_repository.dart)
   ├─> Save to local storage (always)
   ├─> Adjust balance (-amount)
   └─> Sync to cloud if needed
       ├─> If online: Direct upload
       └─> If offline: Queue for later

5. SYNC SERVICE (sync_service.dart)
   └─> If queued: Waits for connection
       └─> Auto-uploads when online

6. BLOC LISTENER (wallet_page.dart)
   └─> Hears SuccessfullyCreatedItemState
       ├─> Shows success message
       └─> Auto-refreshes data
```

## 📊 State Management Pattern

### State Types

```dart
// Loading states
LoadingDataState      // Initial data fetch
SyncingDataState      // Background sync

// Success states
SuccessfullyGetCompareState    // Data loaded
SuccessfullyCreatedItemState   // Item added
SuccessfullyDeletedItemState   // Item removed
SuccessfullyUpdatedItemState   // Item modified
SyncSuccessState              // Sync completed

// Error/Warning states
ErrorState           // Operation failed
NoDataState         // Empty result
SyncFailedState     // Sync failed
```

### Event Types

```dart
// Data fetching
GetCompareEvent              // Get all data
GetExpenseByDateRngEvent    // Get expenses only
GetIncomeByDateRngEvent     // Get incomes only

// CRUD operations
AddExpenseEvent / AddIncomeEvent
DeleteExpenseEvent / DeleteIncomeEvent
UpdateExpenseEvent / UpdateIncomeEvent

// Sync operations
SyncDataEvent       // Manual sync trigger
RefreshDataEvent    // Silent data refresh
```

## 🔐 Storage Modes

### Local Mode (Default)
```dart
Storage: Hive (local SQLite-like DB)
Sync: Disabled
Balance: Stored in SharedPreferences
Use Case: Privacy-focused users, offline-only
```

### Cloud Mode
```dart
Storage: Firestore (with local cache)
Sync: Automatic + manual
Balance: Synced across devices
Use Case: Multi-device users
```

### Migration Flow
```dart
1. User enables cloud mode
2. All local data uploaded to Firestore
3. Local storage cleared
4. Switch to cloud mode
5. Future operations sync automatically
```

## 🛠️ Key Design Patterns

### 1. **Repository Pattern**
- Single point of data access
- Abstracts storage implementation
- Easy to switch/test

### 2. **BLoC Pattern**
- Separation of UI and logic
- Reactive programming
- Testable business logic

### 3. **Offline-First**
- Local storage always used
- Cloud sync is optional
- Works without internet

### 4. **Event Sourcing (Sync)**
- Operations queued as events
- Replayed when online
- Eventual consistency

## 📝 Best Practices

### UI Components
```dart
// ✅ DO: Use BLoC for state
BlocBuilder<DataBloc, DataState>(
  builder: (context, state) {
    if (state is LoadingDataState) return Loader();
    if (state is SuccessfullyGetCompareState) return DataView();
    return ErrorView();
  },
)

// ❌ DON'T: Direct repository access
final data = await context.read<DataRepository>().getData();
```

### Event Handling
```dart
// ✅ DO: Listen for operation success
BlocListener<DataBloc, DataState>(
  listener: (context, state) {
    if (state is SuccessfullyCreatedItemState) {
      // Auto-refresh
      context.read<DataBloc>().add(RefreshDataEvent(...));
    }
  },
)

// ❌ DON'T: Manual refresh without state check
context.read<DataBloc>().add(GetCompareEvent(...));
```

### Error Handling
```dart
// ✅ DO: Graceful degradation
try {
  return await _firestoreService.getData();
} catch (e) {
  // Fallback to local
  return await _localDataService.getData();
}

// ❌ DON'T: Crash on error
return await _firestoreService.getData();
```

## 🧪 Testing Strategy

### Unit Tests
```dart
// Test BLoC events
test('AddExpenseEvent emits success state', () async {
  final bloc = DataBloc(repository: mockRepo);
  bloc.add(AddExpenseEvent(expense: testExpense));
  await expectLater(
    bloc.stream,
    emitsInOrder([LoadingDataState(), SuccessfullyCreatedItemState()]),
  );
});
```

### Integration Tests
```dart
// Test repository with real services
test('DataRepository syncs to cloud when online', () async {
  final repo = DataRepository(...);
  await repo.addExpense(expense: testExpense);
  final cloudData = await firestoreService.getExpenses();
  expect(cloudData, contains(testExpense));
});
```

### Widget Tests
```dart
// Test UI interactions
testWidgets('Add expense button shows form', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  expect(find.byType(ExpenseForm), findsOneWidget);
});
```

## 🚀 Performance Optimizations

1. **Lazy Loading**: Fetch only visible date ranges
2. **Local Cache**: Hive for instant reads
3. **Debounced Sync**: Batch operations every 5 minutes
4. **Pagination**: Load expenses in chunks
5. **Memoization**: Cache computed balances

## 🔄 Future Improvements

- [ ] Stream-based real-time updates
- [ ] Background sync worker
- [ ] Export to CSV/Excel
- [ ] Analytics dashboard
- [ ] Recurring transactions
- [ ] Budget planning
- [ ] Multi-currency support

---

**Last Updated**: November 2025  
**Maintainer**: İbo + Claude