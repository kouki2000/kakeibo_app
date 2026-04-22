/// [SummaryCard] ウィジェットのテスト。
///
/// [SummaryCard] は外部依存を持たない [StatelessWidget] のため、
/// Riverpod のモックなしでテストできる。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/features/dashboard/view/summary_card.dart';

void main() {
  /// テスト対象ウィジェットを [MaterialApp] でラップして返すヘルパー。
  ///
  /// [SummaryCard] は [Theme] や [TextTheme] に依存するため
  /// [MaterialApp] でラップしてマテリアルデザインのコンテキストを提供する。
  Widget buildCard({
    required int income,
    required int expense,
    required int balance,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SummaryCard(income: income, expense: expense, balance: balance),
      ),
    );
  }

  group('SummaryCard', () {
    testWidgets('収入・支出・収支がフォーマットされて表示される', (tester) async {
      await tester.pumpWidget(
        buildCard(income: 200000, expense: 50000, balance: 150000),
      );

      // 収入・支出のラベルが表示されていること
      expect(find.text('収入'), findsOneWidget);
      expect(find.text('支出'), findsOneWidget);

      // 金額がフォーマットされて表示されていること
      expect(find.text('¥200,000'), findsOneWidget);
      expect(find.text('¥50,000'), findsOneWidget);
      expect(find.text('¥150,000'), findsOneWidget);

      // ヘッダが表示されていること
      expect(find.text('今月の収支'), findsOneWidget);
    });

    testWidgets('収入・支出がともに0のとき ¥0 が3つ表示される', (tester) async {
      await tester.pumpWidget(buildCard(income: 0, expense: 0, balance: 0));

      // balance・income・expense それぞれの ¥0 が表示される
      expect(find.text('¥0'), findsNWidgets(3));
    });

    testWidgets('収支がマイナスのとき balance は絶対値で表示される', (tester) async {
      await tester.pumpWidget(
        buildCard(income: 10000, expense: 30000, balance: -20000),
      );

      // Formatter.amount は abs() を使うため ¥20,000 が表示される
      expect(find.text('¥20,000'), findsOneWidget);
    });
  });
}
