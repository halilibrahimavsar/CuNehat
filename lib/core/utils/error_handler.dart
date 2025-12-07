// lib/core/utils/error_handler.dart
import 'package:cunehat/core/error/failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../error/exceptions.dart';

/// Error handler utility for converting exceptions to failures
class ErrorHandler {
  /// Convert exception to failure
  static Failure handleException(dynamic error) {
    if (error is ServerException) {
      return ServerFailure(error.message);
    } else if (error is CacheException) {
      return CacheFailure(error.message);
    } else if (error is NetworkException) {
      return NetworkFailure(error.message);
    } else if (error is AuthenticationException) {
      return AuthenticationFailure(error.message);
    } else if (error is ValidationException) {
      return ValidationFailure(error.message);
    } else if (error is NotFoundException) {
      return NotFoundFailure(error.message);
    } else if (error is PermissionException) {
      return PermissionFailure(error.message);
    } else if (error is FirebaseException) {
      return _handleFirebaseException(error);
    } else if (error is FirebaseAuthException) {
      return _handleFirebaseAuthException(error);
    }

    return ServerFailure('Beklenmeyen bir hata oluştu: ${error.toString()}');
  }

  /// Handle Firebase exceptions
  static Failure _handleFirebaseException(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return const PermissionFailure('Bu işlem için yetkiniz yok');
      case 'unavailable':
        return const NetworkFailure('Sunucu şu anda kullanılamıyor');
      case 'not-found':
        return const NotFoundFailure('İstenen kayıt bulunamadı');
      case 'already-exists':
        return const ValidationFailure('Bu kayıt zaten mevcut');
      case 'resource-exhausted':
        return const ServerFailure('Kaynak limiti aşıldı');
      case 'failed-precondition':
        return const ValidationFailure('İşlem önkoşulları sağlanmadı');
      case 'aborted':
        return const ServerFailure('İşlem iptal edildi');
      case 'out-of-range':
        return const ValidationFailure('Geçersiz değer aralığı');
      case 'unimplemented':
        return const ServerFailure('Bu özellik henüz uygulanmadı');
      case 'internal':
        return const ServerFailure('Sunucu iç hatası');
      case 'data-loss':
        return const ServerFailure('Veri kaybı oluştu');
      default:
        return ServerFailure('Sunucu hatası: ${error.message ?? error.code}');
    }
  }

  /// Handle Firebase Auth exceptions
  static Failure _handleFirebaseAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return const AuthenticationFailure('Kullanıcı bulunamadı');
      case 'wrong-password':
        return const AuthenticationFailure('Hatalı şifre');
      case 'email-already-in-use':
        return const ValidationFailure('Bu e-posta adresi zaten kullanımda');
      case 'invalid-email':
        return const ValidationFailure('Geçersiz e-posta adresi');
      case 'weak-password':
        return const ValidationFailure('Şifre çok zayıf');
      case 'user-disabled':
        return const AuthenticationFailure('Kullanıcı hesabı devre dışı');
      case 'operation-not-allowed':
        return const PermissionFailure('Bu işleme izin verilmiyor');
      case 'too-many-requests':
        return const ServerFailure(
            'Çok fazla deneme. Lütfen daha sonra tekrar deneyin');
      case 'network-request-failed':
        return const NetworkFailure('İnternet bağlantısı yok');
      case 'requires-recent-login':
        return const AuthenticationFailure(
            'Bu işlem için yeniden giriş yapmanız gerekiyor');
      default:
        return AuthenticationFailure(
            'Kimlik doğrulama hatası: ${error.message ?? error.code}');
    }
  }
}
