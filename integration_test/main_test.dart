import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:demo/main.dart" as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("successful test", (WidgetTester tester) async {
    await restoreFlutterError(() async {
      app.main();
      await tester.pumpAndSettle();
    });

    expect(find.text("Crashlytics"), findsOneWidget);

    await tester.tap(find.text("WebView-Native Cookie Linkage"));
    await tester.pumpAndSettle();

    expect(find.text("Cookieを表示"), findsOneWidget);
  });
}

Future<void> restoreFlutterError(Future<void> Function() call) async {
  final originalOnError = FlutterError.onError!;
  await call();
  final overriddenOnError = FlutterError.onError!;

  // restore FlutterError.onError
  FlutterError.onError = (FlutterErrorDetails details) {
    if (overriddenOnError != originalOnError) overriddenOnError(details);
    originalOnError(details);
  };
}

