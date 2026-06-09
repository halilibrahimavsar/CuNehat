enum ConnectionStatus { connected, disconnected, checking }

class ConnectionMonitorState {
  final ConnectionStatus status;
  final String? message;
  final DateTime? lastChecked;

  const ConnectionMonitorState({
    required this.status,
    this.message,
    this.lastChecked,
  });

  ConnectionMonitorState copyWith({
    ConnectionStatus? status,
    String? message,
    DateTime? lastChecked,
  }) {
    return ConnectionMonitorState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionMonitorState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          message == other.message &&
          lastChecked == other.lastChecked;

  @override
  int get hashCode => status.hashCode ^ message.hashCode ^ lastChecked.hashCode;

  @override
  String toString() =>
      'ConnectionMonitorState(status: $status, message: $message, lastChecked: $lastChecked)';
}

/// Deprecated old type alias for backward compatibility.
