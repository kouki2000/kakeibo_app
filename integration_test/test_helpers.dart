/// 統合テスト用のヘルパー。
///
/// テスト専用のインメモリ DB とモック Firestore を使って
/// アプリを起動するためのユーティリティを提供する。
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakeibo_app/app/router.dart';
import 'package:kakeibo_app/core/database/app_database.dart' as db;
import 'package:kakeibo_app/core/firebase/firestore_service.dart';
import 'package:mockito/mockito.dart';

/// テスト用のインメモリ [db.AppDatabase] を生成する。
///
/// [DatabaseConnection] に `closeStreamsSynchronously: true` を渡し、
/// drift のストリームタイマー問題を回避する。
db.AppDatabase buildTestDatabase() => db.AppDatabase.forTesting(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Firestore への書き込みを何もしないフェイク実装。
///
/// `Mock with implements` を使うことで [FirestoreService] のコンストラクタを
/// 呼ばずにインスタンスを生成できる。Firebase 未初期化エラーが発生しない。
class _MockFirestoreService extends Mock implements FirestoreService {
  @override
  Future<void> saveTransaction(dynamic item) async {}

  @override
  Future<void> deleteTransaction(String id) async {}
}

/// テスト用アプリを [ProviderScope.overrides] 付きで起動する。
///
/// - [appDatabaseProvider] をインメモリ DB に差し替える
/// - [firestoreServiceProvider] を no-op 実装に差し替える
/// - Firebase.initializeApp をスキップする
///
/// テストファイルの先頭で `await tester.pumpWidget(buildTestApp(testDatabase))` と呼ぶ。
Widget buildTestApp(db.AppDatabase testDatabase) {
  return ProviderScope(
    overrides: [
      db.appDatabaseProvider.overrideWithValue(testDatabase),
      firestoreServiceProvider.overrideWithValue(_MockFirestoreService()),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}
