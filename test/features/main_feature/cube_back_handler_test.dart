import 'dart:async';

import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:cunehat/features/main_feature/widgets/cube_back_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Küpün alt sayfaları route değil; sistem geri jesti onları ancak
/// [CubeBackHandler] sayesinde görebiliyor. Kapı olmadan çerçeve poplanacak
/// route bulamayıp `SystemNavigator.pop` ile uygulamayı kapatıyordu.
void main() {
  late List<String> platformCalls;

  setUp(() {
    platformCalls = <String>[];
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('alt sayfadayken geri, uygulamayı kapatmaz; ana görünüme döner',
      (tester) async {
    late HomeNavigationController controller;
    await tester.pumpWidget(_Host(onReady: (c) => controller = c));
    await tester.pumpAndSettle();

    unawaited(controller.navigateToView(1));
    await tester.pumpAndSettle();
    expect(controller.viewStack.currentIndex, 1);

    platformCalls.clear();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    expect(controller.isAtMainView, isTrue);
  });

  testWidgets('ana görünümdeyken geri normal davranır (uygulamadan çıkış)',
      (tester) async {
    late HomeNavigationController controller;
    await tester.pumpWidget(_Host(onReady: (c) => controller = c));
    await tester.pumpAndSettle();
    expect(controller.isAtMainView, isTrue);

    platformCalls.clear();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(platformCalls, contains('SystemNavigator.pop'));
  });

  testWidgets('ikinci alt sayfadan geri de ana görünüme döner', (tester) async {
    late HomeNavigationController controller;
    await tester.pumpWidget(_Host(onReady: (c) => controller = c));
    await tester.pumpAndSettle();

    unawaited(controller.navigateToView(2));
    await tester.pumpAndSettle();
    expect(controller.viewStack.currentIndex, 2);

    platformCalls.clear();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Alt sayfalar iç içe değil KARDEŞ (çarktan biri seçilir), bu yüzden
    // geri tek adımda köke döner — araya "Detay" girmez.
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    expect(controller.isAtMainView, isTrue);
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.onReady});

  final void Function(HomeNavigationController) onReady;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TickerProviderStateMixin {
  late final HomeNavigationController controller =
      HomeNavigationController(this);

  @override
  void initState() {
    super.initState();
    controller.setupViewStack(
      mainView: const Center(child: Text('ANA')),
      subViews: const [
        Center(child: Text('ALT-1')),
        Center(child: Text('ALT-2')),
      ],
    );
    widget.onReady(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CubeBackHandler(
        controller: controller,
        child: Scaffold(
          body: AnimatedBuilder(
            animation: controller.viewStack,
            builder: (_, __) => controller.viewStack.buildTransition(),
          ),
        ),
      ),
    );
  }
}
