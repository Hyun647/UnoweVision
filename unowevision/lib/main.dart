import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '네이버 웹뷰',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NaverWebView(),
    );
  }
}

class NaverWebView extends StatefulWidget {
  const NaverWebView({Key? key}) : super(key: key);

  @override
  State<NaverWebView> createState() => _NaverWebViewState();
}

class _NaverWebViewState extends State<NaverWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.naver.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('네이버'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
