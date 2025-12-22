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
  const ServerFailure([super.message = 'Sunucu hatası oluştu']);
}

/// Cache failure - Local storage errors
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Önbellek hatası oluştu']);
}

/// Network failure - Internet connection errors
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'İnternet bağlantısı yok']);
}

/// Authentication failure - Auth related errors
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Kimlik doğrulama hatası']);
}

/// Validation failure - Input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Geçersiz veri']);
}

/// Not found failure - Resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Kayıt bulunamadı']);
}

/// Permission failure - Permission denied
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'İzin reddedildi']);
}
