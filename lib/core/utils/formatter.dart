/// 金額・日付の表示フォーマットユーティリティ
class Formatter {
  Formatter._(); // インスタンス化禁止（static メソッドのみのクラスに必要）

  /// 金額を「¥1,500」形式に変換する
  /// for ループと文字列補間を使用
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

  /// 日付を「2024/06/01」形式に変換する（アロー関数）
  static String date(DateTime dt) =>
      '${dt.year}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.day.toString().padLeft(2, '0')}';

  /// 月を「2024年6月」形式に変換する
  static String yearMonth(DateTime dt) => '${dt.year}年${dt.month}月';
}
