/// ダッシュボード（ホームタブ）の表示状態モデル。
///
/// MVVM の Model 層に位置する。
/// `SummaryNotifier` がこのクラスのインスタンスを状態として保持し、
/// `HomeTab` が `summaryProvider` 経由で参照する。
library;

/// 収支サマリの表示状態を保持するイミュータブルなデータクラス。
///
/// フィールドはすべて `final` で、状態変更時は新インスタンスを生成する。
/// Riverpod の変化検知は `state = 新インスタンス` への代入で行われるため、
/// フィールドの直接書き換えは変化として検知されない。
class SummaryState {
  /// コンストラクタ。
  const SummaryState({
    required this.income,
    required this.expense,
    required this.recentTransactions,
  });

  /// 今月の収入合計（円）。
  final int income;

  /// 今月の支出合計（円、正値）。
  final int expense;

  /// ホームタブに表示する直近の取引リスト。
  final List<RecentItem> recentTransactions;

  /// 収支（収入 − 支出）。
  ///
  /// 赤字の場合は負値になる。`SummaryCard` での色分けに使用する。
  int get balance => income - expense;
}

/// ホームタブの直近取引リストに表示する1行分のデータ。
///
/// [Transaction] モデルから必要な表示項目だけを抽出した表示専用クラス。
/// DB 接続後は ViewModel 側で `Transaction` → [RecentItem] の変換を行う。
class RecentItem {
  /// コンストラクタ。
  const RecentItem({
    required this.label,
    required this.amount,
    required this.iconCode,
    required this.isIncome,
    required this.dateLabel,
  });

  /// 表示するカテゴリ名。例: `'食費'`
  final String label;

  /// 金額（正値）。符号は [isIncome] で判断する。
  final int amount;

  /// Material Icons のコードポイント（16進数文字列）。例: `'e56c'`
  final String iconCode;

  /// `true` のとき収入、`false` のとき支出。行の色分けに使用する。
  final bool isIncome;

  /// 日付の表示文字列。例: `'04/25'`
  final String dateLabel;
}
