import 'package:flutter/cupertino.dart';

// Import screens and widgets
// import 'screens/home_screen.dart'; // Removed Home Screen import
import 'screens/contact_screen.dart';
import 'screens/diary_screen.dart';
import 'screens/photography_screen.dart';
import 'widgets/pinterest_webview.dart';

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
    // Define colors for each tab
    final Color photographyTabColor = backgroundColor;
    final Color diaryTabColor = CupertinoColors.white;
    final Color pinterestTabColor = CupertinoColors.white;
    final Color contactTabColor = backgroundColor;

    Color getTabBarBackgroundColor() {
      switch (_selectedIndex) {
        case 0:
          return photographyTabColor;
        case 1:
          return diaryTabColor;
        case 2:
          return pinterestTabColor;
        case 3:
          return contactTabColor;
        default:
          return backgroundColor;
      }
    }

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: getTabBarBackgroundColor(),
        activeColor: CupertinoColors.black,
        inactiveColor: CupertinoColors.black.withAlpha(153),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // Reload Pinterest URL when Pinterest tab is clicked
            if (index == 2 && _selectedIndex == 2) {
              _reloadPinterestUrl();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.photo),
            label: 'Photography',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: 'Diary',
          ),
          BottomNavigationBarItem(icon: PinterestIcon(), label: 'Pinterest'),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'About',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (context) {
            if (index == 2) {
              // Pinterest tab
              return CupertinoPageScaffold(
                child: SafeArea(child: const PinterestWebView()),
              );
            }

            // Photography and About (formerly Contact) tabs with the same background color
            if (index == 0 || index == 3) {
              return CupertinoPageScaffold(
                backgroundColor: backgroundColor,
                child: SafeArea(
                  child:
                      index == 0
                          ? const PhotographyScreen()
                          : const ContactScreen(),
                ),
              );
            }

            // Diary tab (unchanged)
            return CupertinoPageScaffold(
              backgroundColor: CupertinoColors.white,
              child: SafeArea(child: const DiaryScreen()),
            );
          },
        );
      },
    );
  }

  void _reloadPinterestUrl() {
    // Use the static method to reload Pinterest
    PinterestWebView.reloadPinterest();
  }
}
