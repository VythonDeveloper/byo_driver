import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewUI extends StatefulWidget {
  final url;
  const WebViewUI({Key? key, this.url}) : super(key: key);

  @override
  State<WebViewUI> createState() => _WebViewUIState();
}

class _WebViewUIState extends State<WebViewUI> {
  @override
  void initState() {
    super.initState();
    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: widget.url,
    );
  }
}
