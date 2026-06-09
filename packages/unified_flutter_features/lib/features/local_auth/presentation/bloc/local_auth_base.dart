/// Base class for all local authentication events.
///
/// All events in the local authentication BLoC should extend this class.
/// It provides equality checking based on runtime type for proper BLoC operation.
abstract class LocalAuthEvent {
  const LocalAuthEvent();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAuthEvent && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Base class for all local authentication states.
///
/// All states in the local authentication BLoC should extend this class.
/// It provides equality checking based on runtime type for proper BLoC operation.
abstract class LocalAuthState {
  const LocalAuthState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAuthState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
