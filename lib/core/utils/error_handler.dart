import 'package:cunehat/core/error/failure.dart';
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
    }

    return ServerFailure('Beklenmeyen bir hata oluştu: ${error.toString()}');
  }
}
