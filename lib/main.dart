import 'package:flutter/material.dart';
import 'package:kakeibo_app/app/router.dart';

void main() {
  runApp(const KakeiboApp());
}

/// アプリのルートウィジェット
class KakeiboApp extends StatelessWidget {
  /// コンストラクタ
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '家計簿アプリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
