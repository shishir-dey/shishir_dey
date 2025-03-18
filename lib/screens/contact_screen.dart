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
