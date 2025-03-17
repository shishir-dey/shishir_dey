import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:url_launcher/url_launcher.dart';

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
  // Define the background color
  final Color backgroundColor = const Color.fromRGBO(217, 210, 189, 1);

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

            // Home, Photography, and Contact tabs with the same background color
            if (index == 0 || index == 1 || index == 4) {
              return CupertinoPageScaffold(
                backgroundColor: backgroundColor,
                navigationBar: CupertinoNavigationBar(
                  backgroundColor: backgroundColor,
                  middle: Text(
                    index == 0
                        ? 'Home'
                        : index == 1
                        ? 'Photography'
                        : 'Contact',
                  ),
                ),
                child: SafeArea(
                  child:
                      index == 0
                          ? const HomeScreen()
                          : index == 4
                          ? const ContactScreen()
                          : const Center(child: Text('Coming soon')),
                ),
              );
            }

            // Diary tab (unchanged)
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(middle: Text('Diary')),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Shishir Dey.',
            style: TextStyle(
              fontFamily: 'Chunkfive',
              fontSize: 62,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Hi. I am Shishir, an engineer based in India who loves technology and art!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Helvetica',
                fontSize: 22,
                color: CupertinoColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Socials Section
            Text(
              'Socials',
              style: TextStyle(
                fontFamily: 'Chunkfive',
                fontSize: 32,
                color: CupertinoColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Email Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed:
                  () => _launchEmailApp(context, 'r0qck3ntp@mozmail.com'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CupertinoColors.black, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'Email',
                    style: TextStyle(
                      fontFamily: 'Helvetica',
                      fontSize: 18,
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // GitHub Button
            _buildSocialButton(
              context,
              'GitHub',
              'https://github.com/shishir-dey',
              isWebView: true,
            ),
            const SizedBox(height: 12),
            // LinkedIn Button
            _buildSocialButton(
              context,
              'LinkedIn',
              'https://www.linkedin.com/in/shishir-dey/',
              isExternal: true,
            ),
            const SizedBox(height: 30),

            // IM Section
            Text(
              'IM',
              style: TextStyle(
                fontFamily: 'Chunkfive',
                fontSize: 32,
                color: CupertinoColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Telegram Button
            _buildSocialButton(
              context,
              'Telegram',
              'https://t.me/shishir_dey',
              isExternal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    String label,
    String url, {
    bool isWebView = false,
    bool isExternal = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        if (isWebView) {
          _openInWebView(context, url, label);
        } else if (isExternal) {
          if (url.startsWith('mailto:')) {
            _launchEmailApp(context, url.replaceFirst('mailto:', ''));
          } else {
            _launchUrl(url);
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CupertinoColors.black, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Helvetica',
              fontSize: 18,
              color: CupertinoColors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _openInWebView(BuildContext context, String url, String title) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder:
            (context) => CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(middle: Text(title)),
              child: SafeArea(
                child: WebViewWidget(controller: _createWebViewController(url)),
              ),
            ),
      ),
    );
  }

  WebViewController _createWebViewController(String url) {
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

    final controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(url));

    return controller;
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmailApp(BuildContext context, String email) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': 'Hello from your portfolio app',
          'body': '',
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      // Show an error dialog if email launch fails
      if (context.mounted) {
        _showErrorDialog(context, email);
      }
    }
  }

  void _showErrorDialog(BuildContext context, String email) {
    if (context.mounted) {
      showCupertinoDialog(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text(
                'Could not open email app. Please email $email manually.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
      );
    }
  }
}
