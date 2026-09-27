import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splashscreen_ghdinteractivestudio/splashscreen_ghdinteractivestudio.dart';

void main() {
  testWidgets('AppSplashScreen displays app and company information properly', (tester) async {
    bool finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AppSplashScreen(
          appName: 'Lupus Arena',
          companyName: 'ghdinteractivestudio',
          companyPrefix: 'from',
          duration: const Duration(milliseconds: 100),
          onFinish: () => finished = true,
        ),
      ),
    );

    expect(find.text('Lupus Arena'), findsOneWidget);
    expect(find.text('ghdinteractivestudio'), findsOneWidget);
    expect(find.text('from'), findsOneWidget);
    expect(finished, isFalse);
  });

  testWidgets('AppSplashScreen triggers onFinish upon transition completion', (tester) async {
    bool finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AppSplashScreen(
          appName: 'Lupus Arena',
          companyName: 'ghdinteractivestudio',
          duration: const Duration(milliseconds: 30),
          entranceDuration: const Duration(milliseconds: 10),
          exitDuration: const Duration(milliseconds: 10),
          onFinish: () => finished = true,
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(finished, isTrue);
  });
}
