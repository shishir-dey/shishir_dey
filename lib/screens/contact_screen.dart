import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile section from Home Screen
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    color: CupertinoColors.systemGrey5,
                    width: 120,
                    height: 120,
                    child: const Icon(
                      CupertinoIcons.person_alt,
                      size: 70,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Shishir Dey.',
                  style: TextStyle(
                    fontFamily: 'Chunkfive',
                    fontSize: 42,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hi. I am Shishir, an engineer based in India who loves technology and art!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SourceSans3',
                    fontSize: 18,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Social buttons in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email Button
                _buildSmallButton(
                  context,
                  CupertinoIcons.mail,
                  () => _launchEmailApp(context, 'r0qck3ntp@mozmail.com'),
                ),
                const SizedBox(width: 16),
                // GitHub Button
                _buildSmallButton(
                  context,
                  CupertinoIcons.chevron_left_slash_chevron_right,
                  () => _openInWebView(
                    context,
                    'https://github.com/shishir-dey',
                    'GitHub',
                  ),
                ),
                const SizedBox(width: 16),
                // LinkedIn Button
                _buildSmallButton(
                  context,
                  CupertinoIcons.briefcase,
                  () => _launchUrl('https://www.linkedin.com/in/shishir-dey/'),
                ),
                const SizedBox(width: 16),
                // Telegram Button
                _buildSmallButton(
                  context,
                  CupertinoIcons.paperplane,
                  () => _launchUrl('https://t.me/shishir_dey'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: CupertinoColors.black, width: 1.5),
        ),
        child: Center(
          child: Icon(icon, size: 24, color: CupertinoColors.black),
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
