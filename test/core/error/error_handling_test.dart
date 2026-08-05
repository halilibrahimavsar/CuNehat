import 'package:cunehat/core/error/error_handling.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global handler'lar süreç geneli tekil durumdur: kurulumu geri almazsak
/// aynı dosyadaki sonraki testlerin (ve --concurrency ile aynı izolatı
/// paylaşan diğerlerinin) hata yakalaması bozulur.
void main() {
  late FlutterExceptionHandler? originalFlutterOnError;
  late bool Function(Object, StackTrace)? originalPlatformOnError;
  late ErrorWidgetBuilder originalErrorWidgetBuilder;

  setUp(() {
    originalFlutterOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
    originalErrorWidgetBuilder = ErrorWidget.builder;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
    ErrorWidget.builder = originalErrorWidgetBuilder;
  });

  test('framework hatası handler kurulur ve kendisi fırlatmaz', () {
    installGlobalErrorHandlers();

    expect(FlutterError.onError, isNotNull);
    expect(
      () => FlutterError.onError!(
        FlutterErrorDetails(
          exception: StateError('deneme'),
          stack: StackTrace.current,
          library: 'test',
        ),
      ),
      returnsNormally,
    );
  });

  test('kök zone asenkron hatası ele alınmış sayılır', () {
    installGlobalErrorHandlers();

    final handler = PlatformDispatcher.instance.onError;
    expect(handler, isNotNull);
    // false dönmek bazı platformlarda süreci sonlandırır: await edilmemiş tek
    // bir Future'ın uygulamayı kapatmasını istemiyoruz.
    expect(handler!(StateError('deneme'), StackTrace.current), isTrue);
  });

  test('stack trace olmayan hata da işlenebilir', () {
    installGlobalErrorHandlers();

    expect(
      () => FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('stack yok')),
      ),
      returnsNormally,
    );
  });
}
