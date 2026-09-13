import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/texts/local_auth_texts.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../../support/fake_local_auth_repository.dart';

void main() {
  testWidgets(
      'sensör kilitliyken biyometrik hatası çökmeden sayfanın dilinde gösterilir',
      (tester) async {
    // Eskiden `authenticate` fırlattığında bloc handler'ı patlıyor ve kilit
    // ekranında hiçbir şey olmuyordu. Bloc varsayılan (İngilizce) metinlerle
    // kurulduğu için mesajı sayfanın yerelleştirmesi gerekiyor.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final repo = FakeLocalAuthRepository(
      pinSet: true,
      bioEnabled: true,
      bioAvailable: true,
      authenticateError: PlatformException(code: 'LockedOut'),
    );
    const localized = 'Biyometrik kimlik doğrulama başarısız';
    final texts = const LocalAuthTexts()
        .copyWith(msgBiometricAuthenticationFailed: localized);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<LocalAuthLoginBloc>(
          create: (_) => LocalAuthLoginBloc(repository: repo),
          child: BiometricAuthPage(
            onSuccess: () {},
            showLogoutButton: false,
            texts: texts,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.authenticateCalls, 1);
    expect(find.text(localized), findsOneWidget);
    expect(
      find.text(const LocalAuthTexts().msgBiometricAuthenticationFailed),
      findsNothing,
    );
  });
}
