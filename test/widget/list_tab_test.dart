/// [ListTab] ウィジェットのテスト。
///
/// [AppDatabase] と [FirestoreService] を mockito の [GenerateMocks] でモック化し、
/// [appDatabaseProvider] と [firestoreServiceProvider] を
/// [ProviderScope.overrides] で差し替える。
/// [TransactionListNotifier] は本物を使うため、Notifier の動作ごとテストできる。
///
/// drift のストリームタイマー問題を回避するため、インメモリ DB は
/// [DatabaseConnection] に `closeStreamsSynchronously: true` を渡して作成する。
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/core/database/app_database.dart' as db;
import 'package:kakeibo_app/core/firebase/firestore_service.dart';
import 'package:kakeibo_app/features/dashboard/view/list_tab.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'list_tab_test.mocks.dart';

// build_runner がこのアノテーションを読み取り、
// list_tab_test.mocks.dart に MockFirestoreService を生成する。
// AppDatabase は drift の生成クラスを継承しているためコード生成でのモックが難しく、
// forTesting コンストラクタでインメモリDBを使う。
@GenerateMocks([FirestoreService])
void main() {
  /// テスト用のインメモリ [db.AppDatabase] を作成する。
  ///
  /// [DatabaseConnection] に `closeStreamsSynchronously: true` を渡すことで、
  /// drift がクエリストリームを購読解除した後に保持するタイマーを同期的に閉じる。
  /// これを省略するとウィジェットテスト終了時にペンディングタイマーエラーが発生する。
  db.AppDatabase buildInMemoryDb() => db.AppDatabase.forTesting(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );

  /// 各テストで共通して使うウィジェットビルダー。
  ///
  /// [inMemoryDb] と [mockFirestore] を Provider に注入し、
  /// [ListTab] を描画する。
  Widget buildListTab({
    required db.AppDatabase inMemoryDb,
    required MockFirestoreService mockFirestore,
  }) {
    return ProviderScope(
      overrides: [
        db.appDatabaseProvider.overrideWithValue(inMemoryDb),
        firestoreServiceProvider.overrideWithValue(mockFirestore),
      ],
      child: const MaterialApp(home: ListTab()),
    );
  }

  group('ListTab', () {
    late db.AppDatabase inMemoryDb;
    late MockFirestoreService mockFirestore;

    setUp(() {
      inMemoryDb = buildInMemoryDb();
      mockFirestore = MockFirestoreService();

      // Firestore の書き込みは成功扱いにしておく（テストの対象外）
      when(mockFirestore.saveTransaction(any)).thenAnswer((_) async {});
      when(mockFirestore.deleteTransaction(any)).thenAnswer((_) async {});
    });

    tearDown(() async {
      await inMemoryDb.close();
    });

    testWidgets('DBが空のときは「この月の取引はありません」が表示される', (tester) async {
      await tester.pumpWidget(
        buildListTab(inMemoryDb: inMemoryDb, mockFirestore: mockFirestore),
      );
      await tester.pumpAndSettle();

      expect(find.text('この月の取引はありません'), findsOneWidget);
    });

    testWidgets('取引を追加すると明細行が表示される', (tester) async {
      // インメモリDBに取引を挿入する
      // migration の onCreate でシードカテゴリが挿入済みのため
      // categoryId: 'food' はそのまま使える
      await inMemoryDb.insertTransaction(
        db.TransactionsCompanion.insert(
          categoryId: 'food',
          amount: 3200,
          date: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      await tester.pumpWidget(
        buildListTab(inMemoryDb: inMemoryDb, mockFirestore: mockFirestore),
      );
      await tester.pumpAndSettle();

      // カテゴリ名と金額が表示されていること
      expect(find.text('食費'), findsOneWidget);
      expect(find.text('-¥3,200'), findsOneWidget);
    });
  });
}
