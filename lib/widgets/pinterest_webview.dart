import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

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
  bool _isLoading = true;
  bool _hasConnectivity = true;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    instance = this;
    _initWebView();
    _startConnectivityTimer();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    if (instance == this) {
      instance = null;
    }
    super.dispose();
  }

  void _startConnectivityTimer() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_hasConnectivity) {
        _checkConnectivityAndLoad();
      }
    });
  }

  Future<void> _checkConnectivityAndLoad() async {
    try {
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      // If we get a response, we have connectivity
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!_hasConnectivity) {
          setState(() {
            _hasConnectivity = true;
          });
          reloadUrl();
        }
      }
    } catch (e) {
      if (_hasConnectivity) {
        setState(() {
          _hasConnectivity = false;
        });
      }
    }
  }

  void _initWebView() {
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
            // Update loading indicator
            setState(() {
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasConnectivity = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_pinterestUrl));
  }

  @override
  Widget build(BuildContext context) {
    Widget webViewWithRefresh = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    reloadUrl();
                    await _checkConnectivityAndLoad();
                  },
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: WebViewWidget(controller: _controller),
                ),
              ],
            ),

            // Loading indicator
            if (_isLoading)
              const Center(child: CupertinoActivityIndicator(radius: 20)),
          ],
        );
      },
    );

    return Column(
      children: [
        // No connectivity notification
        if (!_hasConnectivity && !_isLoading)
          Container(
            color: CupertinoColors.systemRed.withOpacity(0.9),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.wifi_slash,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No internet connection',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: _checkConnectivityAndLoad,
                      child: const Icon(
                        CupertinoIcons.refresh,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Content area
        Expanded(child: webViewWithRefresh),
      ],
    );
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
