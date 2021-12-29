import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({
    Key? key,
    required this.userId,
  }) : super(key: key);

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Hello world! $userId'),
        ),
      ),
    );
  }
}
