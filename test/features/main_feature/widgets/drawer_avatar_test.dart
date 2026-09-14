import 'package:cunehat/features/main_feature/widgets/modern_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(String? photoUrl) => MaterialApp(
        home: Scaffold(
          body: Center(child: DrawerAvatar(photoUrl: photoUrl)),
        ),
      );

  // Testte ağ istekleri 400 döner: çevrimdışı ya da geçersiz fotoğraf adresinin
  // aynısı. İşleyici yokken yükleme hatası "yakalanmamış" diye raporlanıyor
  // (test bu durumda kendiliğinden düşer) ve avatar boş bir daire kalıyordu.
  testWidgets('fotoğraf yüklenemezse kişi ikonuna düşer', (tester) async {
    await tester.pumpWidget(host('https://example.invalid/avatar.png'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('bağlı hesap fotoğrafı yoksa kişi ikonu gösterilir',
      (tester) async {
    await tester.pumpWidget(host(null));

    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
