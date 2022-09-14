import "package:demo/webview/web_view_widget.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:webview_cookie_manager/webview_cookie_manager.dart";

class CookieWidget extends StatelessWidget {
  const CookieWidget({Key? key}) : super(key: key);
  static final cookieManager = WebviewCookieManager();
  static const url = "https://www.google.com/";

  @override
  Widget build(BuildContext context) {
    cookieManager.clearCookies();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cookie連携テスト"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                child: const Text("WebViewを表示"),
                onPressed: () {
                  showCupertinoModalBottomSheet(
                      expand: true,
                      useRootNavigator: true,
                      context: context,
                      builder: (context) => WebViewWidget(
                          cookieManager: cookieManager, url: url));
                }),
            ElevatedButton(
              child: const Text("Cookieを表示"),
              onPressed: () async {
                final cookies = await cookieManager.getCookies(url);
                var text = "";
                for (var cookie in cookies) {
                  text += "${cookie.name} : ${cookie.value}\n";
                }
                if (kDebugMode) {
                  print("text is $text");
                }
                showDialog<void>(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: const Text("Cookieデータ"),
                        content: Text(text),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, "Cancel"),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, "OK"),
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    });
              },
            ),
          ],
        ),
      ),
    );
  }
}
