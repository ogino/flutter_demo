import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewWidget extends StatelessWidget {
  const PdfViewWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const url = "https://www.cs.utexas.edu/users/novak/sparcv9.pdf";
    if (kDebugMode) {
      print("url is $url");
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF'),
        leading: IconButton(
          icon: const Icon(
            Icons.close,
          ),
          onPressed: () async {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.ios_share,
            ),
            onPressed: () async {
              await Share.share(url);
            },
          ),
        ],
      ),
      body: SfPdfViewer.network(url),
    );
  }
}
