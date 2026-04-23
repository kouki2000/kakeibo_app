/// アプリのエントリポイント。
///
/// [ProviderScope] でウィジェットツリー全体を包み、Riverpod を有効化する。
/// 第8章で Firebase の初期化を追加した。
/// [Firebase.initializeApp] は非同期のため `async` で待機する。
/// ルーティングは `appRouter`（lib/app/router.dart）で一元管理する。
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/app/router.dart';
import 'package:kakeibo_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: KakeiboApp()));
}

/// アプリのルートウィジェット。
///
/// [MaterialApp.router] に `appRouter` を渡すことで
/// go_router によるルーティングを有効化する。
class KakeiboApp extends StatelessWidget {
  /// コンストラクタ。
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
