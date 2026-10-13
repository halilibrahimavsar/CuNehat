import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/onboarding/log_reminder_offer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool offer({
    bool alreadyOffered = false,
    NotificationFrequency current = NotificationFrequency.none,
    int count = LogReminderOffer.minRecords,
  }) =>
      LogReminderOffer.shouldOffer(
        alreadyOffered: alreadyOffered,
        current: current,
        transactionCount: count,
      );

  group('ne zaman sorulur', () {
    test('üçüncü kayıtta, hatırlatma kapalıyken, daha önce sorulmadıysa', () {
      expect(offer(), isTrue);
    });

    test('ilk kayıtlarda sorulmaz: kullanıcı henüz karar vermedi', () {
      expect(offer(count: 0), isFalse);
      expect(offer(count: LogReminderOffer.minRecords - 1), isFalse);
    });

    test('bir kez sorulur', () {
      expect(offer(alreadyOffered: true), isFalse);
    });

    test('hatırlatmayı kendi açmış olana sorulmaz', () {
      expect(offer(current: NotificationFrequency.low), isFalse);
      expect(offer(current: NotificationFrequency.high), isFalse);
    });

    test('güncellemeyle gelen, yüzlerce kaydı olan kullanıcıya sorulmaz', () {
      expect(offer(count: LogReminderOffer.maxRecords), isTrue);
      expect(offer(count: LogReminderOffer.maxRecords + 1), isFalse);
      expect(offer(count: 271), isFalse);
    });
  });

  group('bir daha bakmaya gerek var mı', () {
    test('eşiğin altındaki yeni kullanıcı: evet (bayrak yazılmaz)', () {
      expect(
        LogReminderOffer.isSettled(
          current: NotificationFrequency.none,
          transactionCount: 1,
        ),
        isFalse,
      );
    });

    test('hatırlatma açık ya da kayıt çok: hayır', () {
      expect(
        LogReminderOffer.isSettled(
          current: NotificationFrequency.medium,
          transactionCount: 1,
        ),
        isTrue,
      );
      expect(
        LogReminderOffer.isSettled(
          current: NotificationFrequency.none,
          transactionCount: 500,
        ),
        isTrue,
      );
    });
  });

  test('teklif günde BİR hatırlatma açar; saati metinde yazar', () {
    expect(LogReminderOffer.frequency.dailySlots, hasLength(1));
    expect(LogReminderOffer.timeLabel, '13:00');
  });

  group('diyalog', () {
    Future<bool?> open(WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showLogReminderOfferDialog(context),
              child: const Text('aç'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.text('Yazmayı hatırlatalım mı?'), findsOneWidget);
      expect(find.textContaining('saat 13:00'), findsOneWidget);
      return result;
    }

    testWidgets('"Hatırlat" true döner', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showLogReminderOfferDialog(context),
              child: const Text('aç'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log-reminder-accept')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('içerik: tek soru, saat ve nereden kapatılacağı',
        (tester) async {
      await open(tester);

      expect(find.textContaining('Ayarlar > Bildirimler'), findsOneWidget);
      expect(find.text('Hatırlat'), findsOneWidget);
      expect(find.text('Şimdi değil'), findsOneWidget);
    });

    testWidgets('"Şimdi değil" ve dışarı dokunma false döner', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showLogReminderOfferDialog(context),
              child: const Text('aç'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('log-reminder-later')));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
