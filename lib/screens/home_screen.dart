import 'package:flutter/cupertino.dart';

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
