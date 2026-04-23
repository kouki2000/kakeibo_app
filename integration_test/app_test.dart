/// 家計簿アプリの E2E 統合テスト。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kakeibo_app/core/database/app_database.dart' as db;

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late db.AppDatabase testDatabase;

  setUp(() {
    testDatabase = buildTestDatabase();
  });

  tearDown(() async {
    await testDatabase.close();
  });

  group('家計簿アプリ E2E テスト', () {
    testWidgets('シナリオ1：起動時に明細タブが「この月の取引はありません」を表示する', (tester) async {
      await tester.pumpWidget(buildTestApp(testDatabase));
      await tester.pumpAndSettle();

      // 明細タブへ
      await tester.tap(find.byKey(const Key('nav_list')));
      await tester.pumpAndSettle();

      expect(find.text('この月の取引はありません'), findsOneWidget);
    });

    testWidgets('シナリオ2：取引を追加すると明細タブとホームタブに金額が表示される', (tester) async {
      await tester.pumpWidget(buildTestApp(testDatabase));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '3200');
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 保存後はホームタブに戻っている（明細タブは非選択 → list_outlined）
      // 明細タブへ
      await tester.tap(find.byKey(const Key('nav_list')));
      await tester.pumpAndSettle();

      expect(find.text('食費'), findsOneWidget);
      expect(find.text('-¥3,200'), findsOneWidget);

      // ホームタブへ
      await tester.tap(find.byKey(const Key('nav_home')));
      await tester.pumpAndSettle();

      expect(find.text('¥3,200'), findsWidgets);
    });

    testWidgets('シナリオ3：追加した取引をスワイプ削除するとリストから消える', (tester) async {
      await tester.pumpWidget(buildTestApp(testDatabase));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '1500');
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 明細タブへ
      await tester.tap(find.byKey(const Key('nav_list')));
      await tester.pumpAndSettle();

      expect(find.text('食費'), findsOneWidget);

      await tester.drag(find.text('食費'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('この月の取引はありません'), findsOneWidget);
      expect(find.text('食費'), findsNothing);
    });
  });
}
