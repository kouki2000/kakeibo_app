import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// アプリのルートWidget
class MyApp extends StatelessWidget {
  /// コンストラクタ
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '家計簿アプリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const Scaffold(body: Center(child: Text('家計簿アプリ'))),
    );
  }
}
