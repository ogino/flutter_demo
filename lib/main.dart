import 'dart:async';

import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    runApp(const MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
    FirebaseAnalyticsObserver(analytics: analytics);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Demo",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorObservers: [observer],
      home: MainPage(analytics: analytics),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key, required this.analytics}) : super(key: key);
  final FirebaseAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("デモ コンテンツ"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text("Crashlytics"),
              onPressed: () {
                FirebaseCrashlytics.instance.crash();
              },
            ),
            ElevatedButton(
              child: const Text("Analytics"),
              onPressed: () async {
                await analytics.logEvent(
                  name: "test_event",
                  parameters: <String, dynamic> {
                    "string": "Event Name",
                    "int": 1,
                    "long": -1,
                    "double": double.infinity,
                    "bool": true,
                  }
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

