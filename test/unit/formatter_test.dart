/// [Formatter] ユーティリティのユニットテスト。
///
/// ウィジェットやRiverpodへの依存がないため `test()` 関数で検証する。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/core/utils/formatter.dart';

void main() {
  group('Formatter.amount', () {
    test('3桁の金額は3桁のまま返す', () {
      expect(Formatter.amount(500), '¥500');
    });

    test('4桁の金額は3桁区切りで返す', () {
      expect(Formatter.amount(1500), '¥1,500');
    });

    test('7桁の金額は2箇所カンマ区切りで返す', () {
      expect(Formatter.amount(1234567), '¥1,234,567');
    });

    test('0円は ¥0 を返す', () {
      expect(Formatter.amount(0), '¥0');
    });
  });

  group('Formatter.date', () {
    test('月・日が1桁のときは0埋めして返す', () {
      expect(Formatter.date(DateTime(2025, 4, 5)), '2025/04/05');
    });

    test('月・日が2桁のときはそのまま返す', () {
      expect(Formatter.date(DateTime(2025, 12, 31)), '2025/12/31');
    });
  });

  group('Formatter.yearMonth', () {
    test('年月を「YYYY年M月」形式で返す', () {
      expect(Formatter.yearMonth(DateTime(2025, 4, 15)), '2025年4月');
    });
  });
}
