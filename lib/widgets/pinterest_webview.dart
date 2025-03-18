import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class PinterestWebView extends StatefulWidget {
  const PinterestWebView({super.key});

  static void reloadPinterest() {
    if (_PinterestWebViewState.instance != null) {
      _PinterestWebViewState.instance!.reloadUrl();
    }
  }

  @override
  State<PinterestWebView> createState() => _PinterestWebViewState();
}

class _PinterestWebViewState extends State<PinterestWebView> {
  late final WebViewController _controller;
  static _PinterestWebViewState? instance;
  final String _pinterestUrl = 'https://in.pinterest.com/shishir_dey/';

  @override
  void initState() {
    super.initState();
    instance = this;

    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(_pinterestUrl));
  }

  @override
  void dispose() {
    if (instance == this) {
      instance = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

  void reloadUrl() {
    _controller.loadRequest(Uri.parse(_pinterestUrl));
  }
}

class PinterestIcon extends StatelessWidget {
  const PinterestIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.asset(
        'assets/icon/tabs/pinterest_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
