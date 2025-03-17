import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'My Portfolio',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        brightness: Brightness.light,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // Reload Pinterest URL when Pinterest tab is clicked
            if (index == 3 && _selectedIndex == 3) {
              _reloadPinterestUrl();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.photo),
            label: 'Photography',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: 'Diary',
          ),
          BottomNavigationBarItem(icon: _PinterestIcon(), label: 'Pinterest'),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Contact',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (context) {
            if (index == 3) {
              // Pinterest tab
              return CupertinoPageScaffold(
                navigationBar: const CupertinoNavigationBar(
                  middle: Text('Pinterest'),
                ),
                child: SafeArea(child: const PinterestWebView()),
              );
            }

            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text(
                  index == 0
                      ? 'Home'
                      : index == 1
                      ? 'Photography'
                      : index == 2
                      ? 'Diary'
                      : 'Contact',
                ),
              ),
              child: const SafeArea(child: Center(child: Text('Coming soon'))),
            );
          },
        );
      },
    );
  }

  void _reloadPinterestUrl() {
    // Find the PinterestWebView and reload the URL
    final webViewState = _PinterestWebViewState.instance;
    if (webViewState != null) {
      webViewState.reloadUrl();
    }
  }
}

class PinterestWebView extends StatefulWidget {
  const PinterestWebView({super.key});

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

class _PinterestIcon extends StatelessWidget {
  const _PinterestIcon();

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
