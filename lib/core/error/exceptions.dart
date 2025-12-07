// ==========================================
// CORE/ERROR - EXCEPTIONS
// ==========================================

// lib/core/error/exceptions.dart

/// Base exception class for all exceptions in the app
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, [this.originalError]);

  @override
  String toString() =>
      'AppException: $message${originalError != null ? ' - $originalError' : ''}';
}

/// Server exception - API/Backend errors
class ServerException extends AppException {
  ServerException([String message = 'Sunucu hatası oluştu', dynamic error])
      : super(message, error);
}

/// Cache exception - Local storage errors
class CacheException extends AppException {
  CacheException([String message = 'Önbellek hatası oluştu', dynamic error])
      : super(message, error);
}

/// Network exception - Internet connection errors
class NetworkException extends AppException {
  NetworkException([String message = 'İnternet bağlantısı yok', dynamic error])
      : super(message, error);
}

/// Authentication exception - Auth related errors
class AuthenticationException extends AppException {
  AuthenticationException(
      [String message = 'Kimlik doğrulama hatası', dynamic error])
      : super(message, error);
}

/// Validation exception - Input validation errors
class ValidationException extends AppException {
  ValidationException([String message = 'Geçersiz veri', dynamic error])
      : super(message, error);
}

/// Not found exception - Resource not found
class NotFoundException extends AppException {
  NotFoundException([String message = 'Kayıt bulunamadı', dynamic error])
      : super(message, error);
}

/// Permission exception - Permission denied
class PermissionException extends AppException {
  PermissionException([String message = 'İzin reddedildi', dynamic error])
      : super(message, error);
}
