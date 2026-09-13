import 'package:bloc/bloc.dart';
import 'package:cunehat/core/error/app_bloc_observer.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/error/error_log.dart';
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
  late BlocObserver originalBlocObserver;

  setUp(() {
    originalFlutterOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
    originalErrorWidgetBuilder = ErrorWidget.builder;
    originalBlocObserver = Bloc.observer;
    ErrorLog.instance.resetForTest();
  });

  tearDown(() {
    FlutterError.onError = originalFlutterOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
    ErrorWidget.builder = originalErrorWidgetBuilder;
    Bloc.observer = originalBlocObserver;
    ErrorLog.instance.resetForTest();
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

  test('framework hatası katmanıyla birlikte hata günlüğüne yazılır', () {
    installGlobalErrorHandlers();

    FlutterError.onError!(
      FlutterErrorDetails(
        exception: StateError('build patladı'),
        stack: StackTrace.current,
        library: 'widgets library',
      ),
    );

    final entry = ErrorLog.instance.entries.single;
    expect(entry.source, 'FlutterError · widgets library');
    expect(entry.message, contains('build patladı'));
  });

  test('kök zone hatası hata günlüğüne yazılır', () {
    installGlobalErrorHandlers();

    PlatformDispatcher.instance.onError!(
      StateError('await edilmemiş'),
      StackTrace.current,
    );

    expect(ErrorLog.instance.entries.single.source, 'PlatformDispatcher');
  });

  test('kurulum Bloc hatalarını da aynı kanala bağlar', () {
    installGlobalErrorHandlers();

    expect(Bloc.observer, isA<AppBlocObserver>());
  });

  test('reportError bilerek yakalanan hatayı da günlüğe yazar', () {
    reportError('Kategori indeksi', StateError('okunamadı'));

    final entry = ErrorLog.instance.entries.single;
    expect(entry.source, 'Kategori indeksi');
    expect(entry.type, 'StateError');
  });
}
