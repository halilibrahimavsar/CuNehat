// lib/core/usecases/usecase.dart

import 'package:cunehat/core/error/failure.dart';
import 'package:dartz/dartz.dart';

/// Base UseCase interface with input parameter and output result
/// [Type] - Return type
/// [Params] - Input parameter type
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// UseCase without parameters
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// UseCase with stream output
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// NoParams class for usecases that don't need parameters
class NoParams {
  const NoParams();
}
