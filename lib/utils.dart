import "package:advertising_id/advertising_id.dart";
import "package:app_tracking_transparency/app_tracking_transparency.dart";
import "package:device_info_plus/device_info_plus.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:version/version.dart";

Future<String> findOSVersionIOS() async {
  try {
    final info = await DeviceInfoPlugin().iosInfo;
    return info.systemVersion ?? "15.0";
  } on PlatformException {
    return "15.0";
  }
}

const zeroId = "00000000-0000-0000-0000-000000000000";

Future<String> findAdIdAndroid() async {
  try {
    final enableTrack = await AdvertisingId.isLimitAdTrackingEnabled;
    if (kDebugMode) {
      print("enableTrack is $enableTrack");
    }
    if (enableTrack == null || !enableTrack) {
      return zeroId;
    }
    final id = await AdvertisingId.id(true);
    return id ?? zeroId;
  } on Exception {
    return zeroId;
  }
}

Future<String> findAdIdIOS() async {
  try {
    final iosVersion = await findOSVersionIOS();
    final version = Version.parse(iosVersion);
    if (kDebugMode) {
      print("version is $version");
    }
    if (version >= Version.parse("14.5")) {
      final TrackingStatus trackStatus =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (kDebugMode) {
        print("trackStatus is $trackStatus");
      }
      if (trackStatus == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 200));
        final status =
            await AppTrackingTransparency.requestTrackingAuthorization();
        if (kDebugMode) {
          print("status is $status");
        }
        if (status == TrackingStatus.authorized) {
          return await AppTrackingTransparency.getAdvertisingIdentifier();
        } else {
          return zeroId;
        }
      } else if (trackStatus == TrackingStatus.authorized) {
        return await AppTrackingTransparency.getAdvertisingIdentifier();
      }
    } else if (version >= Version.parse("14.0")) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (kDebugMode) {
        print("status is $status");
      }
      switch (status) {
        case TrackingStatus.notDetermined:
        case TrackingStatus.authorized:
          return await AppTrackingTransparency.getAdvertisingIdentifier();
        default:
          return zeroId;
      }
    } else {
      return await AppTrackingTransparency.getAdvertisingIdentifier();
    }
  } on Exception {
    return zeroId;
  }
  return zeroId;
}

Future<void> logFirebaseEvent(
    [String name = "",
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions]) async {
  if (name.isNotEmpty) {
    FirebaseAnalytics.instance
        .logEvent(name: name, parameters: parameters, callOptions: callOptions);
  }
}

Map<String, String> handleLink(String? link) {
  if (kDebugMode) {
    print("link = ${link ?? ""}");
  }
  Map<String, String> map = {};
  if (link != null) {
    map.addAll({"link": link});
    final uri = Uri.parse(link);
    if (uri.hasQuery) {
      map.addAll(uri.queryParameters);
    }
  }
  return map;
}
