import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

void main() {
  testWidgets('initial state has correct default values', (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    expect(controller.horizontalController.value, 0.5);
    expect(controller.isAtMainView, true);
    expect(controller.selectedSubIndices, isEmpty);
    expect(controller.isAnimating, false);
    expect(controller.currentSliderState, SliderState.transactions);
    controller.dispose();
  });

  testWidgets('setupViewStack updates view stack views', (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');
    const subView2 = Text('Sub 2');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1, subView2],
    );

    expect(controller.viewStack.views.length, 3);
    expect(controller.viewStack.views[0], mainView);
    expect(controller.viewStack.views[1], subView1);
    expect(controller.viewStack.views[2], subView2);
    controller.dispose();
  });

  testWidgets('navigateToView updates active index and remembers sub index for slider state', (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');
    const subView2 = Text('Sub 2');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1, subView2],
    );

    // Navigate to Sub 1 (index 1)
    controller.navigateToView(1, sliderState: SliderState.savedMoney);

    // Let the animation run
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.viewStack.currentIndex, 1);
    expect(controller.isAtMainView, false);
    expect(controller.selectedSubIndices[SliderState.savedMoney], 0);

    controller.dispose();
  });

  testWidgets('closeToMain returns to index 0 and clears selectedSubIndices', (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1],
    );

    controller.navigateToView(1, sliderState: SliderState.debt);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.viewStack.currentIndex, 1);
    expect(controller.selectedSubIndices, isNotEmpty);

    controller.closeToMain();
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.viewStack.currentIndex, 0);
    expect(controller.isAtMainView, true);
    expect(controller.selectedSubIndices, isEmpty);

    controller.dispose();
  });

  testWidgets('onWalletChanged calls closeToMain and clears selectedSubIndices', (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1],
    );

    controller.navigateToView(1, sliderState: SliderState.transactions);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.viewStack.currentIndex, 1);

    controller.onWalletChanged();
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.viewStack.currentIndex, 0);
    expect(controller.selectedSubIndices, isEmpty);

    controller.dispose();
  });

  testWidgets('horizontal controller movement closes subviews if not at main view', (WidgetTester tester) async {
    final controller = HomeNavigationController(const TestVSync());
    const mainView = Text('Main');
    const subView1 = Text('Sub 1');

    controller.setupViewStack(
      mainView: mainView,
      subViews: [subView1],
    );

    controller.navigateToView(1, sliderState: SliderState.transactions);
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.viewStack.currentIndex, 1);

    // Move horizontal slider to trigger listener
    controller.horizontalController.value = 0.8;
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.viewStack.currentIndex, 0);

    controller.dispose();
  });
}
