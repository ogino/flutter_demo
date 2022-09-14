import "package:flutter/material.dart";
import "package:webview_cookie_manager/webview_cookie_manager.dart";
import "package:webview_flutter/webview_flutter.dart";

class WebViewWidget extends StatelessWidget {
  const WebViewWidget(
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
    return WebView(
      initialUrl: url,
      javascriptMode: JavascriptMode.unrestricted,
    );
  }
}
