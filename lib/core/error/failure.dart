// ==========================================
// CORE/ERROR - FAILURES
// ==========================================

// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

/// Base failure class for all failures in the app
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

/// Server failure - API/Backend errors
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Sunucu hatası oluştu'])
      : super(message);
}

/// Cache failure - Local storage errors
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Önbellek hatası oluştu'])
      : super(message);
}

/// Network failure - Internet connection errors
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'İnternet bağlantısı yok'])
      : super(message);
}

/// Authentication failure - Auth related errors
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Kimlik doğrulama hatası'])
      : super(message);
}

/// Validation failure - Input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Geçersiz veri']) : super(message);
}

/// Not found failure - Resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Kayıt bulunamadı']) : super(message);
}

/// Permission failure - Permission denied
class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'İzin reddedildi'])
      : super(message);
}
