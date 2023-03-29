import "package:flutter/material.dart";
import "package:webview_cookie_manager/webview_cookie_manager.dart";
import "package:webview_flutter/webview_flutter.dart";

class WebWidget extends StatelessWidget {
  const WebWidget(
      {Key? key, required this.cookieManager, required this.url})
      : super(key: key);
  final WebviewCookieManager cookieManager;
  final String url;

  _clearCookies() async {
    final found = await cookieManager.hasCookies();
    if (found) {
      await cookieManager.clearCookies();
    }
  }

  @override
  Widget build(BuildContext context) {
    _clearCookies();
    var controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.loadRequest(Uri.parse(url));
    return Scaffold(
        appBar: AppBar(title: Text("Load $url")),
        body: WebViewWidget(controller: controller)
    );
  }
}
