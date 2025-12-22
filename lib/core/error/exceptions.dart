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
  ServerException([super.message = 'Sunucu hatası oluştu', super.error]);
}

/// Cache exception - Local storage errors
class CacheException extends AppException {
  CacheException([super.message = 'Önbellek hatası oluştu', super.error]);
}

/// Network exception - Internet connection errors
class NetworkException extends AppException {
  NetworkException([super.message = 'İnternet bağlantısı yok', super.error]);
}

/// Authentication exception - Auth related errors
class AuthenticationException extends AppException {
  AuthenticationException(
      [super.message = 'Kimlik doğrulama hatası', super.error]);
}

/// Validation exception - Input validation errors
class ValidationException extends AppException {
  ValidationException([super.message = 'Geçersiz veri', super.error]);
}

/// Not found exception - Resource not found
class NotFoundException extends AppException {
  NotFoundException([super.message = 'Kayıt bulunamadı', super.error]);
}

/// Permission exception - Permission denied
class PermissionException extends AppException {
  PermissionException([super.message = 'İzin reddedildi', super.error]);
}
