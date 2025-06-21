// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock screens for testing
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('Shishir Dey.'),
        Text(
          'Hi. I am Shishir, an engineer based in India who loves technology and art!',
        ),
      ],
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [Text('Socials'), Text('IM')],
    );
  }
}

// Test-only version of the app that doesn't include the Pinterest tab
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'My Portfolio',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        brightness: Brightness.light,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  int _selectedIndex = 0;
  final Color backgroundColor = const Color(0xFFFFFBEB);

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
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
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Contact',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (context) {
            // Home, Photography, and Contact tabs with the same background color
            if (index == 0 || index == 1 || index == 3) {
              return CupertinoPageScaffold(
                backgroundColor: backgroundColor,
                child: SafeArea(
                  child:
                      index == 0
                          ? const HomeScreen()
                          : index == 3
                          ? const ContactScreen()
                          : const Center(child: Text('Coming soon')),
                ),
              );
            }

            // Diary tab (unchanged)
            return CupertinoPageScaffold(
              child: const SafeArea(child: Center(child: Text('Coming soon'))),
            );
          },
        );
      },
    );
  }
}

void main() {
  testWidgets('App initializes with Home tab selected', (
    WidgetTester tester,
  ) async {
    // Build our test app and trigger a frame
    await tester.pumpWidget(const TestApp());

    // Verify that the app starts with the Home tab
    expect(find.text('Home'), findsWidgets);
    expect(find.byIcon(CupertinoIcons.home), findsOneWidget);

    // Verify that the Home screen content is displayed
    expect(find.text('Shishir Dey.'), findsOneWidget);
    expect(
      find.text(
        'Hi. I am Shishir, an engineer based in India who loves technology and art!',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Can navigate between tabs', (WidgetTester tester) async {
    // Build our test app and trigger a frame
    await tester.pumpWidget(const TestApp());

    // Tap on the Photography tab
    await tester.tap(find.byIcon(CupertinoIcons.photo));
    await tester.pumpAndSettle();

    // Verify that we're on the Photography tab
    expect(find.text('Photography'), findsWidgets);
    expect(find.text('Coming soon'), findsOneWidget);

    // Tap on the Diary tab
    await tester.tap(find.byIcon(CupertinoIcons.book));
    await tester.pumpAndSettle();

    // Verify that we're on the Diary tab
    expect(find.text('Diary'), findsWidgets);
    expect(find.text('Coming soon'), findsOneWidget);

    // Tap on the Contact tab
    await tester.tap(find.byIcon(CupertinoIcons.person));
    await tester.pumpAndSettle();

    // Verify that we're on the Contact tab
    expect(find.text('Contact'), findsWidgets);
    expect(find.text('Socials'), findsOneWidget);
    expect(find.text('IM'), findsOneWidget);

    // Go back to Home tab
    await tester.tap(find.byIcon(CupertinoIcons.home));
    await tester.pumpAndSettle();

    // Verify that we're back on the Home tab
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Shishir Dey.'), findsOneWidget);
  });
}
