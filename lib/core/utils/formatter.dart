/// 金額・日付の表示フォーマットユーティリティ。
///
/// アプリ全体で統一した表示形式を提供する static メソッド群。
/// インスタンス化は不要なため、コンストラクタをプライベートにしている。
///
/// 使用箇所: `SummaryCard`, `RecentList`, `Transaction`
library;

/// 金額・日付の表示フォーマットユーティリティ。
class Formatter {
  Formatter._(); // インスタンス化禁止（static メソッドのみのクラスに必要）

  /// 金額を「¥1,500」形式に変換する。
  ///
  /// [amount] は正値を渡すこと。負値の符号付与は呼び出し側の責務。
  /// 例: `Formatter.amount(1500)` → `'¥1,500'`
  static String amount(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    final offset = str.length % 3;

    for (var i = 0; i < str.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '¥$buffer';
  }

  /// 日付を「2024/06/01」形式に変換する。
  ///
  /// 例: `Formatter.date(DateTime(2024, 6, 1))` → `'2024/06/01'`
  static String date(DateTime dt) =>
      '${dt.year}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.day.toString().padLeft(2, '0')}';

  /// 年月を「2024年6月」形式に変換する。
  ///
  /// サマリ画面のヘッダ表示などに使用する。
  static String yearMonth(DateTime dt) => '${dt.year}年${dt.month}月';
}
